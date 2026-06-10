import 'dart:convert';
import '../game_data_module.dart';

abstract class JsonGameDataModule extends GameDataModule {
  JsonGameDataModule({
    required super.dataDirectory,
    required super.fileName,
  });

  Map<String, dynamic> data = {};

  @override
  Future<void> load() async {
    if (!await exists()) {
      data = {};
      return;
    }
    final content = await file.readAsString();
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
  }

  @override
  Future<void> save() async {
    final content = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(content);
  }

  @override
  Future<void> initialize() async {
    data = {};
    await save();
  }
}
