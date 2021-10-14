// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:dcat/dcat.dart';
import 'package:test/test.dart';

import '../bin/dcat.dart' as app;

void main() {
  int exitCode;
  final List<String> log = [];
  final sampleBinary = 'test/test.7z';
  final sampleFile = 'test/test.txt';
  final sampleText = 'This is a test';
  final sourceFile = 'bin/dcat.dart';
  final tempDir = Directory.systemTemp.createTempSync();

  Stream<List<int>> mockStdin() async* {
    yield sampleText.codeUnits;
  }

  File tmpFile() =>
      File("${tempDir.path}/tmp-${DateTime.now().millisecondsSinceEpoch}.txt");

  tearDownAll(() => tempDir.delete(recursive: true));

  group('app', () {
    test('Test Help', () async {
      expect(app.main(['-h']), completion(0));
      expect(app.main(['--help']), completion(0));
      exitCode = await app.main(['-h']);
      expect(exitCode, exitSuccess);
    });

    test('Test --version', () async {
      expect(app.main(['--version']), completion(0));
      exitCode = await app.main(['--version']);
      expect(exitCode, exitSuccess);
    });

    test('Test -a', () async {
      expect(app.main(['-a']), completion(1));
      exitCode = await app.main(['-a']);
      expect(exitCode, exitFailure);
    });

    test('Test directory', () async {
      exitCode = await app.main(['bin']);
      expect(exitCode, exitFailure);
    });

    test('Test binary', () async {
      exitCode = await app.main([sampleBinary]);
      expect(exitCode, exitFailure);
    });

    test('Test missing file', () async {
      exitCode = await app.main(['foo']);
      expect(exitCode, exitFailure, reason: 'foo not found');
      exitCode = await app.main([sourceFile, 'foo']);
      expect(exitCode, exitFailure, reason: 'one missing file');
    });
  });

  group('lib', () {
    test('Test cat source', () async {
      await cat([sourceFile], stdout, log: log);
      expect(log.isEmpty, false, reason: 'log is empty');
      expect(log.first, startsWith('// Copyright (c)'),
          reason: 'has copyright');
      expect(log.last, equals('}'));
    });

    test('Test cat -n source', () async {
      final result =
          await cat([sourceFile], stdout, log: log, showLineNumbers: true);
      expect(result.exitCode, 0, reason: 'result code is 0');
      expect(log.first, startsWith('     1  // Copyright (c)'),
          reason: 'has copyright');
      expect(log.last, endsWith('  }'), reason: 'last line');
      for (final String line in log) {
        expect(line, matches('^ +\\d+  .*'), reason: 'has line number');
      }
    });

    test('Test cat source test', () async {
      await cat([sourceFile, sampleFile], stdout, log: log);
      expect(log.length, greaterThan(10), reason: 'more than 10 lines');
      expect(log.first, startsWith('// Copyright'),
          reason: 'start with copyright');
      expect(log.last, endsWith('✓'), reason: 'end with checkmark');
    });

    test('Test cat -E', () async {
      await cat([sampleFile], stdout, log: log, showEnds: true);
      var hasBlank = false;
      for (final String line in log) {
        expect(line, endsWith('\$'));
        if (line == '\$') {
          hasBlank = true;
        }
      }
      expect(hasBlank, true, reason: 'has blank line');
      expect(log.last, endsWith('✓\$'), reason: 'has unicode');
    });

    test('Test cat -bE', () async {
      await cat([sampleFile], stdout,
          log: log, numberNonBlank: true, showEnds: true);
      var hasBlank = false;
      for (final String line in log) {
        expect(line, endsWith('\$'));
        if (line.contains(RegExp(r'^ +\d+  .*\$$'))) {
          hasBlank = true;
        }
      }
      expect(hasBlank, true, reason: 'has blank line');
    });

    test('Test cat -T', () async {
      await cat([sampleFile], stdout, log: log, showTabs: true);
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
      await cat([sampleFile], stdout, log: log, squeezeBlank: true);
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

    test('Test cat -A', () async {
      await cat([sampleFile], stdout,
          log: log, showNonPrinting: true, showEnds: true, showTabs: true);
      expect(log.last, equals('^I^A^B^C^DU+00A9^?U+0080U+2713\$'));
    });

    test('Test cat -t', () async {
      await cat([sampleFile], stdout,
          log: log, showNonPrinting: true, showTabs: true);
      expect(log.last, equals('^I^A^B^C^DU+00A9^?U+0080U+2713'));
    });

    test('Test cat-Abs', () async {
      await cat([sampleFile], stdout,
          log: log,
          showNonPrinting: true,
          showEnds: true,
          showTabs: true,
          numberNonBlank: true,
          squeezeBlank: true);
      var blankLines = 0;
      for (final String line in log) {
        if (line == '\$') {
          blankLines++;
        }
      }
      expect(blankLines, 2, reason: 'only 2 blank lines.');
    });

    test('Test cat -v', () async {
      await cat([sampleFile], stdout, log: log, showNonPrinting: true);
      var hasTab = false;
      for (final String line in log) {
        if (line.contains('\t')) {
          hasTab = true;
          break;
        }
      }
      expect(hasTab, true, reason: "has real tab");
      expect(log.last, equals('\t^A^B^C^DU+00A9^?U+0080U+2713'),
          reason: 'non-printing');
    });

    test('Test cat to file', () async {
      final tmp = tmpFile();
      final result = await cat([sampleFile], tmp, log: log);
      expect(result.exitCode, exitSuccess, reason: 'result code is success');
      expect(result.messages.length, 0, reason: 'messages is empty');
      expect(await tmp.exists(), true, reason: 'tmp file exists');
      expect(await tmp.length(), greaterThan(0),
          reason: 'tmp file is not empty');
      var lines = await tmp.readAsLines();
      expect(lines.first, startsWith('Lorem'), reason: 'Lorem in first line');
      expect(lines.last, endsWith('✓'), reason: 'end with checkmark');
    });

    test('Test cat with file and binary', () async {
      final tmp = tmpFile();
      final result = await cat([sampleFile, sampleBinary], tmp, log: log);
      expect(result.exitCode, exitFailure, reason: 'result code is failure');
      expect(result.messages.length, 1, reason: 'as one message');
      expect(result.messages.first, contains('Binary'),
          reason: 'message contains binary');
    });

    test('Test empty stdin', () async {
      final tmp = tmpFile();
      var result = await cat([], tmp, input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat() is successful');
      expect(result.messages.length, 0, reason: 'cat() has no message');

      result = await cat(['-'], tmp, input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat(-) is successful');
      expect(result.messages.length, 0, reason: 'cat(-) no message');
    });

    test('Test cat with stdin', () async {
      var tmp = tmpFile();
      var result = await cat(['-'], tmp, input: mockStdin());
      expect(result.exitCode, exitSuccess, reason: 'result code is failure');
      expect(result.messages.length, 0, reason: 'no message');
      var lines = await tmp.readAsLines();
      tmp = tmpFile();
      expect(await tmp.exists(), false, reason: 'tmp file does not exists');
      result = await cat([], tmp, input: mockStdin());
      expect(lines.first, equals(sampleText), reason: 'cat() is sample text');
    });
  });
}
