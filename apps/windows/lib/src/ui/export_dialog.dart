import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../application/note_workspace_controller.dart';
import '../application/vault_export_service.dart';

Future<void> showVaultExportDialog(
  BuildContext context, {
  required NoteWorkspaceController workspace,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _VaultExportDialog(workspace: workspace),
);

final class _VaultExportDialog extends StatefulWidget {
  const _VaultExportDialog({required this.workspace});

  final NoteWorkspaceController workspace;

  @override
  State<_VaultExportDialog> createState() => _VaultExportDialogState();
}

final class _VaultExportDialogState extends State<_VaultExportDialog> {
  late final VaultExportService _service;
  VaultExportResult? _result;
  Object? _error;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _service = VaultExportService(store: widget.workspace.store);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: const Text('导出与备份'),
      content: SizedBox(
        width: 520,
        child: result == null
            ? _buildConfirmation(context)
            : _buildSuccess(result),
      ),
      actions: <Widget>[
        if (result != null)
          TextButton.icon(
            key: const Key('open-export-folder-button'),
            onPressed: _openExportFolder,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('打开文件夹'),
          ),
        TextButton(
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          child: Text(result == null ? '取消' : '完成'),
        ),
        if (result == null)
          FilledButton.icon(
            key: const Key('confirm-export-button'),
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt),
            label: Text(_exporting ? '正在校验…' : '开始导出'),
          ),
      ],
    );
  }

  Widget _buildConfirmation(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        '将当前便签、尚未整理的草稿、全部版本历史和冲突记录导出到：',
        style: TextStyle(height: 1.5),
      ),
      const SizedBox(height: 10),
      SelectableText(
        _service.destinationRoot.path,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '注意：导出文件是可直接阅读的明文备份。请妥善保管。Vault 密钥、密码及 R2 访问凭据不会被导出。',
            style: TextStyle(height: 1.45),
          ),
        ),
      ),
      if (_error case final error?) ...<Widget>[
        const SizedBox(height: 14),
        Text(
          '导出失败：$error',
          key: const Key('export-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );

  Widget _buildSuccess(VaultExportResult result) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Row(
        children: <Widget>[
          Icon(Icons.verified_outlined, color: Color(0xff557a61)),
          SizedBox(width: 8),
          Text('备份已完成并通过完整性校验'),
        ],
      ),
      const SizedBox(height: 14),
      SelectableText(result.directory.path),
      const SizedBox(height: 12),
      Text(
        '${result.noteCount} 条便签 · ${result.revisionCount} 个历史版本 · '
        '${result.conflictCount} 条冲突记录',
      ),
    ],
  );

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      await widget.workspace.flush();
      final result = await _service.exportPortableSnapshot();
      if (mounted) {
        setState(() => _result = result);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _openExportFolder() {
    final result = _result;
    if (result == null) {
      return;
    }
    unawaited(
      Process.start('explorer.exe', <String>[
        result.directory.path,
      ], mode: ProcessStartMode.detached),
    );
  }
}
