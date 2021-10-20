// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

/// A library to concatenate files to standard output or file.
library dcat;

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
  void addMessage(String message, {String? path}) {
    exitCode = exitFailure;
    if (path != null && path.isNotEmpty) {
      messages.add('$path: $message');
    } else {
      messages.add(message);
    }
  }
}

// Holds the current line number and last character.
class _LastLine {
  int lineNumber = 0;
  int lastChar = _lineFeed;
}

/// Concatenates files in [paths] to the standard output or a file.
///
///  * [output] should be an [IOSink] such as [stdout] or [File.openWrite].
///  * [input] can be [stdin].
///
/// The remaining optional parameters are similar to the [GNU cat utility](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation).
Future<CatResult> cat(List<String> paths, IOSink output,
    {Stream<List<int>>? input,
    bool numberNonBlank = false,
    bool showEnds = false,
    bool showLineNumbers = false,
    bool showNonPrinting = false,
    bool showTabs = false,
    bool squeezeBlank = false}) async {
  final result = CatResult();
  final lastLine = _LastLine();

  if (paths.isEmpty) {
    if (input != null) {
      try {
        await _copyStream(input, lastLine, output, numberNonBlank, showEnds,
            showLineNumbers, showNonPrinting, showTabs, squeezeBlank);
      } catch (e) {
        result.addMessage(_getErrorMessage(e));
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
        await _copyStream(stream, lastLine, output, numberNonBlank, showEnds,
            showLineNumbers, showNonPrinting, showTabs, squeezeBlank);
      } catch (e) {
        result.addMessage(_getErrorMessage(e), path: path);
      }
    }
  }
  return result;
}

// Copies (and formats) a stream to an IO sink.
Future<void> _copyStream(
    Stream<List<int>> stream,
    _LastLine lastLine,
    IOSink out,
    bool numberNonBlank,
    bool showEnds,
    bool showLineNumbers,
    bool showNonPrinting,
    bool showTabs,
    bool squeezeBlank) async {
  // No flags
  if (!showEnds &&
      !showLineNumbers &&
      !numberNonBlank &&
      !showTabs &&
      !squeezeBlank &&
      !showNonPrinting) {
    await stream.forEach(out.add);
  } else {
    const caret = 94;
    const questionMark = 63;
    const tab = 9;
    int squeeze = 0;
    final List<int> buff = [];

    await stream.forEach((data) {
      buff.clear();
      for (final ch in data) {
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
              buff.addAll('${++lastLine.lineNumber}'.padLeft(6).codeUnits);
              buff.add(tab);
            }
          }
        }
        lastLine.lastChar = ch;
        if (ch == _lineFeed) {
          if (showEnds) {
            // $ at EOL
            buff.add(36);
          }
        } else if (ch == tab) {
          if (showTabs) {
            // TAB (^I)
            buff
              ..add(caret)
              ..add(73);
            continue;
          }
        } else if (showNonPrinting) {
          if (ch >= 32) {
            if (ch < 127) {
              // ASCII
              buff.add(ch);
              continue;
            } else if (ch == 127) {
              // NULL (^?)
              buff
                ..add(caret)
                ..add(questionMark);
              continue;
            } else {
              // HIGH BIT (M-)
              buff.add(77);
              buff.add(45);
              if (ch >= 128 + 32) {
                if (ch < 128 + 127) {
                  buff.add(ch - 128);
                } else {
                  buff
                    ..add(caret)
                    ..add(questionMark);
                }
              } else {
                buff.add(caret);
                buff.add(ch - 128 + 64);
              }
              continue;
            }
          } else {
            // CTRL
            buff
              ..add(caret)
              ..add(ch + 64);
            continue;
          }
        }
        buff.add(ch);
      }
      if (buff.isNotEmpty) {
        out.add(buff);
      }
    });
  }
}

// Returns the message describing an error.
String _getErrorMessage(Object e) {
  final String message;
  if (e is FileSystemException) {
    final String? osMessage = e.osError?.message;
    if (osMessage != null && osMessage.isNotEmpty) {
      message = osMessage;
    } else {
      message = e.message;
    }
  } else {
    message = '$e';
  }
  return message;
}
