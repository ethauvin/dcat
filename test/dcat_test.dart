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

  File makeTmpFile() =>
      File("${tempDir.path}/tmp-${DateTime.now().millisecondsSinceEpoch}.txt");

  tearDownAll(() => tempDir.delete(recursive: true));

  group('app', () {
    test('--help', () async {
      expect(app.main(['-h']), completion(0));
      expect(app.main(['--help']), completion(0));
      exitCode = await app.main(['-h']);
      expect(exitCode, exitSuccess);
    });

    test('--version', () async {
      expect(app.main(['--version']), completion(0));
      exitCode = await app.main(['--version']);
      expect(exitCode, exitSuccess);
    });

    test('invalid option', () async {
      expect(app.main(['-a']), completion(1));
      exitCode = await app.main(['-a']);
      expect(exitCode, exitFailure);
    });

    test('no directories', () async {
      exitCode = await app.main(['bin']);
      expect(exitCode, exitFailure);
    });

    test('missing file', () async {
      exitCode = await app.main(['foo']);
      expect(exitCode, exitFailure, reason: 'foo not found');
      exitCode = await app.main([sourceFile, 'foo']);
      expect(exitCode, exitFailure, reason: 'one missing file');
    });
  });

  group('lib', () {
    test('CatResult defaults', () async {
      final result = CatResult();
      expect(result.isSuccess, true, reason: 'success by default');
      result.addMessage(exitFailure, sampleText);
      expect(result.isFailure, true, reason: 'is failure');
      expect(result.messages.first, equals(sampleText),
          reason: 'message is sample');
    });

    test('cat source', () async {
      final tmp = makeTmpFile();
      await cat([sourceFile], tmp.openWrite());
      final lines = await tmp.readAsLines();
      expect(lines.isEmpty, false, reason: 'log is empty');
      expect(lines.first, startsWith('// Copyright (c)'),
          reason: 'has copyright');
      expect(lines.last, equals('}'));
    });

    test('cat -n source', () async {
      final tmp = makeTmpFile();
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

    test('cat source, test', () async {
      final tmp = makeTmpFile();
      await cat([sourceFile, sampleFile], tmp.openWrite());
      final lines = await tmp.readAsLines();
      expect(lines.length, greaterThan(10), reason: 'more than 10 lines');
      expect(lines.first, startsWith('// Copyright'),
          reason: 'start with copyright');
      expect(lines.last, endsWith('✓'), reason: 'end with checkmark');
    });

    test('cat -E', () async {
      final tmp = makeTmpFile();
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

    test('cat -bE', () async {
      final tmp = makeTmpFile();
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

    test('cat -T', () async {
      final tmp = makeTmpFile();
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

    test('cat -s', () async {
      final tmp = makeTmpFile();
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

    test('cat -A', () async {
      final tmp = makeTmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true, showEnds: true, showTabs: true);
      final lines = await tmp.readAsLines();
      expect(lines.first, endsWith('\$'), reason: '\$ at end.');
      expect(lines.last, equals('^I^A^B^C^DM-BM-)^?M-BM-^@M-bM-^\\M-^S'),
          reason: "no last linefeed");
    });

    test('cat -t', () async {
      final tmp = makeTmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true, showTabs: true);
      final lines = await tmp.readAsLines();
      expect(lines.last, equals('^I^A^B^C^DM-BM-)^?M-BM-^@M-bM-^\\M-^S'));
    });

    test('cat -Abs', () async {
      final tmp = makeTmpFile();
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

    test('cat -v', () async {
      final tmp = makeTmpFile();
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
      expect(lines.last, equals('\t^A^B^C^DM-BM-)^?M-BM-^@M-bM-^\\M-^S'),
          reason: 'non-printing');
    });

    test('cat > file', () async {
      final tmp = makeTmpFile();
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

    test('cat -v binary, file', () async {
      final tmp = makeTmpFile();
      await cat([sampleBinary, sampleFile], tmp.openWrite(),
          showNonPrinting: true);
      var lines = await tmp.readAsLines();
      expect(lines.first, startsWith('7z'));
    });

    test('cat binary', () async {
      final tmp = makeTmpFile();
      await cat([sampleBinary], tmp.openWrite());
      expect(tmp.readAsLines(), throwsException);
    });

    test('empty stdin', () async {
      final tmp = makeTmpFile();
      var result = await cat([], tmp.openWrite(), input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat() is successful');
      expect(result.messages.length, 0, reason: 'cat() has no message');

      result = await cat(['-'], tmp.openWrite(), input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat(-) is successful');
      expect(result.messages.length, 0, reason: 'cat(-) no message');
    });

    test('cat -', () async {
      var tmp = makeTmpFile();
      final result = await cat(['-'], tmp.openWrite(), input: mockStdin());
      expect(result.exitCode, exitSuccess, reason: 'result code is successful');
      expect(result.messages.length, 0, reason: 'no message');
      tmp = makeTmpFile();
      expect(await tmp.exists(), false, reason: 'tmp file does not exists');
    });

    test('cat()', () async {
      var tmp = makeTmpFile();
      await cat([], tmp.openWrite(), input: mockStdin());
      var lines = await tmp.readAsLines();
      expect(lines.first, equals(sampleText), reason: 'cat() is sample text');
      tmp = makeTmpFile();
      await cat([], tmp.openWrite(), input: mockStdin(text: "Line 1\nLine 2"));
      lines = await tmp.readAsLines();
      expect(lines.length, 2, reason: "two lines");
    });

    test('cat file -', () async {
      var tmp = makeTmpFile();
      await cat([sampleFile, '-'], tmp.openWrite(),
          input: mockStdin(text: '\n$sampleText'));
      var lines = await tmp.readAsLines();
      expect(lines.last, equals(sampleText));
    });

    test('closed stdout', () async {
      final tmp = makeTmpFile();
      final stream = tmp.openWrite();
      stream.close();
      final result = await cat([sampleFile], stream);
      expect(result.messages.first, contains("closed"));
    });
  });
}
