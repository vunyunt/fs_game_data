import 'dart:convert';
import 'dart:io';

import 'package:fs_game_data/fs_game_data.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _StubModule extends GameDataModule {
  _StubModule({required super.dataDirectory})
    : super(fileName: 'manifest.binpb');

  @override
  Future<void> load() async {}

  @override
  Future<void> save() async {}

  @override
  Future<void> initialize() async {
    await file.writeAsBytes(<int>[0]);
  }
}

class _StubManager extends GameDataManager {
  _StubManager({required super.rootDirectory, required super.applicationId});

  @override
  List<GameDataModule> get modules => [_indicator];

  late final _StubModule _indicator = _StubModule(dataDirectory: dataDirectory);

  @override
  GameDataModule get initializationIndicatorModule => _indicator;
}

void main() {
  group('GameDataManager application ID', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fs_game_data_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initializeNewFolder writes data/.application_id', () async {
      final manager = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'app-a',
      );

      await manager.initializeNewFolder();

      final file = File(path.join(tempDir.path, 'data', '.application_id'));
      expect(await file.exists(), isTrue);
      expect((await file.readAsString()).trim(), equals('app-a'));
    });

    test('loadAll succeeds when application ID matches', () async {
      final writer = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'app-a',
      );
      await writer.initializeNewFolder();

      final reader = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'app-a',
      );
      await reader.loadAll();
    });

    test(
      'loadAll writes application ID on first load (legacy migration)',
      () async {
        final writer = _StubManager(
          rootDirectory: tempDir,
          applicationId: 'app-a',
        );
        await writer.initializeNewFolder();

        final file = File(path.join(tempDir.path, 'data', '.application_id'));
        await file.delete();

        final reader = _StubManager(
          rootDirectory: tempDir,
          applicationId: 'app-a',
        );
        await reader.loadAll();

        expect(await file.exists(), isTrue);
        expect((await file.readAsString()).trim(), equals('app-a'));
      },
    );

    test(
      'loadAll throws WrongApplicationIdException when application ID mismatches',
      () async {
        final writer = _StubManager(
          rootDirectory: tempDir,
          applicationId: 'app-a',
        );
        await writer.initializeNewFolder();

        final reader = _StubManager(
          rootDirectory: tempDir,
          applicationId: 'app-b',
        );

        await expectLater(
          () => reader.loadAll(),
          throwsA(isA<WrongApplicationIdException>()),
        );
      },
    );

    test(
      'WrongApplicationIdException exposes expected and actual values',
      () async {
        final exception = WrongApplicationIdException(
          directoryPath: '/tmp/foo',
          expected: 'expected-id',
          actual: 'actual-id',
        );

        expect(exception.directoryPath, equals('/tmp/foo'));
        expect(exception.expected, equals('expected-id'));
        expect(exception.actual, equals('actual-id'));
        expect(exception.toString(), contains('WrongApplicationIdException'));
      },
    );

    test('application ID file tolerates trailing whitespace', () async {
      final writer = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'app-a',
      );
      await writer.initializeNewFolder();

      final file = File(path.join(tempDir.path, 'data', '.application_id'));
      await file.writeAsString('  app-a\n');

      final reader = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'app-a',
      );
      await reader.loadAll();
    });

    test(
      'non-empty dir without indicator still throws original exception',
      () async {
        final stray = File(path.join(tempDir.path, 'stray.txt'));
        await stray.writeAsString('hello');

        final manager = _StubManager(
          rootDirectory: tempDir,
          applicationId: 'app-a',
        );

        await expectLater(
          () => manager.loadAll(),
          throwsA(isA<UninitializedNonEmptyDirectoryException>()),
        );
      },
    );
  });

  group('UTF-8 boundary', () {
    test('handles multi-byte application ID', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'fs_game_data_utf8_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final writer = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'test-app-id',
      );
      await writer.initializeNewFolder();

      final file = File(path.join(tempDir.path, 'data', '.application_id'));
      final raw = utf8.decode(await file.readAsBytes());
      expect(raw, equals('test-app-id'));

      final reader = _StubManager(
        rootDirectory: tempDir,
        applicationId: 'test-app-id',
      );
      await reader.loadAll();
    });
  });
}
