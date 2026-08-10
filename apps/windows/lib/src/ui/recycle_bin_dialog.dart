import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import '../application/local_commit_coordinator.dart';
import '../application/note_workspace_controller.dart';

Future<bool> showRecycleBinDialog(
  BuildContext context, {
  required NoteWorkspaceController workspace,
  required LocalCommitCoordinator localCommits,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          _RecycleBinDialog(workspace: workspace, localCommits: localCommits),
    ) ??
    false;

final class _RecycleBinDialog extends StatefulWidget {
  const _RecycleBinDialog({
    required this.workspace,
    required this.localCommits,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;

  @override
  State<_RecycleBinDialog> createState() => _RecycleBinDialogState();
}

final class _RecycleBinDialogState extends State<_RecycleBinDialog> {
  List<StoredNoteSummary>? _notes;
  Object? _error;
  String? _restoringNoteId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final notes = await widget.workspace.deletedNotes();
      if (mounted) {
        setState(() => _notes = notes);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _restore(String noteId) async {
    setState(() {
      _restoringNoteId = noteId;
      _error = null;
    });
    try {
      final restored = await widget.workspace.restoreDeletedNote(noteId);
      if (!restored) {
        throw StateError('The note is no longer available in the recycle bin');
      }
      await widget.localCommits.refreshPendingRemoteObjects();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _restoringNoteId = null;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('回收站'),
    content: SizedBox(
      key: const Key('recycle-bin-dialog'),
      width: 520,
      height: 360,
      child: _body(context),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('关闭'),
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
              '无法读取回收站，本地数据未受影响。',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    final notes = _notes;
    if (notes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notes.isEmpty) {
      return const Center(child: Text('回收站是空的。'));
    }
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final note = notes[index];
        final title = note.title.trim().isEmpty ? '无标题便签' : note.title.trim();
        final preview = note.bodyPreview.trim().replaceAll('\n', ' ');
        final restoring = _restoringNoteId == note.noteId;
        return ListTile(
          key: ValueKey<String>('deleted-note-${note.noteId}'),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: preview.isEmpty
              ? null
              : Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: restoring
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton.icon(
                  key: ValueKey<String>('restore-note-${note.noteId}'),
                  onPressed: _restoringNoteId == null
                      ? () => unawaited(_restore(note.noteId))
                      : null,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('恢复'),
                ),
        );
      },
    );
  }
}
