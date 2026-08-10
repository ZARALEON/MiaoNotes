import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import '../application/local_commit_coordinator.dart';
import '../application/note_workspace_controller.dart';

Future<void> showConflictCenterDialog(
  BuildContext context, {
  required NoteWorkspaceController workspace,
  required LocalCommitCoordinator localCommits,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      ConflictCenterDialog(workspace: workspace, localCommits: localCommits),
);

final class ConflictCenterDialog extends StatefulWidget {
  const ConflictCenterDialog({
    required this.workspace,
    required this.localCommits,
    super.key,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;

  @override
  State<ConflictCenterDialog> createState() => _ConflictCenterDialogState();
}

final class _ConflictCenterDialogState extends State<ConflictCenterDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  List<StoredConflict> _conflicts = const <StoredConflict>[];
  ConflictDetails? _details;
  Revision? _selected;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: <Widget>[
        const Icon(Icons.call_split),
        const SizedBox(width: 10),
        const Expanded(child: Text('同步冲突')),
        if (_conflicts.isNotEmpty)
          Text(
            '${_conflicts.length} 项',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    ),
    content: SizedBox(
      width: 900,
      height: 560,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
          ? const _NoConflictsView()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(width: 230, child: _buildConflictList()),
                const VerticalDivider(width: 28),
                Expanded(child: _buildDetails()),
              ],
            ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: Text(_conflicts.isEmpty ? '关闭' : '稍后处理'),
      ),
      if (_conflicts.isNotEmpty)
        FilledButton.icon(
          key: const Key('resolve-conflict-button'),
          onPressed: _busy || _selected == null ? null : _resolve,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.merge),
          label: const Text('保存合并版本'),
        ),
    ],
  );

  Widget _buildConflictList() => ListView.builder(
    itemCount: _conflicts.length,
    itemBuilder: (context, index) {
      final conflict = _conflicts[index];
      final selected = conflict.conflictId == _details?.conflict.conflictId;
      return ListTile(
        key: Key('conflict-item-${conflict.conflictId}'),
        selected: selected,
        title: Text(
          '便签 ${_shortId(conflict.noteId)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${conflict.headRevisionIds.length} 个并发版本'),
        onTap: _busy ? null : () => _loadDetails(conflict),
      );
    },
  );

  Widget _buildDetails() {
    final details = _details;
    if (details == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selected = _selected;
    final isMarkdown = selected?.format == ContentFormat.markdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          '选择一个版本作为起点。你可以继续编辑后再保存；所有原版本都会作为历史保留。',
          style: TextStyle(color: Color(0xff6f625d)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: details.versions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final version = details.versions[index];
              return _VersionCard(
                version: version,
                selected: version.revisionId == selected?.revisionId,
                onTap: _busy ? null : () => _selectVersion(version),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('conflict-merged-title-field'),
          controller: _title,
          enabled: !_busy && selected != null,
          decoration: const InputDecoration(
            labelText: '合并后的标题',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isMarkdown
              ? TextField(
                  key: const Key('conflict-merged-body-field'),
                  controller: _body,
                  enabled: !_busy,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: '合并后的正文',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                )
              : const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xfffff6f1),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('这是富文本版本。本阶段会完整保留所选版本；可编辑的结构化合并将在富文本编辑器阶段开放。'),
                  ),
                ),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _error!,
            key: const Key('conflict-center-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final conflicts = await widget.workspace.store.openConflicts();
      if (!mounted) {
        return;
      }
      _conflicts = conflicts;
      if (conflicts.isEmpty) {
        setState(() {
          _details = null;
          _selected = null;
          _loading = false;
        });
        return;
      }
      await _loadDetails(conflicts.first, showLoading: false);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '读取冲突失败：$error';
        });
      }
    }
  }

  Future<void> _loadDetails(
    StoredConflict conflict, {
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _details = null;
        _selected = null;
        _error = null;
      });
    }
    final details = await widget.workspace.store.loadConflictDetails(
      conflict.conflictId,
    );
    if (!mounted) {
      return;
    }
    if (details == null || details.versions.isEmpty) {
      await _reload();
      return;
    }
    setState(() {
      _details = details;
      _loading = false;
      _error = null;
    });
    _selectVersion(details.versions.first);
  }

  void _selectVersion(Revision version) {
    setState(() {
      _selected = version;
      _title.text = version.title;
      _body.text = version.format == ContentFormat.markdown
          ? version.body as String
          : canonicalJson(version.body);
      _error = null;
    });
  }

  Future<void> _resolve() async {
    final selected = _selected!;
    final details = _details!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.workspace.resolveConflict(
        conflictId: details.conflict.conflictId,
        format: selected.format,
        title: _title.text,
        body: selected.format == ContentFormat.markdown
            ? _body.text
            : selected.body,
        tags: selected.tags,
        deleted: selected.operation == RevisionOperation.tombstone,
      );
      await widget.localCommits.refreshPendingRemoteObjects();
      await _reload();
    } on ConflictResolutionException catch (error) {
      if (mounted) {
        setState(
          () => _error = switch (error.message) {
            'The note has an uncommitted local edit' =>
              '这条便签还有尚未整理成版本的本地编辑。请先返回编辑器保存，再重新打开冲突中心。',
            'The conflict changed while it was being reviewed' =>
              '同步期间出现了新版本，冲突已变化，请重新检查。',
            _ => '无法保存合并版本：${error.message}',
          },
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = '无法保存合并版本：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

final class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.selected,
    required this.onTap,
  });

  final Revision version;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final deleted = version.operation == RevisionOperation.tombstone;
    final body = version.format == ContentFormat.markdown
        ? version.body as String
        : jsonEncode(version.body);
    return SizedBox(
      width: 245,
      child: Material(
        color: selected ? const Color(0xffffe6e7) : const Color(0xfffffbf8),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xffeadfda),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          key: Key('conflict-version-${version.revisionId}'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        deleted ? '已删除版本' : _versionTitle(version),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${version.deviceId} · ${_formatTime(version.createdAtUtc)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff806f69),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    deleted ? '此设备删除了便签。' : body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _NoConflictsView extends StatelessWidget {
  const _NoConflictsView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: 44, color: Color(0xff557a61)),
        SizedBox(height: 12),
        Text('没有需要处理的同步冲突'),
      ],
    ),
  );
}

String _versionTitle(Revision revision) =>
    revision.title.trim().isEmpty ? '无标题版本' : revision.title.trim();

String _shortId(String value) =>
    value.length <= 10 ? value : '${value.substring(0, 10)}…';

String _formatTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.month}/${local.day} ${two(local.hour)}:${two(local.minute)}';
}
