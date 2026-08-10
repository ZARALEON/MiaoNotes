import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import '../application/sync_configuration.dart';
import '../application/sync_settings_controller.dart';

Future<void> showSyncSettingsDialog(
  BuildContext context,
  SyncSettingsController settings,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => SyncSettingsDialog(settings: settings),
);

final class SyncSettingsDialog extends StatefulWidget {
  const SyncSettingsDialog({required this.settings, super.key});

  final SyncSettingsController settings;

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

final class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _endpoint;
  late final TextEditingController _bucket;
  late final TextEditingController _prefix;
  late final TextEditingController _accessKeyId;
  late final TextEditingController _secretAccessKey;
  late final TextEditingController _vaultPassword;
  late final TextEditingController _vaultPasswordConfirm;
  late final TextEditingController _recoveryCode;
  bool _secretVisible = false;
  bool _passwordVisible = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.settings.profile;
    _endpoint = TextEditingController(text: profile?.endpoint.toString() ?? '');
    _bucket = TextEditingController(text: profile?.bucket ?? '');
    _prefix = TextEditingController(text: profile?.objectPrefix ?? '');
    _accessKeyId = TextEditingController();
    _secretAccessKey = TextEditingController();
    _vaultPassword = TextEditingController();
    _vaultPasswordConfirm = TextEditingController();
    _recoveryCode = TextEditingController();
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _bucket.dispose();
    _prefix.dispose();
    for (final controller in <TextEditingController>[
      _accessKeyId,
      _secretAccessKey,
      _vaultPassword,
      _vaultPasswordConfirm,
      _recoveryCode,
    ]) {
      controller
        ..clear()
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile = widget.settings.isConfigured;
    return AlertDialog(
      title: const Row(
        children: <Widget>[
          Icon(Icons.cloud_outlined),
          SizedBox(width: 10),
          Text('R2 同步设置'),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '便签始终先保存在本机。连接测试、加密解锁和同步只在编辑器出现后运行。',
                  style: TextStyle(color: Color(0xff6f625d)),
                ),
                const SizedBox(height: 18),
                _field(
                  key: const Key('sync-endpoint-field'),
                  controller: _endpoint,
                  label: 'R2 终结点',
                  hint: 'https://<账户ID>.r2.cloudflarestorage.com',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _field(
                  key: const Key('sync-bucket-field'),
                  controller: _bucket,
                  label: '存储桶',
                  hint: 'notes',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _field(
                  key: const Key('sync-prefix-field'),
                  controller: _prefix,
                  label: '对象前缀（可选）',
                  hint: '例如 personal，不要以 / 开头或结尾',
                ),
                const SizedBox(height: 18),
                Text(
                  hasProfile
                      ? 'S3 密钥留空会继续使用 Windows 凭据管理器中的现有值。'
                      : '首次连接需要填写 S3 访问密钥。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                _field(
                  key: const Key('sync-access-key-field'),
                  controller: _accessKeyId,
                  label: '访问密钥 ID',
                  validator: hasProfile ? null : _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('sync-secret-key-field'),
                  controller: _secretAccessKey,
                  obscureText: !_secretVisible,
                  validator: hasProfile ? null : _required,
                  decoration: InputDecoration(
                    labelText: '机密访问密钥',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _secretVisible ? '隐藏密钥' : '显示密钥',
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _secretVisible = !_secretVisible,
                            ),
                      icon: Icon(
                        _secretVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  hasProfile
                      ? 'Vault 密码留空时，优先使用此设备已保存的主密钥。'
                      : '输入并确认 Vault 密码。连接已有 Vault 时，也可以改用恢复密钥。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('sync-vault-password-field'),
                  controller: _vaultPassword,
                  obscureText: !_passwordVisible,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Vault 密码',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible ? '隐藏密码' : '显示密码',
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  key: const Key('sync-vault-password-confirm-field'),
                  controller: _vaultPasswordConfirm,
                  label: '再次输入 Vault 密码',
                  obscureText: !_passwordVisible,
                ),
                const SizedBox(height: 12),
                _field(
                  key: const Key('sync-recovery-code-field'),
                  controller: _recoveryCode,
                  label: '恢复密钥（连接已有 Vault 时可选）',
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    key: const Key('sync-settings-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'S3 密钥和 Vault 主密钥只保存在 Windows 凭据管理器。密码与恢复密钥不会保存。',
                  style: TextStyle(fontSize: 12, color: Color(0xff806f69)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        if (hasProfile)
          TextButton(
            key: const Key('sync-disconnect-button'),
            onPressed: _busy ? null : _disconnect,
            child: const Text('停用同步'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('sync-connect-button'),
          onPressed: _busy ? null : _connect,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('测试并连接'),
        ),
      ],
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) => TextFormField(
    key: key,
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    enabled: !_busy,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final hasAccessKey = _accessKeyId.text.trim().isNotEmpty;
    final hasSecret = _secretAccessKey.text.isNotEmpty;
    if (hasAccessKey != hasSecret) {
      setState(() => _error = '访问密钥 ID 和机密访问密钥必须同时填写。');
      return;
    }
    if (_vaultPassword.text != _vaultPasswordConfirm.text) {
      setState(() => _error = '两次输入的 Vault 密码不一致。');
      return;
    }
    if (!widget.settings.isConfigured &&
        _vaultPassword.text.isEmpty &&
        _recoveryCode.text.trim().isEmpty) {
      setState(() => _error = '请填写 Vault 密码；已有 Vault 也可以填写恢复密钥。');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = SyncProfile(
        endpoint: Uri.parse(_endpoint.text.trim()),
        bucket: _bucket.text.trim(),
        objectPrefix: _prefix.text.trim(),
      );
      final credentials = hasAccessKey
          ? SyncCredentials(
              accessKeyId: _accessKeyId.text.trim(),
              secretAccessKey: _secretAccessKey.text,
            )
          : null;
      var result = await widget.settings.configure(
        profile: profile,
        credentials: credentials,
        vaultPassword: _vaultPassword.text,
        recoveryCode: _recoveryCode.text,
      );
      if (result == SyncConnectResult.requiresVaultAdoption && mounted) {
        final approved = await _confirmVaultAdoption();
        if (approved == true) {
          result = await widget.settings.configure(
            profile: profile,
            credentials: credentials,
            vaultPassword: _vaultPassword.text,
            recoveryCode: _recoveryCode.text,
            adoptRemoteVault: true,
          );
        }
      }
      if (result == SyncConnectResult.connected && mounted) {
        _clearSensitiveFields();
        final recoveryCode = widget.settings.takeRecoveryCode();
        if (recoveryCode != null) {
          await _showRecoveryCode(recoveryCode);
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showRecoveryCode(String recoveryCode) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('保存恢复密钥'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('这是唯一一次显示。请保存到密码管理器；丢失密码和恢复密钥后，远端便签无法解密。'),
            const SizedBox(height: 16),
            SelectableText(
              recoveryCode,
              key: const Key('sync-new-recovery-code'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          key: const Key('sync-copy-recovery-code-button'),
          onPressed: () => Clipboard.setData(ClipboardData(text: recoveryCode)),
          icon: const Icon(Icons.copy),
          label: const Text('复制'),
        ),
        FilledButton(
          key: const Key('sync-confirm-recovery-saved-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我已保存'),
        ),
      ],
    ),
  );

  Future<bool?> _confirmVaultAdoption() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('导入远端 Vault？'),
      content: const Text(
        '远端存储桶属于另一个 MiaoNotes Vault。只有本机还没有任何已保存便签时，'
        '才能安全导入其身份和内容。此操作不会删除远端对象。',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('保持本机 Vault'),
        ),
        FilledButton(
          key: const Key('sync-adopt-vault-button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('导入远端 Vault'),
        ),
      ],
    ),
  );

  Future<void> _disconnect() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('停用同步？'),
        content: const Text(
          '这会删除本机同步配置、S3 凭据和已保存的 Vault 主密钥；不会删除本机便签或 R2 对象。'
          '再次连接时需要 Vault 密码或恢复密钥。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('sync-confirm-disconnect-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('停用'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    await widget.settings.disconnect();
    if (!mounted) {
      return;
    }
    if (widget.settings.state == SyncSettingsState.failed) {
      setState(() {
        _busy = false;
        _error = _friendlyError(widget.settings.error!);
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _clearSensitiveFields() {
    _accessKeyId.clear();
    _secretAccessKey.clear();
    _vaultPassword.clear();
    _vaultPasswordConfirm.clear();
    _recoveryCode.clear();
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? '此项不能为空' : null;

String _friendlyError(Object error) => switch (error) {
  ObjectStoreAuthenticationFailed() => 'R2 拒绝了这组 S3 凭据，请检查后重试。',
  ObjectStoreUnavailable() => '暂时无法连接 R2，请检查网络和终结点。',
  VaultAdoptionNotAllowedException() => '本机已有便签或版本，不能改绑到另一个 Vault。远端没有被写入。',
  VaultPasswordRequiredException() => '需要 Vault 密码或恢复密钥才能解锁端到端加密。',
  VaultUnlockFailed() => 'Vault 密码或恢复密钥不正确。',
  UnencryptedRemoteVaultException() => '远端存在旧版明文对象。为避免混合数据，本版本不会自动迁移，请先备份。',
  EncryptedObjectCorrupted() => '远端密文校验失败，已停止同步。',
  RemoteObjectCorruptedException() => '远端 Vault 或加密配置无效，已停止连接。',
  ArgumentError() => '配置格式不正确，请检查终结点、存储桶和对象前缀。',
  _ => '连接失败：$error',
};
