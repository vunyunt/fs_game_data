import 'dart:io';

void main(List<String> args) async {
  String? modelPackage;
  String? scanDir;
  String? output;

  for (final arg in args) {
    if (arg.startsWith('--model-package=')) {
      modelPackage = arg.substring('--model-package='.length);
    } else if (arg.startsWith('--scan-dir=')) {
      scanDir = arg.substring('--scan-dir='.length);
    } else if (arg.startsWith('--output=')) {
      output = arg.substring('--output='.length);
    }
  }

  if (modelPackage == null || scanDir == null || output == null) {
    print('Usage: dart run fs_game_data:generate_type_registry '
        '--model-package=<package_name> '
        '--scan-dir=<directory_path> '
        '--output=<output_file_path>');
    exit(1);
  }

  final scanDirectory = Directory(scanDir);
  if (!scanDirectory.existsSync()) {
    print('Could not find directory: $scanDir');
    exit(1);
  }

  final mappingEntries = <_Mapping>[];
  final regex = RegExp(r'//\s*@binpb_type_map:\s*(.+)\s*->\s*(.+)');

  final entities = scanDirectory.listSync(recursive: true);
  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.prototypemap.dart')) {
      final lines = entity.readAsLinesSync();
      for (final line in lines) {
        final match = regex.firstMatch(line);
        if (match != null) {
          final pattern = match.group(1)!.trim();
          final typeName = match.group(2)!.trim();
          mappingEntries.add(_Mapping(pattern, typeName));
        }
      }
    }
  }

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Run `dart run fs_game_data:generate_type_registry` to update');
  buffer.writeln();
  buffer.writeln("import 'package:protobuf/protobuf.dart';");
  buffer.writeln("import 'package:$modelPackage/$modelPackage.dart';");
  buffer.writeln("import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';");
  buffer.writeln();
  buffer.writeln('class TypeMappingRule {');
  buffer.writeln('  final RegExp pattern;');
  buffer.writeln('  final GeneratedMessage Function() factory;');
  buffer.writeln();
  buffer.writeln('  TypeMappingRule(String patternString, this.factory)');
  buffer.writeln('      : pattern = RegExp(patternString);');
  buffer.writeln();
  buffer.writeln('  bool matches(String relativePath) => pattern.hasMatch(relativePath);');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('class GameDataTypeRegistry {');
  buffer.writeln('  static final List<TypeMappingRule> _rules = [');

  for (final entry in mappingEntries) {
    final escapedPattern = entry.pattern
        .replaceAll(r'\', r'\\')
        .replaceAll(r'$', r'\$')
        .replaceAll("'", r"\'");
    buffer.writeln("    TypeMappingRule('$escapedPattern', () => ${entry.typeName}()),");
  }

  buffer.writeln('  ];');
  buffer.writeln();
  buffer.writeln('  static GeneratedMessage? getMessageTypeForPath(String relativePath) {');
  buffer.writeln("    final normalizedPath = relativePath.replaceAll('\\\\', '/');");
  buffer.writeln('    for (final rule in _rules) {');
  buffer.writeln('      if (rule.matches(normalizedPath)) {');
  buffer.writeln('        return rule.factory();');
  buffer.writeln('      }');
  buffer.writeln('    }');
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln('}');

  final outputFile = File(output);
  final parentDir = outputFile.parent;
  if (!parentDir.existsSync()) {
    parentDir.createSync(recursive: true);
  }
  outputFile.writeAsStringSync(buffer.toString());

  print('Generated ${mappingEntries.length} type map rules in $output.');
}

class _Mapping {
  final String pattern;
  final String typeName;
  _Mapping(this.pattern, this.typeName);
}
