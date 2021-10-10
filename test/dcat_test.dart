import 'package:test/test.dart';

import '../bin/dcat.dart' as dcat;

void main() {
  final List<String> log = [];
  int exitCode;

  test('Test Help', () async {
    expect(dcat.main(['-h']), completion(equals(0)));
    expect(dcat.main(['--help']), completion(equals(0)));
    exitCode = await dcat.main(['-h']);
    expect(exitCode, equals(dcat.exitSuccess));
  });

  test('Test --version', () async {
    expect(dcat.main(['--version']), completion(equals(0)));
    exitCode = await dcat.main(['--version']);
    expect(exitCode, equals(dcat.exitSuccess));
  });

  test('Test directory', () async {
    exitCode = await dcat.main(['bin']);
    expect(exitCode, equals(dcat.exitFailure));
  });

  test('Test missing file', () async {
    exitCode = await dcat.main(['foo']);
    expect(exitCode, equals(dcat.exitFailure), reason: 'foo not found');
    exitCode = await dcat.main(['bin/dcat.dart', 'foo']);
    expect(exitCode, equals(dcat.exitFailure), reason: 'one missing file');
  });

  test('Test cat source', () async {
    await dcat.cat(['bin/dcat.dart'], log: log);
    expect(log.isEmpty, false, reason: 'log is empty');
    expect(log.first, startsWith('// Copyright (c)'), reason: 'has copyright');
    expect(log.last, equals('}'));
  });

  test('Test cat -n source', () async {
    exitCode =
        await dcat.cat(['bin/dcat.dart'], log: log, showLineNumbers: true);
    expect(exitCode, 0, reason: 'result code is 0');
    expect(log.first, startsWith('1: // Copyright (c)'),
        reason: 'has copyright');
    expect(log.last, endsWith(': }'), reason: 'last line');
    for (final String line in log) {
      expect(line, matches('^\\d+: .*'), reason: 'has line number');
    }
  });

  test('Test cat -E', () async {
    await dcat.cat(['test/test.txt'], log: log, showEnds: true);
    var hasBlank = false;
    for (final String line in log) {
      expect(line, endsWith('\$'));
      if (line == '\$') {
        hasBlank = true;
      }
    }
    expect(hasBlank, true, reason: 'has blank line');
  });

  test('Test cat -bE', () async {
    await dcat
        .cat(['test/test.txt'], log: log, numberNonBlank: true, showEnds: true);
    var hasBlank = false;
    for (final String line in log) {
      expect(line, endsWith('\$'));
      if (line.contains(RegExp(r'^\d+: .*\$$'))) {
        hasBlank = true;
      }
    }
    expect(hasBlank, true, reason: 'has blank line');
  });

  test('Test cat -T', () async {
    await dcat.cat(['test/test.txt'], log: log, showTabs: true);
    var hasTab = false;
    for (final String line in log) {
      if (line.startsWith('^I')) {
        hasTab = true;
        break;
      }
    }
    expect(hasTab, true, reason: 'has tab');
  });

  test('Test cat -s', () async {
    await dcat.cat(['test/test.txt'], log: log, squeezeBlank: true);
    var hasSqueeze = true;
    var prevLine = 'foo';
    for (final String line in log) {
      if (line == prevLine) {
        hasSqueeze = false;
      }
      prevLine = line;
    }
    expect(hasSqueeze, true, reason: 'has squeeze');
  });
}
