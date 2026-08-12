import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:miaonotes_windows/src/application/miaonotes_application.dart';
import 'package:miaonotes_windows/src/ui/miaonotes_bootstrap.dart';
import 'package:miaonotes_windows/src/ui/miaonotes_shell.dart';

void main() {
  testWidgets('editor accepts input immediately and autosaves it', (
    tester,
  ) async {
    final app = await _openTestApplication();
    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );
    await tester.pump();

    expect(find.text('喵喵便签'), findsOneWidget);
    expect(find.byKey(const Key('import-notes-button')), findsOneWidget);
    expect(find.byKey(const Key('export-notes-button')), findsOneWidget);
    expect(find.byKey(const Key('note-body-field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('note-body-field')), '一打开就可以写');
    await tester.pump();
    await app.workspace.flush();

    expect(app.workspace.notes.single.bodyPreview, '一打开就可以写');
    expect(find.text('已保存到本地'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await app.close();
  });

  testWidgets('idle editing creates a local revision and sync queue', (
    tester,
  ) async {
    final app = await _openTestApplication(
      localCommitIdleDelay: const Duration(milliseconds: 20),
    );
    await app.startBackgroundWork();
    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );

    await tester.enterText(find.byKey(const Key('note-body-field')), '空闲后生成版本');
    await app.workspace.flush();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();

    final recovery = await app.store.recoveryState();
    expect(recovery.revisions, 1);
    expect(recovery.pendingObjects, 2);
    expect(find.text('已保存 · 2 项等待同步'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await app.close();
  });

  testWidgets('sidebar search filters locally and can be cleared', (
    tester,
  ) async {
    final app = await _openTestApplication();
    final firstId = app.workspace.currentDraft!.noteId;
    app.workspace
      ..updateTitle('Alpha')
      ..updateBody('orchard checklist');
    await app.workspace.flush();
    await app.workspace.createNote();
    final secondId = app.workspace.currentDraft!.noteId;
    app.workspace
      ..updateTitle('Beta')
      ..updateBody('ocean journal');
    await app.workspace.flush();

    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-search-field')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await tester.enterText(find.byKey(const Key('note-search-field')), 'orch');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey<String>('note-list-$firstId')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('note-list-$secondId')), findsNothing);

    await tester.tap(find.byKey(const Key('clear-search-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey<String>('note-list-$firstId')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('note-list-$secondId')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('note-search-field')), 'ocean');
    await tester.tap(find.byKey(const Key('new-note-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(app.workspace.searchQuery, isEmpty);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-search-field')))
          .controller!
          .text,
      isEmpty,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await app.close();
  });

  testWidgets('delete confirmation and recycle bin restore a note', (
    tester,
  ) async {
    final app = await _openTestApplication();
    final noteId = app.workspace.currentDraft!.noteId;
    app.workspace
      ..updateTitle('Recover me')
      ..updateBody('recycle body');
    await app.workspace.flush();
    await app.localCommits.commitNow();

    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );
    await tester.tap(find.byKey(const Key('delete-note-button')));
    await tester.pumpAndSettle();
    expect(find.text('删除这条便签？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-note')));
    await tester.pumpAndSettle();
    expect(app.workspace.notes, isEmpty);

    await tester.tap(find.byKey(const Key('recycle-bin-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recycle-bin-dialog')), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('deleted-note-$noteId')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ValueKey<String>('restore-note-$noteId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recycle-bin-dialog')), findsNothing);
    expect(app.workspace.currentDraft!.noteId, noteId);
    expect(app.workspace.currentDraft!.body, 'recycle body');
    expect(find.byKey(ValueKey<String>('note-list-$noteId')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await app.close();
  });

  testWidgets('tag editor and on-demand filter narrow the sidebar', (
    tester,
  ) async {
    final app = await _openTestApplication();
    final workId = app.workspace.currentDraft!.noteId;
    app.workspace
      ..updateTitle('Work note')
      ..updateBody('roadmap')
      ..updateTags(const <String>['work']);
    await app.workspace.flush();
    await app.workspace.createNote();
    final personalId = app.workspace.currentDraft!.noteId;
    app.workspace
      ..updateTitle('Personal note')
      ..updateBody('journal')
      ..updateTags(const <String>['personal']);
    await app.workspace.flush();

    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );
    await tester.enterText(find.byKey(const Key('note-tag-field')), 'urgent');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await app.workspace.flush();
    expect(app.workspace.currentDraft!.tags, <String>['personal', 'urgent']);
    expect(
      find.byKey(const ValueKey<String>('note-tag-urgent')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-filter-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('tag-option-work')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-tag-filter')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('note-list-$workId')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('note-list-$personalId')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await app.close();
  });

  testWidgets('pin and sort controls update the local sidebar order', (
    tester,
  ) async {
    final app = await _openTestApplication();
    final firstId = app.workspace.currentDraft!.noteId;
    app.workspace.updateTitle('Zulu');
    await app.workspace.flush();
    await app.workspace.createNote();
    final secondId = app.workspace.currentDraft!.noteId;
    app.workspace.updateTitle('Alpha');
    await app.workspace.flush();

    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );
    await tester.tap(find.byKey(const Key('note-sort-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('标题 A–Z'));
    await tester.pumpAndSettle();
    expect(app.workspace.notes.first.noteId, secondId);

    await tester.tap(find.byKey(ValueKey<String>('note-list-$firstId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pin-note-button')));
    await tester.pumpAndSettle();
    expect(app.workspace.notes.first.noteId, firstId);
    expect(find.text('已置顶 · 仅此设备'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await app.close();
  });

  testWidgets('bootstrap renders local workspace before background work', (
    tester,
  ) async {
    var backgroundStarts = 0;
    late MiaoNotesApplication app;
    await tester.pumpWidget(
      MiaoNotesBootstrap(
        openApplication: () async {
          app = await _openTestApplication(
            backgroundTask: (_) async => backgroundStarts += 1,
          );
          return app;
        },
      ),
    );

    expect(backgroundStarts, 0);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-body-field')), findsOneWidget);
    expect(backgroundStarts, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await app.close();
  });
}

Future<MiaoNotesApplication> _openTestApplication({
  BackgroundTask? backgroundTask,
  Duration localCommitIdleDelay = const Duration(seconds: 2),
}) {
  final clock = _AdvancingClock();
  return MiaoNotesApplication.open(
    database: MiaoNotesDatabase.inMemory(),
    idFactory: SequenceIdFactory('widget'),
    clock: clock.call,
    backgroundTask: backgroundTask,
    localCommitIdleDelay: localCommitIdleDelay,
  );
}

final class _AdvancingClock {
  DateTime _now = DateTime.utc(2026, 8, 10, 17);

  DateTime call() {
    final result = _now;
    _now = _now.add(const Duration(milliseconds: 1));
    return result;
  }
}
