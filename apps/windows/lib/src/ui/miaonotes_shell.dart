import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import '../application/local_commit_coordinator.dart';
import '../application/note_workspace_controller.dart';
import '../application/remote_sync_coordinator.dart';
import '../application/sync_settings_controller.dart';
import 'conflict_center_dialog.dart';
import 'export_dialog.dart';
import 'sync_settings_dialog.dart';

ThemeData buildMiaoNotesTheme() {
  const seed = Color(0xffb65365);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: const Color(0xfffffbf8),
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Microsoft YaHei UI',
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      isDense: true,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xffeadfda),
      thickness: 1,
      space: 1,
    ),
  );
}

final class MiaoNotesShell extends StatelessWidget {
  const MiaoNotesShell({
    required this.workspace,
    required this.localCommits,
    this.remoteSync,
    this.syncSettings,
    super.key,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final RemoteSyncCoordinator? remoteSync;
  final SyncSettingsController? syncSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MiaoNotes',
      theme: buildMiaoNotesTheme(),
      home: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
            unawaited(_ignoreFailure(workspace.createNote()));
          },
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            unawaited(_ignoreFailure(localCommits.commitNow()));
          },
        },
        child: Focus(
          autofocus: true,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              workspace,
              localCommits,
              ?remoteSync,
              ?syncSettings,
            ]),
            builder: (context, _) {
              final activeRemote = syncSettings?.remoteSync ?? remoteSync;
              return _WorkspaceView(
                workspace: workspace,
                localCommits: localCommits,
                remoteSync: activeRemote,
                syncSettings: syncSettings,
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _WorkspaceView extends StatelessWidget {
  const _WorkspaceView({
    required this.workspace,
    required this.localCommits,
    required this.remoteSync,
    required this.syncSettings,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final RemoteSyncCoordinator? remoteSync;
  final SyncSettingsController? syncSettings;

  @override
  Widget build(BuildContext context) {
    final draft = workspace.currentDraft;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 286,
              child: _NotesSidebar(
                workspace: workspace,
                localCommits: localCommits,
                syncSettings: syncSettings,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: draft == null
                  ? const SizedBox.shrink()
                  : _NoteEditor(
                      key: ValueKey<String>(draft.noteId),
                      draft: draft,
                      workspace: workspace,
                      localCommits: localCommits,
                      remoteSync: remoteSync,
                      syncSettings: syncSettings,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NotesSidebar extends StatelessWidget {
  const _NotesSidebar({
    required this.workspace,
    required this.localCommits,
    required this.syncSettings,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final SyncSettingsController? syncSettings;

  @override
  Widget build(BuildContext context) {
    final notes = workspace.notes;
    final selectedId = workspace.currentDraft?.noteId;
    return ColoredBox(
      color: const Color(0xfffff6f1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    '喵喵便签',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (localCommits.openConflicts > 0)
                  Badge(
                    label: Text('${localCommits.openConflicts}'),
                    child: IconButton(
                      key: const Key('conflict-center-button'),
                      tooltip: '处理同步冲突',
                      onPressed: () => unawaited(
                        showConflictCenterDialog(
                          context,
                          workspace: workspace,
                          localCommits: localCommits,
                        ),
                      ),
                      icon: const Icon(Icons.call_split, size: 20),
                    ),
                  ),
                if (syncSettings case final settings?)
                  IconButton(
                    key: const Key('sync-settings-button'),
                    tooltip: '同步设置',
                    onPressed: () =>
                        unawaited(showSyncSettingsDialog(context, settings)),
                    icon: const Icon(Icons.cloud_outlined, size: 20),
                  ),
                IconButton(
                  key: const Key('export-notes-button'),
                  tooltip: '导出与备份',
                  onPressed: () => unawaited(
                    showVaultExportDialog(context, workspace: workspace),
                  ),
                  icon: const Icon(Icons.save_alt_outlined, size: 20),
                ),
                IconButton.filledTonal(
                  key: const Key('new-note-button'),
                  tooltip: '新建便签  Ctrl+N',
                  onPressed: () =>
                      unawaited(_ignoreFailure(workspace.createNote())),
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: notes.isEmpty
                ? const _EmptyNotesHint()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteListTile(
                        note: note,
                        selected: note.noteId == selectedId,
                        onTap: () => unawaited(
                          _ignoreFailure(workspace.selectNote(note.noteId)),
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Text(
              '本地优先 · 自动保存',
              style: TextStyle(fontSize: 12, color: Color(0xff8a7770)),
            ),
          ),
        ],
      ),
    );
  }
}

final class _EmptyNotesHint extends StatelessWidget {
  const _EmptyNotesHint();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: Text(
      '直接在右侧输入，第一条便签会自动保存。',
      style: TextStyle(color: Color(0xff8a7770), height: 1.5),
    ),
  );
}

final class _NoteListTile extends StatelessWidget {
  const _NoteListTile({
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final StoredNoteSummary note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty ? '无标题便签' : note.title.trim();
    final preview = note.bodyPreview.trim().replaceAll('\n', ' ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      child: Material(
        color: selected ? const Color(0xffffe6e7) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (preview.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff806f69),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.draft,
    required this.workspace,
    required this.localCommits,
    required this.remoteSync,
    required this.syncSettings,
    super.key,
  });

  final NoteDraft draft;
  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final RemoteSyncCoordinator? remoteSync;
  final SyncSettingsController? syncSettings;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

final class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final FocusNode _bodyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.draft.title);
    _bodyController = TextEditingController(text: widget.draft.body as String);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bodyFocus.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeController(_titleController, widget.draft.title);
    _synchronizeController(_bodyController, widget.draft.body as String);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(34, 26, 34, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: const Key('note-title-field'),
          controller: _titleController,
          onChanged: widget.workspace.updateTitle,
          maxLines: 1,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: '标题',
            hintStyle: TextStyle(color: Color(0xffc1aaa3)),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: TextField(
            key: const Key('note-body-field'),
            controller: _bodyController,
            focusNode: _bodyFocus,
            onChanged: widget.workspace.updateBody,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 16, height: 1.65),
            decoration: const InputDecoration(
              hintText: '现在就记下来…',
              hintStyle: TextStyle(color: Color(0xffc1aaa3)),
            ),
          ),
        ),
        _SaveStatus(
          workspace: widget.workspace,
          localCommits: widget.localCommits,
          remoteSync: widget.remoteSync,
          syncSettings: widget.syncSettings,
        ),
      ],
    ),
  );
}

final class _SaveStatus extends StatelessWidget {
  const _SaveStatus({
    required this.workspace,
    required this.localCommits,
    required this.remoteSync,
    required this.syncSettings,
  });

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final RemoteSyncCoordinator? remoteSync;
  final SyncSettingsController? syncSettings;

  @override
  Widget build(BuildContext context) {
    final saveFailed = workspace.saveState == DraftSaveState.failed;
    final commitFailed = localCommits.state == LocalCommitState.failed;
    final remoteFailed =
        remoteSync != null &&
        remoteSync!.state != RemoteSyncState.idle &&
        remoteSync!.state != RemoteSyncState.syncing;
    final settingsFailed =
        syncSettings?.state == SyncSettingsState.failed ||
        syncSettings?.state == SyncSettingsState.vaultMismatch;
    final (label, color) = switch ((workspace.saveState, localCommits.state)) {
      (DraftSaveState.failed, _) => (
        '保存失败',
        Theme.of(context).colorScheme.error,
      ),
      (DraftSaveState.saving, _) => ('正在保存…', const Color(0xff8a7770)),
      (_, LocalCommitState.failed) => (
        '后台整理失败',
        Theme.of(context).colorScheme.error,
      ),
      (_, LocalCommitState.committing) => (
        '正在整理本地版本…',
        const Color(0xff8a7770),
      ),
      (_, LocalCommitState.waiting) => (
        '已保存 · 等待后台整理',
        const Color(0xff557a61),
      ),
      _ when syncSettings?.state == SyncSettingsState.vaultMismatch => (
        '已保存 · Vault 不匹配，未同步',
        Theme.of(context).colorScheme.error,
      ),
      _ when syncSettings?.state == SyncSettingsState.failed => (
        '已保存 · 同步配置需要检查',
        Theme.of(context).colorScheme.error,
      ),
      _
          when syncSettings?.state == SyncSettingsState.loading ||
              syncSettings?.state == SyncSettingsState.connecting =>
        ('已保存 · 正在检查同步配置…', const Color(0xff8a7770)),
      _ when remoteSync?.state == RemoteSyncState.authenticationFailed => (
        '已保存 · 同步凭据无效',
        Theme.of(context).colorScheme.error,
      ),
      _ when remoteSync?.state == RemoteSyncState.offline => (
        '已保存 · 当前离线',
        const Color(0xff8a7770),
      ),
      _ when remoteSync?.state == RemoteSyncState.failed => (
        '已保存 · 同步失败',
        Theme.of(context).colorScheme.error,
      ),
      _ when remoteSync?.state == RemoteSyncState.syncing => (
        '已保存 · 正在同步…',
        const Color(0xff557a61),
      ),
      _ when localCommits.pendingRemoteObjects > 0 => (
        '已保存 · ${localCommits.pendingRemoteObjects} 项等待同步',
        const Color(0xff557a61),
      ),
      (DraftSaveState.saved, _) => ('已保存到本地', const Color(0xff557a61)),
      _ => ('输入后自动保存', const Color(0xff8a7770)),
    };
    return SizedBox(
      key: const Key('save-status'),
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          if (saveFailed || commitFailed || remoteFailed) ...<Widget>[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => unawaited(
                _ignoreFailure(
                  saveFailed
                      ? workspace.retrySave()
                      : commitFailed
                      ? localCommits.commitNow()
                      : remoteSync!.syncNow(),
                ),
              ),
              child: const Text('重试'),
            ),
          ],
          if (settingsFailed) ...<Widget>[
            const SizedBox(width: 6),
            const Text('请打开同步设置', style: TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

Future<void> _ignoreFailure<T>(Future<T> operation) async {
  try {
    await operation;
  } on Object {
    // Save failures stay visible and retryable through the workspace state.
  }
}

void _synchronizeController(TextEditingController controller, String text) {
  if (controller.text == text) {
    return;
  }
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
