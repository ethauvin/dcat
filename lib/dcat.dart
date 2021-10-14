// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

/// A library to concatenate files to standard output or file.
library dcat;

import 'dart:convert';
import 'dart:io';

const exitFailure = 1;
const exitSuccess = 0;

/// Holds the [cat] result [exitCode] and error [messages].
class CatResult {
  /// The exit code.
  int exitCode = exitSuccess;
  /// The error messages.
  final List<String> messages = [];

  CatResult();

  /// Add a message.
  void addMessage(int exitCode, String message, {String? path}) {
    this.exitCode = exitCode;
    if (path != null && path.isNotEmpty) {
      messages.add('$path: $message');
    } else {
      messages.add(message);
    }
  }
}

/// Concatenates files in [paths] to [stdout] or [File].
///
///  * [output] should be an [IOSink] like [stdout] or a [File].
///  * [input] can be [stdin].
///  * [log] is used for debugging/testing purposes.
///
/// The remaining optional parameters are similar to the [GNU cat utility](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation).
Future<CatResult> cat(List<String> paths, Object output,
    {Stream<List<int>>? input,
    List<String>? log,
    bool showEnds = false,
    bool numberNonBlank = false,
    bool showLineNumbers = false,
    bool showTabs = false,
    bool squeezeBlank = false,
    bool showNonPrinting = false}) async {
  var result = CatResult();
  var lineNumber = 1;
  log?.clear();
  if (paths.isEmpty) {
    if (input != null) {
      final lines = await _readStream(input);
      try {
        await _writeLines(
            lines,
            lineNumber,
            output,
            log,
            showEnds,
            showLineNumbers,
            numberNonBlank,
            showTabs,
            squeezeBlank,
            showNonPrinting);
      } catch (e) {
        result.addMessage(exitFailure, '$e');
      }
    }
  } else {
    for (final path in paths) {
      try {
        final Stream<String> lines;
        if (path == '-' && input != null) {
          lines = await _readStream(input);
        } else {
          lines = utf8.decoder
              .bind(File(path).openRead())
              .transform(const LineSplitter());
        }
        lineNumber = await _writeLines(
            lines,
            lineNumber,
            output,
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
        result.addMessage(exitFailure, message, path: path);
      } on FormatException {
        result.addMessage(exitFailure, 'Binary file not supported.',
            path: path);
      } catch (e) {
        result.addMessage(exitFailure, '$e', path: path);
      }
    }
  }
  return result;
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
        sb.write('U+' + ch.toRadixString(16).padLeft(4, '0').toUpperCase());
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

/// Reads from stream (stdin, etc.)
Future<Stream<String>> _readStream(Stream<List<int>> input) async =>
    input.transform(utf8.decoder).transform(const LineSplitter());

/// Writes lines to stdout.
Future<int> _writeLines(Stream<String> lines, int lineNumber, Object out,
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

    try {
      if (out is IOSink) {
        out.writeln(sb);
      } else if (out is File) {
        await out.writeAsString("$sb\n", mode: FileMode.append);
      }
    } catch (e) {
      rethrow;
    }
  }
  return lineNumber;
}
