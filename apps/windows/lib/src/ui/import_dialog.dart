import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../application/local_commit_coordinator.dart';
import '../application/note_workspace_controller.dart';
import '../application/sync_settings_controller.dart';
import '../application/vault_export_service.dart';
import '../application/vault_import_service.dart';

Future<void> showVaultImportDialog(
  BuildContext context, {
  required NoteWorkspaceController workspace,
  required LocalCommitCoordinator localCommits,
  SyncSettingsController? syncSettings,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _VaultImportDialog(
    workspace: workspace,
    localCommits: localCommits,
    syncSettings: syncSettings,
  ),
);

final class _VaultImportDialog extends StatefulWidget {
  const _VaultImportDialog({
    required this.workspace,
    required this.localCommits,
    required this.syncSettings,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final SyncSettingsController? syncSettings;

  @override
  State<_VaultImportDialog> createState() => _VaultImportDialogState();
}

final class _VaultImportDialogState extends State<_VaultImportDialog> {
  late final VaultImportService _service;
  late final Directory _defaultRoot;
  late final TextEditingController _pathController;
  VaultImportPreview? _preview;
  VaultImportResult? _result;
  Object? _error;
  bool _busy = false;

  bool get _syncReadyForImport {
    final settings = widget.syncSettings;
    return settings == null ||
        settings.state == SyncSettingsState.notConfigured;
  }

  @override
  void initState() {
    super.initState();
    _service = VaultImportService(store: widget.workspace.store);
    _defaultRoot = VaultExportService(
      store: widget.workspace.store,
    ).destinationRoot;
    _pathController = TextEditingController();
    unawaited(_selectNewestDefaultExport());
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: const Text('从备份恢复'),
      content: SizedBox(
        width: 560,
        child: result != null
            ? _buildSuccess(result)
            : _preview == null
            ? _buildSelection(context)
            : _buildPreview(context, _preview!),
      ),
      actions: <Widget>[
        if (_preview != null && result == null)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _preview = null;
                    _error = null;
                  }),
            child: const Text('返回'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(result == null ? '取消' : '完成'),
        ),
        if (_preview == null && result == null)
          FilledButton.icon(
            key: const Key('inspect-import-button'),
            onPressed: _busy || !_syncReadyForImport ? null : _inspect,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: const Text('校验并预览'),
          ),
        if (_preview != null && result == null)
          FilledButton.icon(
            key: const Key('confirm-import-button'),
            onPressed: _busy ? null : _import,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.settings_backup_restore),
            label: const Text('确认恢复'),
          ),
      ],
    );
  }

  Widget _buildSelection(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        '选择一个 MiaoNotes Portable Export v1 目录。应用会先校验所有文件，'
        '不会直接写入本地数据。',
        style: TextStyle(height: 1.5),
      ),
      const SizedBox(height: 14),
      TextField(
        key: const Key('import-directory-field'),
        controller: _pathController,
        enabled: !_busy,
        decoration: const InputDecoration(
          labelText: '备份目录路径',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          TextButton.icon(
            key: const Key('find-latest-export-button'),
            onPressed: _busy ? null : _selectNewestDefaultExport,
            icon: const Icon(Icons.history),
            label: const Text('查找最近的默认备份'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _defaultRoot.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      if (!_syncReadyForImport) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          widget.syncSettings?.isConfigured == true
              ? '请先在同步设置中断开并清除当前 R2 配置，再恢复其他 Vault。'
              : '正在读取同步配置，请稍后重新打开此窗口。',
          key: const Key('import-sync-blocked'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      if (_error case final error?) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          '校验失败：$error',
          key: const Key('import-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );

  Widget _buildPreview(BuildContext context, VaultImportPreview preview) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.verified_outlined, color: Color(0xff557a61)),
              SizedBox(width: 8),
              Text('备份已通过完整性与结构校验'),
            ],
          ),
          const SizedBox(height: 14),
          Text('Vault：${preview.snapshot.vault.vaultId}'),
          Text('导出时间：${preview.snapshot.exportedAtUtc.toLocal()}'),
          Text(
            '${preview.noteCount} 条便签 · ${preview.revisionCount} 个历史版本 · '
            '${preview.conflictCount} 条冲突记录',
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '恢复仅允许写入空的本地 Vault。恢复会采用备份中的 Vault 身份，'
                '并把历史版本重新加入待同步队列。任何失败都会整体回滚。',
                style: TextStyle(height: 1.45),
              ),
            ),
          ),
          if (_error case final error?) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              '恢复失败：$error',
              key: const Key('import-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      );

  Widget _buildSuccess(VaultImportResult result) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline, color: Color(0xff557a61)),
          SizedBox(width: 8),
          Text('备份已完整恢复'),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        '${result.imported.noteCount} 条便签 · '
        '${result.imported.revisionCount} 个历史版本 · '
        '${result.imported.queuedObjectCount} 个对象等待同步',
      ),
    ],
  );

  Future<void> _selectNewestDefaultExport() async {
    try {
      final exports = await VaultImportService.discoverExports(_defaultRoot);
      if (mounted) {
        setState(() {
          _error = exports.isEmpty ? '默认备份目录中没有可用导出' : null;
          if (exports.isNotEmpty) {
            _pathController.text = exports.first.path;
          }
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _inspect() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() => _error = '请输入备份目录路径');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await _service.inspectPortableExport(Directory(path));
      if (mounted) {
        setState(() => _preview = preview);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.workspace.flush();
      final result = await _service.importPortableExport(
        Directory(_pathController.text.trim()),
      );
      await widget.workspace.refreshAfterImport();
      await widget.localCommits.refreshAfterImport();
      if (mounted) {
        setState(() => _result = result);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
