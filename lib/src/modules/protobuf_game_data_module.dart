import 'package:protobuf/protobuf.dart';
import '../game_data_module.dart';

abstract class ProtobufGameDataModule<T extends GeneratedMessage>
    extends GameDataModule {
  final T Function() createEmptyMessage;
  late T proto;

  ProtobufGameDataModule({
    required super.dataDirectory,
    required super.fileName,
    required this.createEmptyMessage,
  }) {
    proto = createEmptyMessage();
  }

  @override
  Future<void> load() async {
    if (!await exists()) {
      proto = createEmptyMessage();
      return;
    }
    final bytes = await file.readAsBytes();
    proto = createEmptyMessage()..mergeFromBuffer(bytes);
  }

  @override
  Future<void> save() async {
    await file.writeAsBytes(proto.writeToBuffer());
  }

  @override
  Future<void> initialize() async {
    proto = createEmptyMessage();
    await save();
  }
}
