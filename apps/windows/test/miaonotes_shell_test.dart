import 'package:flutter/material.dart';
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
