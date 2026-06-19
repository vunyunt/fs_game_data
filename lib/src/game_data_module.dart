import 'dart:io';
import 'package:path/path.dart' as path;

abstract class GameDataModule {
  final Directory dataDirectory;
  final String fileName;

  GameDataModule({
    required this.dataDirectory,
    required this.fileName,
  });

  File get file => File(path.join(dataDirectory.path, fileName));

  Future<void> load();
  Future<void> save();
  Future<void> initialize();

  Future<bool> exists() => file.exists();
}

class GameDataInitializationException implements Exception {
  final String message;
  GameDataInitializationException(this.message);

  @override
  String toString() => 'GameDataInitializationException: $message';
}

class UninitializedNonEmptyDirectoryException
    extends GameDataInitializationException {
  final String directoryPath;
  UninitializedNonEmptyDirectoryException(this.directoryPath)
    : super(
        'Directory is not empty and not a game data directory: $directoryPath',
      );

  @override
  String toString() => 'UninitializedNonEmptyDirectoryException: $message';
}

class MissingMachineIdException implements Exception {
  @override
  String toString() => 'Machine ID is not set for this data folder.';
}

class WrongApplicationIdException extends GameDataInitializationException {
  final String directoryPath;
  final String expected;
  final String actual;
  WrongApplicationIdException({
    required this.directoryPath,
    required this.expected,
    required this.actual,
  }) : super(
         'Wrong application ID for data folder "$directoryPath": expected "$expected", found "$actual"',
       );

  @override
  String toString() => 'WrongApplicationIdException: $message';
}
