// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

/// A library to concatenate files to standard output or file.
library dcat;

import 'dart:convert';
import 'dart:io';

/// Failure exit code.
const exitFailure = 1;

/// Success exit code.
const exitSuccess = 0;

const _lineFeed = 10;

/// Holds the [cat] result [exitCode] and error [messages].
class CatResult {
  /// The exit code.
  int exitCode = exitSuccess;

  /// The error messages.
  final List<String> messages = [];

  CatResult();

  /// Returns `true` if the [exitCode] is [exitFailure].
  bool get isFailure => exitCode == exitFailure;

  /// Returns `true` if the [exitCode] is [exitSuccess].
  bool get isSuccess => exitCode == exitSuccess;

  /// Add a message with an optional path.
  void addMessage(int exitCode, String message, {String? path}) {
    this.exitCode = exitCode;
    if (path != null && path.isNotEmpty) {
      messages.add('$path: $message');
    } else {
      messages.add(message);
    }
  }
}

// Holds the current line number and last character.
class _LastLine {
  int lineNumber;
  int lastChar;

  _LastLine(this.lineNumber, this.lastChar);
}

/// Concatenates files in [paths] to the standard output or a file.
///
///  * [output] should be an [IOSink] such as [stdout] or [File.openWrite].
///  * [input] can be [stdin].
///
/// The remaining optional parameters are similar to the [GNU cat utility](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation).
Future<CatResult> cat(List<String> paths, IOSink output,
    {Stream<List<int>>? input,
    bool showEnds = false,
    bool numberNonBlank = false,
    bool showLineNumbers = false,
    bool showTabs = false,
    bool squeezeBlank = false,
    bool showNonPrinting = false}) async {
  final result = CatResult();
  final lastLine = _LastLine(0, _lineFeed);
  if (paths.isEmpty) {
    if (input != null) {
      try {
        await _writeStream(input, lastLine, output, showEnds, showLineNumbers,
            numberNonBlank, showTabs, squeezeBlank, showNonPrinting);
      } catch (e) {
        result.addMessage(exitFailure, '$e');
      }
    }
  } else {
    for (final path in paths) {
      try {
        final Stream<List<int>> stream;
        if (path == '-' && input != null) {
          stream = input;
        } else {
          stream = File(path).openRead();
        }
        await _writeStream(stream, lastLine, output, showEnds, showLineNumbers,
            numberNonBlank, showTabs, squeezeBlank, showNonPrinting);
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

// Writes parsed data from a stream
Future<void> _writeStream(
    Stream stream,
    _LastLine lastLine,
    IOSink out,
    bool showEnds,
    bool showLineNumbers,
    bool numberNonBlank,
    bool showTabs,
    bool squeezeBlank,
    bool showNonPrinting) async {
  const tab = 9;
  int squeeze = 0;
  final sb = StringBuffer();
  await stream.forEach((data) {
    sb.clear();
    for (final ch in utf8.decode(data).runes) {
      if (lastLine.lastChar == _lineFeed) {
        if (squeezeBlank) {
          if (ch == _lineFeed) {
            if (squeeze >= 1) {
              lastLine.lastChar = ch;
              continue;
            }
            squeeze++;
          } else {
            squeeze = 0;
          }
        }
        if (showLineNumbers || numberNonBlank) {
          if (!numberNonBlank || ch != _lineFeed) {
            sb.write('${++lastLine.lineNumber}'.padLeft(6) + '\t');
          }
        }
      }
      lastLine.lastChar = ch;
      if (ch == _lineFeed) {
        if (showEnds) {
          sb.write('\$');
        }
      } else if (ch == tab) {
        if (showTabs) {
          sb.write('^I');
          continue;
        }
      } else if (showNonPrinting) {
        if (ch >= 32) {
          if (ch < 127) {
            // ASCII
            sb.writeCharCode(ch);
            continue;
          } else if (ch == 127) {
            // NULL
            sb.write('^?');
            continue;
          } else {
            // UNICODE
            sb.write('U+' + ch.toRadixString(16).padLeft(4, '0').toUpperCase());
            continue;
          }
        } else {
          sb
            ..write('^')
            ..writeCharCode(ch + 64);
          continue;
        }
      }
      sb.writeCharCode(ch);
    }
    if (sb.isNotEmpty) {
      out.write(sb);
    }
  });
}