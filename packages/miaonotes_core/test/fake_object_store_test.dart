import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  test('immutable writes are idempotent but reject changed bytes', () async {
    final store = FakeObjectStore();
    await store.putImmutable('key', <int>[1, 2, 3]);
    await store.putImmutable('key', <int>[1, 2, 3]);
    await expectLater(
      store.putImmutable('key', <int>[3, 2, 1]),
      throwsA(isA<ImmutableObjectConflict>()),
    );
  });

  test('failure after write models an ambiguous S3 response', () async {
    final store = FakeObjectStore()..failPutsAfterWriteRemaining = 1;
    await expectLater(
      store.putImmutable('key', <int>[1]),
      throwsA(isA<ObjectStoreUnavailable>()),
    );
    expect((await store.get('key'))!.bytes, <int>[1]);
    await store.putImmutable('key', <int>[1]);
  });
}
