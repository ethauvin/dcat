// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'package:dcat/dcat.dart';
import 'package:test/test.dart';

import '../bin/dcat.dart' as app;

void main() {
  final List<String> log = [];
  int exitCode;

  group('app', () {
    test('Test Help', () async {
      expect(app.main(['-h']), completion(equals(0)));
      expect(app.main(['--help']), completion(equals(0)));
      exitCode = await app.main(['-h']);
      expect(exitCode, equals(exitSuccess));
    });

    test('Test --version', () async {
      expect(app.main(['--version']), completion(equals(0)));
      exitCode = await app.main(['--version']);
      expect(exitCode, equals(exitSuccess));
    });

    test('Test -a', () async {
      expect(app.main(['-a']), completion(equals(1)));
      exitCode = await app.main(['-a']);
      expect(exitCode, equals(exitFailure));
    });

    test('Test directory', () async {
      exitCode = await app.main(['bin']);
      expect(exitCode, equals(exitFailure));
    });

    test('Test binary', () async {
      exitCode = await app.main(['test/test.7z']);
      expect(exitCode, equals(exitFailure));
    });

    test('Test missing file', () async {
      exitCode = await app.main(['foo']);
      expect(exitCode, equals(exitFailure), reason: 'foo not found');
      exitCode = await app.main(['bin/dcat.dart', 'foo']);
      expect(exitCode, equals(exitFailure), reason: 'one missing file');
    });
  });

  group('lib', () {
    test('Test cat source', () async {
      await cat(['bin/dcat.dart'], log: log);
      expect(log.isEmpty, false, reason: 'log is empty');
      expect(log.first, startsWith('// Copyright (c)'),
          reason: 'has copyright');
      expect(log.last, equals('}'));
    });

    test('Test cat -n source', () async {
      exitCode = await cat(['bin/dcat.dart'], log: log, showLineNumbers: true);
      expect(exitCode, 0, reason: 'result code is 0');
      expect(log.first, startsWith('     1  // Copyright (c)'),
          reason: 'has copyright');
      expect(log.last, endsWith('  }'), reason: 'last line');
      for (final String line in log) {
        expect(line, matches('^ +\\d+  .*'), reason: 'has line number');
      }
    });

    test('Test cat source test', () async {
      await cat(['bin/dcat.dart', 'test/test.txt'], log: log);
      expect(log.length, greaterThan(10), reason: 'more than 10 lines');
      expect(log.first, startsWith('// Copyright'),
          reason: 'start with copyright');
      expect(log.last, endsWith('✓'), reason: 'end with checkmark');
    });

    test('Test cat -E', () async {
      await cat(['test/test.txt'], log: log, showEnds: true);
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
      await cat(['test/test.txt'],
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
      await cat(['test/test.txt'], log: log, showTabs: true);
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
      await cat(['test/test.txt'], log: log, squeezeBlank: true);
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
      await cat(['test/test.txt'],
          log: log, showNonPrinting: true, showEnds: true, showTabs: true);
      expect(log.last, equals('^I^A^B^C^DU+00A9^?U+0080U+2713\$'));
    });

    test('Test cat -t', () async {
      await cat(['test/test.txt'],
          log: log, showNonPrinting: true, showTabs: true);
      expect(log.last, equals('^I^A^B^C^DU+00A9^?U+0080U+2713'));
    });

    test('Test cat-Abs', () async {
      await cat(['test/test.txt'],
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
      await cat(['test/test.txt'], log: log, showNonPrinting: true);
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
  });
}
