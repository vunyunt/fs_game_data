import 'package:fixnum/fixnum.dart';

/// A Snowflake-like ID generator.
///
/// Bits distribution:
/// - 1 bit: 0 (reserved to ensure positive signed 64-bit integers)
/// - 41 bits: Timestamp (milliseconds since epoch)
/// - 10 bits: Machine ID (0-1023)
/// - 12 bits: Sequence (0-4095)
class Snowflake {
  final int epoch;
  final int machineId;

  int _lastTimestamp = -1;
  int _sequence = 0;

  Snowflake({required this.epoch, required this.machineId}) {
    if (machineId < 0 || machineId > 1023) {
      throw ArgumentError('Machine ID must be between 0 and 1023');
    }
  }

  /// Generates a new unique ID.
  Int64 nextId() {
    var timestamp = DateTime.now().millisecondsSinceEpoch - epoch;

    if (timestamp < _lastTimestamp) {
      throw StateError(
        'Clock moved backwards. Refusing to generate ID for ${_lastTimestamp - timestamp}ms',
      );
    }

    if (timestamp == _lastTimestamp) {
      _sequence = (_sequence + 1) & 4095;
      if (_sequence == 0) {
        // Sequence exhausted, wait for next millisecond
        timestamp = _waitUntilNextMillis(_lastTimestamp);
      }
    } else {
      _sequence = 0;
    }

    _lastTimestamp = timestamp;

    // ID = (timestamp << 22) | (machineId << 12) | sequence
    final id =
        (Int64(timestamp) << 22) | (Int64(machineId) << 12) | Int64(_sequence);
    return id;
  }

  int _waitUntilNextMillis(int lastTimestamp) {
    var timestamp = DateTime.now().millisecondsSinceEpoch - epoch;
    while (timestamp <= lastTimestamp) {
      timestamp = DateTime.now().millisecondsSinceEpoch - epoch;
    }
    return timestamp;
  }

  /// Deconstructs a Snowflake ID into its components.
  static Map<String, dynamic> deconstruct(Int64 id, int epoch) {
    final timestamp = (id >> 22).toInt();
    final machineId = ((id >> 12) & 1023).toInt();
    final sequence = (id & 4095).toInt();

    return {
      'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp + epoch),
      'machineId': machineId,
      'sequence': sequence,
    };
  }
}
