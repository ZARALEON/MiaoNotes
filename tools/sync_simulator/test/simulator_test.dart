import 'package:miaonotes_sync_simulator/simulator.dart';
import 'package:test/test.dart';

void main() {
  test('all protocol-v1 release-gate scenarios pass', () async {
    final results = await runAllScenarios();
    final failures = results.where((result) => !result.passed).toList();
    expect(
      failures,
      isEmpty,
      reason: failures
          .map((failure) => '${failure.name}: ${failure.error}')
          .join('\n'),
    );
  });
}
