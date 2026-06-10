import 'dart:io';
import 'package:path/path.dart' as path;
import 'game_data_module.dart';

abstract class GameDataManager {
  final Directory rootDirectory;

  late final Directory dataDirectory;
  late final Directory localDirectory;

  GameDataManager({required this.rootDirectory}) {
    dataDirectory = Directory(path.join(rootDirectory.path, 'data'));
    localDirectory = Directory(path.join(rootDirectory.path, '.local'));
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

  static Future<bool> isDirectoryEmpty(Directory dir) async {
    if (!await dir.exists()) return true;
    await for (final _ in dir.list()) {
      return false;
    }
    return true;
  }
}
