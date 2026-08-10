import 'dart:io';

import 'package:miaonotes_sync_simulator/simulator.dart';

Future<void> main() async {
  final results = await runAllScenarios();
  for (final result in results) {
    if (result.passed) {
      stdout.writeln('PASS  ${result.name}');
    } else {
      stderr.writeln('FAIL  ${result.name}: ${result.error}');
    }
  }
  final failures = results.where((result) => !result.passed).length;
  stdout.writeln(
    '${results.length - failures}/${results.length} scenarios passed',
  );
  if (failures > 0) {
    exitCode = 1;
  }
}
