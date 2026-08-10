import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'sync_configuration.dart';

/// Stores the R2 key pair in the current Windows user's credential set.
final class WindowsCredentialStore implements SyncCredentialStore {
  const WindowsCredentialStore({this.targetName = 'MiaoNotes/R2/default'});

  final String targetName;

  @override
  Future<SyncCredentials?> read() async {
    _requireWindows();
    return using((arena) {
      final credentialPointer = arena<Pointer<CREDENTIAL>>();
      final result = CredRead(
        arena.pcwstr(targetName),
        CRED_TYPE_GENERIC,
        credentialPointer,
      );
      if (!result.value) {
        if (result.error == ERROR_NOT_FOUND) {
          return null;
        }
        throw WindowsCredentialException(
          'Windows credential read failed (${result.error})',
        );
      }

      final nativeCredential = credentialPointer.value;
      try {
        final credential = nativeCredential.ref;
        if (credential.UserName.isNull ||
            credential.CredentialBlob.isNull ||
            credential.CredentialBlobSize == 0) {
          throw const WindowsCredentialException(
            'Windows credential is incomplete',
          );
        }
        final blob = credential.CredentialBlob.asTypedList(
          credential.CredentialBlobSize,
        );
        final secret = utf8.decode(List<int>.of(blob));
        return SyncCredentials(
          accessKeyId: credential.UserName.toDartString(),
          secretAccessKey: secret,
        );
      } on FormatException {
        throw const WindowsCredentialException(
          'Windows credential contains invalid text',
        );
      } finally {
        final credential = nativeCredential.ref;
        if (!credential.CredentialBlob.isNull) {
          credential.CredentialBlob.asTypedList(
            credential.CredentialBlobSize,
          ).fillRange(0, credential.CredentialBlobSize, 0);
        }
        CredFree(nativeCredential);
      }
    });
  }

  @override
  Future<void> write(SyncCredentials credentials) async {
    _requireWindows();
    if (credentials.accessKeyId.isEmpty ||
        credentials.secretAccessKey.isEmpty) {
      throw const WindowsCredentialException(
        'Access key ID and secret access key are required',
      );
    }
    using((arena) {
      final secretBytes = utf8.encode(credentials.secretAccessKey);
      final blob = secretBytes.toNative(allocator: arena);
      try {
        final credential = arena<CREDENTIAL>();
        credential.ref
          ..Type = CRED_TYPE_GENERIC
          ..TargetName = arena.pwstr(targetName)
          ..Persist = CRED_PERSIST_LOCAL_MACHINE
          ..UserName = arena.pwstr(credentials.accessKeyId)
          ..CredentialBlob = blob
          ..CredentialBlobSize = secretBytes.length;
        final result = CredWrite(credential, 0);
        if (!result.value) {
          throw WindowsCredentialException(
            'Windows credential write failed (${result.error})',
          );
        }
      } finally {
        blob
            .asTypedList(secretBytes.length)
            .fillRange(0, secretBytes.length, 0);
      }
    });
  }

  @override
  Future<void> delete() async {
    _requireWindows();
    using((arena) {
      final result = CredDelete(arena.pcwstr(targetName), CRED_TYPE_GENERIC);
      if (!result.value && result.error != ERROR_NOT_FOUND) {
        throw WindowsCredentialException(
          'Windows credential delete failed (${result.error})',
        );
      }
    });
  }
}

/// Stores one master key per Vault/key generation in Windows Credential
/// Manager. Raw key bytes are used as the credential blob and are never
/// serialized to the profile file.
final class WindowsVaultKeyStore implements VaultKeyStore {
  const WindowsVaultKeyStore({this.targetPrefix = 'MiaoNotes/Vault'});

  final String targetPrefix;

  @override
  Future<List<int>?> read(String vaultId, String keyId) async {
    _requireWindows();
    final target = _target(vaultId, keyId);
    return using((arena) {
      final credentialPointer = arena<Pointer<CREDENTIAL>>();
      final result = CredRead(
        arena.pcwstr(target),
        CRED_TYPE_GENERIC,
        credentialPointer,
      );
      if (!result.value) {
        if (result.error == ERROR_NOT_FOUND) {
          return null;
        }
        throw WindowsCredentialException(
          'Windows vault-key read failed (${result.error})',
        );
      }
      final nativeCredential = credentialPointer.value;
      try {
        final credential = nativeCredential.ref;
        if (credential.CredentialBlob.isNull ||
            credential.CredentialBlobSize != 32) {
          throw const WindowsCredentialException(
            'Windows vault key has an invalid length',
          );
        }
        return List<int>.of(
          credential.CredentialBlob.asTypedList(32),
          growable: false,
        );
      } finally {
        final credential = nativeCredential.ref;
        if (!credential.CredentialBlob.isNull) {
          credential.CredentialBlob.asTypedList(
            credential.CredentialBlobSize,
          ).fillRange(0, credential.CredentialBlobSize, 0);
        }
        CredFree(nativeCredential);
      }
    });
  }

  @override
  Future<void> write(String vaultId, String keyId, List<int> keyBytes) async {
    _requireWindows();
    if (keyBytes.length != 32) {
      throw const WindowsCredentialException(
        'Vault master key must contain 32 bytes',
      );
    }
    final target = _target(vaultId, keyId);
    using((arena) {
      final protectedBytes = Uint8List.fromList(keyBytes);
      final blob = protectedBytes.toNative(allocator: arena);
      try {
        final credential = arena<CREDENTIAL>();
        credential.ref
          ..Type = CRED_TYPE_GENERIC
          ..TargetName = arena.pwstr(target)
          ..Persist = CRED_PERSIST_LOCAL_MACHINE
          ..UserName = arena.pwstr(keyId)
          ..CredentialBlob = blob
          ..CredentialBlobSize = keyBytes.length;
        final result = CredWrite(credential, 0);
        if (!result.value) {
          throw WindowsCredentialException(
            'Windows vault-key write failed (${result.error})',
          );
        }
      } finally {
        blob.asTypedList(keyBytes.length).fillRange(0, keyBytes.length, 0);
      }
    });
  }

  @override
  Future<void> delete(String vaultId, String keyId) async {
    _requireWindows();
    final target = _target(vaultId, keyId);
    using((arena) {
      final result = CredDelete(arena.pcwstr(target), CRED_TYPE_GENERIC);
      if (!result.value && result.error != ERROR_NOT_FOUND) {
        throw WindowsCredentialException(
          'Windows vault-key delete failed (${result.error})',
        );
      }
    });
  }

  String _target(String vaultId, String keyId) {
    if (!_safeCredentialSegment.hasMatch(vaultId) ||
        !_safeCredentialSegment.hasMatch(keyId)) {
      throw ArgumentError('Unsafe Vault credential identifier');
    }
    return '$targetPrefix/$vaultId/$keyId';
  }
}

final RegExp _safeCredentialSegment = RegExp(r'^[A-Za-z0-9._-]{1,128}$');

final class WindowsCredentialException implements Exception {
  const WindowsCredentialException(this.message);

  final String message;

  @override
  String toString() => 'WindowsCredentialException: $message';
}

void _requireWindows() {
  if (!Platform.isWindows) {
    throw UnsupportedError(
      'Windows Credential Manager is only available on Windows',
    );
  }
}
