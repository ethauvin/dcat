// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

/// Library to concatenate file(s) to standard output,
library dcat;

import 'dart:convert';
import 'dart:io';

const exitFailure = 1;
const exitSuccess = 0;

/// Concatenates files in [paths] to [stdout]
///
/// The parameters are similar to the [GNU cat utility](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation).
/// Specify a [log] for debugging or testing purpose.
Future<int> cat(List<String> paths,
    {String appName = '',
    List<String>? log,
    bool showEnds = false,
    bool numberNonBlank = false,
    bool showLineNumbers = false,
    bool showTabs = false,
    bool squeezeBlank = false,
    bool showNonPrinting = false}) async {
  var lineNumber = 1;
  var returnCode = 0;
  log?.clear();
  if (paths.isEmpty) {
    final lines = await _readStdin();
    await _writeLines(lines, lineNumber, log, showEnds, showLineNumbers,
        numberNonBlank, showTabs, squeezeBlank, showNonPrinting);
  } else {
    for (final path in paths) {
      try {
        final Stream<String> lines;
        if (path == '-') {
          lines = await _readStdin();
        } else {
          lines = utf8.decoder
              .bind(File(path).openRead())
              .transform(const LineSplitter());
        }
        lineNumber = await _writeLines(
            lines,
            lineNumber,
            log,
            showEnds,
            showLineNumbers,
            numberNonBlank,
            showTabs,
            squeezeBlank,
            showNonPrinting);
      } on FileSystemException catch (e) {
        final String? osMessage = e.osError?.message;
        final String message;
        if (osMessage != null && osMessage.isNotEmpty) {
          message = osMessage;
        } else {
          message = e.message;
        }
        returnCode = await printError(message, appName: appName, path: path);
      } on FormatException {
        returnCode = await printError('Binary file not supported.',
            appName: appName, path: path);
      } catch (e) {
        returnCode =
            await printError(e.toString(), appName: appName, path: path);
      }
    }
  }
  return returnCode;
}

/// Parses line with non-printing characters.
Future<String> _parseNonPrinting(String line, bool showTabs) async {
  final sb = StringBuffer();
  for (var ch in line.runes) {
    if (ch >= 32) {
      if (ch < 127) {
        sb.writeCharCode(ch);
      } else if (ch == 127) {
        sb.write('^?');
      } else {
        sb.write('M-');
        if (ch >= 128 + 32) {
          if (ch < 128 + 127) {
            sb.writeCharCode(ch - 128);
          } else {
            sb.write('^?');
          }
        } else {
          sb
            ..write('^')
            ..writeCharCode(ch - 128 + 64);
        }
      }
    } else if (ch == 9 && !showTabs) {
      sb.write('\t');
    } else {
      sb
        ..write('^')
        ..writeCharCode(ch + 64);
    }
  }
  return sb.toString();
}

/// Prints the [appName], [path] and error [message] to [stderr].
Future<int> printError(String message,
    {String appName = '', String path = ''}) async {
  if (appName.isNotEmpty) {
    stderr.write('$appName: ');
  }
  if (path.isNotEmpty) {
    stderr.write('$path: ');
  }
  stderr.writeln(message);
  return exitFailure;
}

/// Reads from stdin.
Future<Stream<String>> _readStdin() async =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());

/// Writes lines to stdout.
Future<int> _writeLines(Stream<String> lines, int lineNumber,
    [List<String>? log,
    bool showEnds = false,
    bool showLineNumbers = false,
    bool showNonBlank = false,
    bool showTabs = false,
    bool squeezeBlank = false,
    bool showNonPrinting = false]) async {
  var emptyLine = 0;
  final sb = StringBuffer();
  await for (final line in lines) {
    sb.clear();
    if (squeezeBlank && line.isEmpty) {
      if (++emptyLine >= 2) {
        continue;
      }
    } else {
      emptyLine = 0;
    }
    if (showLineNumbers || (showNonBlank && line.isNotEmpty)) {
      sb.write('${lineNumber++}  '.padLeft(8));
    }

    if (showNonPrinting) {
      sb.write(await _parseNonPrinting(line, showTabs));
    } else if (showTabs) {
      sb.write(line.replaceAll('\t', '^I'));
    } else {
      sb.write(line);
    }

    if (showEnds) {
      sb.write('\$');
    }

    log?.add(sb.toString());
    stdout.writeln(sb);
  }
  return lineNumber;
}
