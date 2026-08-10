import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import '../application/note_workspace_controller.dart';

final class TagFilterSelection {
  const TagFilterSelection(this.tag);

  final String? tag;
}

Future<TagFilterSelection?> showTagFilterDialog(
  BuildContext context, {
  required NoteWorkspaceController workspace,
}) => showDialog<TagFilterSelection>(
  context: context,
  builder: (context) => _TagFilterDialog(workspace: workspace),
);

final class _TagFilterDialog extends StatefulWidget {
  const _TagFilterDialog({required this.workspace});

  final NoteWorkspaceController workspace;

  @override
  State<_TagFilterDialog> createState() => _TagFilterDialogState();
}

final class _TagFilterDialogState extends State<_TagFilterDialog> {
  List<StoredTagSummary>? _tags;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final tags = await widget.workspace.tagSummaries();
      if (mounted) {
        setState(() => _tags = tags);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('按标签筛选'),
    content: SizedBox(
      key: const Key('tag-filter-dialog'),
      width: 420,
      height: 360,
      child: _body(context),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
    ],
  );

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '无法读取标签，本地便签未受影响。',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    final tags = _tags;
    if (tags == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      children: <Widget>[
        ListTile(
          key: const Key('tag-option-all'),
          leading: const Icon(Icons.notes),
          title: const Text('全部便签'),
          trailing: widget.workspace.selectedTag == null
              ? const Icon(Icons.check)
              : null,
          onTap: () =>
              Navigator.of(context).pop(const TagFilterSelection(null)),
        ),
        const Divider(),
        if (tags.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('还没有标签。可以在编辑器标题下方添加。'),
          ),
        for (final summary in tags)
          ListTile(
            key: ValueKey<String>('tag-option-${summary.tag}'),
            leading: const Icon(Icons.label_outline),
            title: Text(summary.tag),
            subtitle: Text('${summary.noteCount} 条便签'),
            trailing: widget.workspace.selectedTag == summary.tag
                ? const Icon(Icons.check)
                : null,
            onTap: () =>
                Navigator.of(context).pop(TagFilterSelection(summary.tag)),
          ),
      ],
    );
  }
}
