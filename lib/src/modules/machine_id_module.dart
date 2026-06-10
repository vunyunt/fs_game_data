import 'dart:convert';
import 'dart:io';
import 'json_game_data_module.dart';

class MachineIdModule extends JsonGameDataModule {
  bool _mismatchDetected = false;

  MachineIdModule({required super.dataDirectory})
    : super(fileName: 'machine_info.json');

  int get machineId => data['machineId'] as int? ?? 0;
  set machineId(int value) => data['machineId'] = value;

  String? get machineHash => data['machineHash'] as String?;
  set machineHash(String? value) => data['machineHash'] = value;

  bool get mismatchDetected => _mismatchDetected;

  @override
  Future<void> load() async {
    await super.load();
    if (data.isNotEmpty) {
      final currentHash = _calculateMachineHash();
      if (machineHash != currentHash) {
        _mismatchDetected = true;
      }
    }
  }

  @override
  Future<void> save() async {
    data['machineHash'] = _calculateMachineHash();
    await super.save();
    _mismatchDetected = false;
  }

  @override
  Future<void> initialize() async {
    data = {'machineId': 1};
    await save();
  }

  String _calculateMachineHash() {
    final components = [
      Platform.localHostname,
      Platform.operatingSystem,
      Platform.operatingSystemVersion,
      Platform.numberOfProcessors.toString(),
    ];
    return base64Encode(utf8.encode(components.join('|')));
  }

  Future<void> updateMachineId(int newId) async {
    machineId = newId;
    await save();
  }
}
