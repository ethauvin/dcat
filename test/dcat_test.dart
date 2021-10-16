// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:dcat/dcat.dart';
import 'package:test/test.dart';

import '../bin/dcat.dart' as app;

void main() {
  const sampleBinary = 'test/test.7z';
  const sampleFile = 'test/test.txt';
  const sampleText = 'This is a test';
  const sourceFile = 'bin/dcat.dart';

  int exitCode;
  final tempDir = Directory.systemTemp.createTempSync();

  Stream<List<int>> mockStdin({String text = sampleText}) async* {
    yield text.codeUnits;
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
    test('Test CatResult', () async {
      final result = CatResult();
      expect(result.isSuccess, true, reason: 'success by default');
      result.addMessage(exitFailure, sampleText);
      expect(result.isFailure, true, reason: 'is failure');
      expect(result.messages.first, equals(sampleText), reason: 'message is sample');
    });

    test('Test cat source', () async {
      final tmp = tmpFile();
      await cat([sourceFile], tmp.openWrite());
      final lines = await tmp.readAsLines();
      expect(lines.isEmpty, false, reason: 'log is empty');
      expect(lines.first, startsWith('// Copyright (c)'),
          reason: 'has copyright');
      expect(lines.last, equals('}'));
    });

    test('Test cat -n source', () async {
      final tmp = tmpFile();
      final result =
          await cat([sourceFile], tmp.openWrite(), showLineNumbers: true);
      expect(result.exitCode, 0, reason: 'result code is 0');
      final lines = await tmp.readAsLines();
      expect(lines.first, startsWith('     1\t// Copyright (c)'),
          reason: 'has copyright');
      expect(lines.last, endsWith('\t}'), reason: 'last line');
      for (final line in lines) {
        expect(line, matches('^ +\\d+\t.*'), reason: 'has line number');
      }
    });

    test('Test cat source test', () async {
      final tmp = tmpFile();
      await cat([sourceFile, sampleFile], tmp.openWrite());
      final lines = await tmp.readAsLines();
      expect(lines.length, greaterThan(10), reason: 'more than 10 lines');
      expect(lines.first, startsWith('// Copyright'),
          reason: 'start with copyright');
      expect(lines.last, endsWith('✓'), reason: 'end with checkmark');
    });

    test('Test cat -E', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(), showEnds: true);
      var hasBlank = false;
      final lines = await tmp.readAsLines();
      for (var i = 0; i < lines.length - 1; i++) {
        expect(lines[i], endsWith('\$'));
        if (lines[i] == '\$') {
          hasBlank = true;
        }
      }
      expect(hasBlank, true, reason: 'has blank line');
      expect(lines.last, endsWith('✓'), reason: 'has unicode');
    });

    test('Test cat -bE', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(),
          numberNonBlank: true, showEnds: true);
      final lines = await tmp.readAsLines();
      for (var i = 0; i < lines.length - 1; i++) {
        expect(lines[i], endsWith('\$'), reason: '${lines[i]} ends with \$');
        if (lines[i] != '\$') {
          expect(lines[i], contains(RegExp(r'^ +\d+\t.*\$$')),
              reason: '${lines[i]} is valid');
        }
      }
    });

    test('Test cat -T', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(), showTabs: true);
      var hasTab = false;
      final lines = await tmp.readAsLines();
      for (final String line in lines) {
        if (line.startsWith('^I')) {
          hasTab = true;
          break;
        }
      }
      expect(hasTab, true, reason: 'has tab');
    });

    test('Test cat -s', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(), squeezeBlank: true);
      var hasSqueeze = true;
      var prevLine = 'foo';
      final lines = await tmp.readAsLines();
      for (final String line in lines) {
        if (line == prevLine) {
          hasSqueeze = false;
        }
        prevLine = line;
      }
      expect(hasSqueeze, true, reason: 'has squeeze');
    });

    test('Test cat -A', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true, showEnds: true, showTabs: true);
      final lines = await tmp.readAsLines();
      expect(lines.first, endsWith('\$'), reason: '\$ at end.');
      expect(lines.last, equals('^I^A^B^C^DU+00A9^?U+0080U+2713'),
          reason: "no last linefeed");
    });

    test('Test cat -t', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true, showTabs: true);
      final lines = await tmp.readAsLines();
      expect(lines.last, equals('^I^A^B^C^DU+00A9^?U+0080U+2713'));
    });

    test('Test cat -Abs', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true,
          showEnds: true,
          showTabs: true,
          numberNonBlank: true,
          squeezeBlank: true);
      var blankLines = 0;
      final lines = await tmp.readAsLines();
      for (final String line in lines) {
        if (line == '\$') {
          blankLines++;
        }
      }
      expect(blankLines, 2, reason: 'only 2 blank lines.');
    });

    test('Test cat -v', () async {
      final tmp = tmpFile();
      await cat([sampleFile], tmp.openWrite(), showNonPrinting: true);
      var hasTab = false;
      final lines = await tmp.readAsLines();
      for (final String line in lines) {
        if (line.contains('\t')) {
          hasTab = true;
          break;
        }
      }
      expect(hasTab, true, reason: "has real tab");
      expect(lines.last, equals('\t^A^B^C^DU+00A9^?U+0080U+2713'),
          reason: 'non-printing');
    });

    test('Test cat to file', () async {
      final tmp = tmpFile();
      final result = await cat([sampleFile], tmp.openWrite());
      expect(result.isSuccess, true, reason: 'result code is success');
      expect(result.messages.length, 0, reason: 'messages is empty');
      expect(await tmp.exists(), true, reason: 'tmp file exists');
      expect(await tmp.length(), greaterThan(0),
          reason: 'tmp file is not empty');
      var lines = await tmp.readAsLines();
      expect(lines.first, startsWith('Lorem'), reason: 'Lorem in first line');
      expect(lines.last, endsWith('✓'), reason: 'end with checkmark');
    });

    test('Test cat with file and binary', () async {
      final result = await cat([sampleFile, sampleBinary], stdout);
      expect(result.isFailure, true, reason: 'result code is failure');
      expect(result.messages.length, 1, reason: 'as one message');
      expect(result.messages.first, contains('Binary'),
          reason: 'message contains binary');
    });

    test('Test empty stdin', () async {
      final tmp = tmpFile();
      var result = await cat([], tmp.openWrite(), input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat() is successful');
      expect(result.messages.length, 0, reason: 'cat() has no message');

      result = await cat(['-'], tmp.openWrite(), input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat(-) is successful');
      expect(result.messages.length, 0, reason: 'cat(-) no message');
    });

    test('Test cat -', () async {
      var tmp = tmpFile();
      final result = await cat(['-'], tmp.openWrite(), input: mockStdin());
      expect(result.exitCode, exitSuccess, reason: 'result code is successful');
      expect(result.messages.length, 0, reason: 'no message');
      tmp = tmpFile();
      expect(await tmp.exists(), false, reason: 'tmp file does not exists');
    });

    test('Test cat()', () async {
      var tmp = tmpFile();
      await cat([], tmp.openWrite(), input: mockStdin());
      var lines = await tmp.readAsLines();
      expect(lines.first, equals(sampleText), reason: 'cat() is sample text');
      tmp = tmpFile();
      await cat([], tmp.openWrite(), input: mockStdin(text: "Line 1\nLine 2"));
      lines = await tmp.readAsLines();
      expect(lines.length, 2, reason: "two lines");
    });
  });
}
