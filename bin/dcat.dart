// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:indent/indent.dart';

const appName = 'dcat';
const appVersion = '1.0.0';
const exitFailure = 1;
const exitSuccess = 0;
const helpFlag = 'help';
const nonBlankFlag = 'number-nonblank';
const numberFlag = 'number';
const showEndsFlag = 'show-ends';
const showTabsFlag = 'show-tabs';
const squeezeBlank = 'squeeze-blank';
const versionFlag = 'version';

/// Prints [message] and [path] to stderr.
Future<int> handleError(String message, {String path = ''}) async {
  if (path.isNotEmpty) {
    stderr.writeln('$appName: $path: $message');
  } else {
    stderr.write('$appName: $message');
  }
  return exitFailure;
}

/// Concatenates files in [paths].
Future<int> cat(List<String> paths,
    {List<String>? log,
    bool showEnds = false,
    bool numberNonBlank = false,
    bool showLineNumbers = false,
    bool showTabs = false,
    bool squeezeBlank = false}) async {
  var lineNumber = 1;
  var returnCode = 0;
  log?.clear();
  if (paths.isEmpty) {
    final lines = await _readStdin();
    await _writeLines(lines, lineNumber, log, showEnds, showLineNumbers,
        numberNonBlank, showTabs, squeezeBlank);
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
        lineNumber = await _writeLines(lines, lineNumber, log, showEnds,
            showLineNumbers, numberNonBlank, showTabs, squeezeBlank);
      } on FileSystemException catch (e) {
        final String? osMessage = e.osError?.message;
        final String message;
        if (osMessage != null && osMessage.isNotEmpty) {
          message = osMessage;
        } else {
          message = e.message;
        }
        returnCode = await handleError(message, path: path);
      } on FormatException {
        returnCode =
            await handleError('Binary file not supported.', path: path);
      } catch (e) {
        returnCode = await handleError(e.toString(), path: path);
      }
    }
  }
  return returnCode;
}

/// Concatenates files specified in [arguments].
///
/// ```
/// dcat [OPTION]... [FILE]...
/// ```
Future<int> main(List<String> arguments) async {
  final parser = ArgParser();
  Future<int> returnCode;
  exitCode = exitSuccess;
  parser.addFlag(nonBlankFlag,
      negatable: false,
      abbr: 'b',
      help: 'number nonempty output lines, overrides -n');
  parser.addFlag(showEndsFlag,
      negatable: false, abbr: 'E', help: 'display \$ at end of each line');
  parser.addFlag(helpFlag,
      negatable: false, abbr: 'h', help: 'display this help and exit');
  parser.addFlag(numberFlag,
      negatable: false, abbr: 'n', help: 'number all output lines');
  parser.addFlag(showTabsFlag,
      negatable: false, abbr: 'T', help: 'display TAB characters as ^I');
  parser.addFlag(squeezeBlank,
      negatable: false,
      abbr: 's',
      help: 'suppress repeated empty output lines');
  parser.addFlag(versionFlag,
      negatable: false, help: 'output version information and exit');

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    return await handleError(
        "${e.message}\nTry '$appName --$helpFlag' for more information.");
  }

  if (argResults[helpFlag]) {
    returnCode = usage(parser.usage);
  } else if (argResults[versionFlag]) {
    returnCode = printVersion();
  } else {
    final paths = argResults.rest;
    returnCode = cat(paths,
        showEnds: argResults[showEndsFlag],
        showLineNumbers: argResults[numberFlag],
        numberNonBlank: argResults[nonBlankFlag],
        showTabs: argResults[showTabsFlag],
        squeezeBlank: argResults[squeezeBlank]);
  }

  exitCode = await returnCode;
  return exitCode;
}

/// Prints version info.
Future<int> printVersion() async {
  print('''$appName (Dart cat) $appVersion
Copyright (C) 2021 Erik C. Thauvin
License: 3-Clause BSD <https://opensource.org/licenses/BSD-3-Clause>
 
Based on <https://dart.dev/tutorials/server/cmdline>
Written by Erik C. Thauvin <https://erik.thauvin.net/>''');
  return exitSuccess;
}

/// Reads from stdin.
Future<Stream<String>> _readStdin() async =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());

/// Prints usage with [options].
Future<int> usage(String options) async {
  print('''Usage: $appName [OPTION]... [FILE]...
Concatenate FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.

${options.indent(2)}
Examples:
  $appName f - g  Output f's contents, then standard input, then g's contents.
  $appName        Copy standard input to standard output.
  
 Source and documentation: <https://github.com/ethauvin/dcat>''');
  return exitSuccess;
}

/// Writes lines to stdout.
Future<int> _writeLines(Stream<String> lines, int lineNumber,
    [List<String>? log,
    bool showEnds = false,
    bool showLineNumbers = false,
    bool showNonBlank = false,
    bool showTabs = false,
    bool sqeezeBlank = false]) async {
  var emptyLine = 0;
  final sb = StringBuffer();
  await for (final line in lines) {
    sb.clear();
    if (sqeezeBlank && line.isEmpty) {
      if (++emptyLine >= 2) {
        continue;
      }
    } else {
      emptyLine = 0;
    }
    if (showNonBlank || showLineNumbers) {
      sb.write('${lineNumber++}: ');
    }
    if (showTabs) {
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
