import 'dart:async';

import 'package:flutter/material.dart';

import '../application/miaonotes_application.dart';
import 'miaonotes_shell.dart';

typedef ApplicationOpener = Future<MiaoNotesApplication> Function();

final class MiaoNotesBootstrap extends StatefulWidget {
  const MiaoNotesBootstrap({required this.openApplication, super.key});

  final ApplicationOpener openApplication;

  @override
  State<MiaoNotesBootstrap> createState() => _MiaoNotesBootstrapState();
}

final class _MiaoNotesBootstrapState extends State<MiaoNotesBootstrap>
    with WidgetsBindingObserver {
  MiaoNotesApplication? _application;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final application = _application;
      if (application != null) {
        unawaited(_ignoreFailure(application.workspace.flush()));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final application = _application;
    if (application != null) {
      unawaited(_ignoreFailure(application.close()));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;
    if (application != null) {
      return MiaoNotesShell(
        workspace: application.workspace,
        localCommits: application.localCommits,
        remoteSync: application.remoteSync,
        syncSettings: application.syncSettings,
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMiaoNotesTheme(),
      home: _StartupView(error: _startupError, onRetry: _retry),
    );
  }

  Future<void> _open() async {
    try {
      final application = await widget.openApplication();
      if (!mounted) {
        await application.close();
        return;
      }
      setState(() {
        _application = application;
        _startupError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(application.startBackgroundWork());
        }
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _startupError = error);
      }
    }
  }

  void _retry() {
    if (_startupError == null) {
      return;
    }
    setState(() => _startupError = null);
    unawaited(_open());
  }
}

Future<void> _ignoreFailure(Future<void> operation) async {
  try {
    await operation;
  } on Object {
    // The workspace already exposes save failures in its visible save state.
  }
}

final class _StartupView extends StatelessWidget {
  const _StartupView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final startupError = error;
    return Scaffold(
      body: Center(
        child: startupError == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '喵喵便签',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 18),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ],
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline, size: 34),
                    const SizedBox(height: 12),
                    const Text(
                      '本地便签暂时无法打开',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      startupError.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: onRetry, child: const Text('重试')),
                  ],
                ),
              ),
      ),
    );
  }
}
