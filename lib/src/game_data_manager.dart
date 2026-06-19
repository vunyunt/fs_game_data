import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'game_data_module.dart';

abstract class GameDataManager {
  // The on-disk filename where the application ID is stored.
  static const String _applicationIdFileName = '.application_id';

  final Directory rootDirectory;
  final String applicationId;

  late final Directory dataDirectory;
  late final Directory localDirectory;
  late final File _applicationIdFile;

  GameDataManager({
    required this.rootDirectory,
    required this.applicationId,
  }) {
    dataDirectory = Directory(path.join(rootDirectory.path, 'data'));
    localDirectory = Directory(path.join(rootDirectory.path, '.local'));
    _applicationIdFile = File(
      path.join(dataDirectory.path, _applicationIdFileName),
    );
  }

  /// List of all game data modules managed by this coordinator.
  List<GameDataModule> get modules;

  /// The specific module used to check if the directory has been initialized.
  GameDataModule get initializationIndicatorModule;

  Future<void> loadAll() async {
    if (!await rootDirectory.exists() || await isDirectoryEmpty(rootDirectory)) {
      await initializeNewFolder();
      return;
    }

    if (!await localDirectory.exists()) {
      await localDirectory.create(recursive: true);
    }

    if (!await initializationIndicatorModule.exists()) {
      throw UninitializedNonEmptyDirectoryException(rootDirectory.path);
    }

    await _verifyOrWriteApplicationId();

    for (final module in modules) {
      await module.load();
    }

    await postLoad();
  }

  Future<void> initializeNewFolder() async {
    if (await rootDirectory.exists() && !await isDirectoryEmpty(rootDirectory)) {
      throw UninitializedNonEmptyDirectoryException(rootDirectory.path);
    }

    if (!await rootDirectory.exists()) {
      await rootDirectory.create(recursive: true);
    }

    if (!await dataDirectory.exists()) {
      await dataDirectory.create(recursive: true);
    }

    if (!await localDirectory.exists()) {
      await localDirectory.create(recursive: true);
    }

    await _writeApplicationId();

    for (final module in modules) {
      await module.initialize();
    }

    await postInitialize();
  }

  Future<void> saveAll() async {
    for (final module in modules) {
      await module.save();
    }
  }

  Future<void> postLoad() async {}
  Future<void> postInitialize() async {}

  Future<void> _verifyOrWriteApplicationId() async {
    final existing = await _readApplicationId();
    if (existing == null) {
      await _writeApplicationId();
      return;
    }
    if (existing != applicationId) {
      throw WrongApplicationIdException(
        directoryPath: rootDirectory.path,
        expected: applicationId,
        actual: existing,
      );
    }
  }

  Future<String?> _readApplicationId() async {
    if (!await _applicationIdFile.exists()) return null;
    return utf8.decode(await _applicationIdFile.readAsBytes()).trim();
  }

  Future<void> _writeApplicationId() async {
    if (!await dataDirectory.exists()) {
      await dataDirectory.create(recursive: true);
    }
    await _applicationIdFile.writeAsBytes(utf8.encode(applicationId));
  }

  static Future<bool> isDirectoryEmpty(Directory dir) async {
    if (!await dir.exists()) return true;
    await for (final _ in dir.list()) {
      return false;
    }
    return true;
  }
}
