// Copyright (c) 2021-2021, Erik C. Thauvin. All rights reserved.
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
  final tmpDir = Directory.systemTemp.createTempSync();

  Stream<List<int>> mockStdin({String text = sampleText}) async* {
    yield text.codeUnits;
  }

  File makeTmpFile() =>
      File("${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}.txt");

  tearDownAll(() => tmpDir.delete(recursive: true));

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

    test('missing file', () async {
      exitCode = await app.main(['foo']);
      expect(exitCode, exitFailure, reason: 'foo should not be found');
      exitCode = await app.main([sourceFile, 'foo']);
      expect(exitCode, exitFailure, reason: 'source file should be missing');
    });

    test('no directories', () async {
      exitCode = await app.main(['bin']);
      expect(exitCode, exitFailure);
    });
  });

  group('lib', () {
    test('CatResult defaults', () async {
      final result = CatResult();
      expect(result.isSuccess, true, reason: 'should be success by default');
      expect(result.errors.isEmpty, true, reason: 'should be empty by default');
      result.addError(sampleText);
      expect(result.isFailure, true, reason: 'was not failure');
      expect(result.errors.first.message, equals(sampleText),
          reason: 'message was not sample');
      final path = 'foo/bar';
      result.addError(path, path: path);
      expect(result.errors.last.message, equals(path),
          reason: 'message was not foo');
      expect(result.errors.last.path, equals(path), reason: 'path was not foo');
    });

    test('cat -', () async {
      final tmp = makeTmpFile();
      final result = await cat(['-'], tmp.openWrite(), input: mockStdin());
      expect(result.exitCode, exitSuccess,
          reason: 'result code was not success');
      expect(result.errors.length, 0, reason: 'should have no error');
      final lines = await tmp.readAsLines();
      expect(lines.first, equals(sampleText),
          reason: 'first line was not sample text');
    });

    test('cat -A', () async {
      final tmp = makeTmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true, showEnds: true, showTabs: true);
      final lines = await tmp.readAsLines();
      expect(lines.first, endsWith('\$'), reason: 'should end with \$');
      expect(lines.last, equals('^I^A^B^C^DM-BM-)^?M-BM-^@M-bM-^\\M-^S'),
          reason: "missing linefeed");
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
      expect(blankLines, 2, reason: 'should only have 2 blank lines.');
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
      expect(hasBlank, true, reason: 'should have blank line');
      expect(lines.last, endsWith('✓'), reason: 'missing ending checkmark');
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
      expect(hasTab, true, reason: 'should have tab');
    });

    test('cat -bE', () async {
      final tmp = makeTmpFile();
      await cat([sampleFile], tmp.openWrite(),
          numberNonBlank: true, showEnds: true);
      final lines = await tmp.readAsLines();
      for (var i = 0; i < lines.length - 1; i++) {
        expect(lines[i], endsWith('\$'),
            reason: '${lines[i]} should end with \$');
        if (lines[i] != '\$') {
          expect(lines[i], contains(RegExp(r'^ +\d+\t.*\$$')),
              reason: '${lines[i]} was invalid');
        }
      }
    });

    test('cat -n source', () async {
      final tmp = makeTmpFile();
      final result =
          await cat([sourceFile], tmp.openWrite(), showLineNumbers: true);
      expect(result.exitCode, 0, reason: 'result code was not 0');
      final lines = await tmp.readAsLines();
      expect(lines.first, startsWith('     1\t// Copyright (c)'),
          reason: 'copyright was missing');
      expect(lines.last, endsWith('\t}'),
          reason: 'last line should end with tab');
      for (final line in lines) {
        expect(line, matches('^ +\\d+\t.*'), reason: 'missing line number');
      }
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
      expect(hasSqueeze, true, reason: 'was not squeezed');
    });

    test('cat -t', () async {
      final tmp = makeTmpFile();
      await cat([sampleFile], tmp.openWrite(),
          showNonPrinting: true, showTabs: true);
      final lines = await tmp.readAsLines();
      expect(lines.last, equals('^I^A^B^C^DM-BM-)^?M-BM-^@M-bM-^\\M-^S'));
    });

    test('cat -v binary, file', () async {
      final tmp = makeTmpFile();
      await cat([sampleBinary, sampleFile], tmp.openWrite(),
          showNonPrinting: true);
      final lines = await tmp.readAsLines();
      expect(lines.first, startsWith('7z'));
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
      expect(hasTab, true, reason: "should have tab");
      expect(lines.last, equals('\t^A^B^C^DM-BM-)^?M-BM-^@M-bM-^\\M-^S'),
          reason: 'invalid non-printing');
    });

    test('cat > file', () async {
      final tmp = makeTmpFile();
      final result = await cat([sampleFile], tmp.openWrite());
      expect(result.isSuccess, true, reason: 'result code was not success');
      expect(result.errors.length, 0, reason: 'should have no error');
      expect(await tmp.exists(), true, reason: 'tmp file missing');
      expect(await tmp.length(), greaterThan(0),
          reason: 'tmp file should not be empty');
      final lines = await tmp.readAsLines();
      expect(lines.first, startsWith('Lorem'),
          reason: 'first line should start with Lorem');
      expect(lines.last, endsWith('✓'), reason: 'missing ending checkmark');
    });

    test('cat < file', () async {
      final tmp = makeTmpFile();
      final result =
          await cat([], tmp.openWrite(), input: File(sampleFile).openRead());
      expect(result.isSuccess, true, reason: 'result was not success');
      final lines = await tmp.readAsLines();
      expect(lines.first, startsWith('Lorem'),
          reason: 'first line should start with Lorem');
      expect(lines.last, endsWith('✓'), reason: 'missing ending checkmark');
    });

    test('cat binary', () async {
      final tmp = makeTmpFile();
      await cat([sampleBinary], tmp.openWrite());
      expect(tmp.readAsLines(), throwsException);
    });

    test('cat file -', () async {
      var tmp = makeTmpFile();
      await cat([sampleFile, '-'], tmp.openWrite(),
          input: mockStdin(text: '\n$sampleText'));
      var lines = await tmp.readAsLines();
      expect(lines.last, equals(sampleText));
    });

    test('cat file - source', () async {
      final tmp = makeTmpFile();
      final result = await cat([sampleFile, '-'], tmp.openWrite(),
          input: File(sourceFile).openRead());
      expect(result.isSuccess, true, reason: 'result was not success');
      final lines = await tmp.readAsLines();
      expect(lines.first, startsWith('Lorem'),
          reason: 'first line should start with Lorem');
      expect(lines.last.endsWith('✓'), false,
          reason: "missing ending checkmark");
    });

    test('cat source', () async {
      final tmp = makeTmpFile();
      await cat([sourceFile], tmp.openWrite());
      final lines = await tmp.readAsLines();
      expect(lines.isEmpty, false, reason: 'log was not empty');
      expect(lines.first, startsWith('// Copyright (c)'),
          reason: 'missing copyright');
      expect(lines.last, equals('}'));
    });

    test('cat source, test', () async {
      final tmp = makeTmpFile();
      await cat([sourceFile, sampleFile], tmp.openWrite());
      final lines = await tmp.readAsLines();
      expect(lines.length, greaterThan(10),
          reason: 'should be more than 10 lines');
      expect(lines.first, startsWith('// Copyright'),
          reason: 'missing copyright');
      expect(lines.last, endsWith('✓'), reason: 'missing ending checkmark');
    });

    test('cat()', () async {
      var tmp = makeTmpFile();
      await cat([], tmp.openWrite(), input: mockStdin());
      var lines = await tmp.readAsLines();
      expect(lines.first, equals(sampleText),
          reason: 'cat() was not sample text');
      tmp = makeTmpFile();
      await cat([], tmp.openWrite(), input: mockStdin(text: "Line 1\nLine 2"));
      lines = await tmp.readAsLines();
      expect(lines.length, 2, reason: "tmp file should only be 2 lines");
    });

    test('stdin empty', () async {
      final tmp = makeTmpFile();
      var result = await cat([], tmp.openWrite(), input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat() was not successful');
      expect(result.errors.length, 0, reason: 'cat() has errors');
      result = await cat(['-'], tmp.openWrite(), input: Stream.empty());
      expect(result.exitCode, exitSuccess, reason: 'cat(-) was not successful');
      expect(result.errors.length, 0, reason: 'cat(-) has errors');
    });

    test('stdin error', () async {
      final result =
          await cat([], stdout, input: Stream.error(Exception(sampleText)));
      expect(result.isFailure, true, reason: 'cat() was not failure');
      expect(result.errors.first.message, contains(sampleText),
          reason: 'error was not sample');
    });

    test('stdin filesystem error', () async {
      final result = await cat([], stdout,
          input: Stream.error(FileSystemException(sampleText)));
      expect(result.isFailure, true, reason: 'cat() was not failure');
      expect(result.errors.first.message, contains(sampleText),
          reason: 'error was not sample');
    });

    test('stdin invalid', () async {
      final tmp = makeTmpFile();
      final result = await cat([], tmp.openWrite(), input: null);
      expect(result.exitCode, exitSuccess);
    });

    test('stdout closed', () async {
      final tmp = makeTmpFile();
      final stream = tmp.openWrite();
      stream.close();
      final result = await cat([sampleFile], stream);
      expect(result.errors.first.message, contains("closed"),
          reason: 'stream was not closed');
    });
  });
}
