// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcat/dcat.dart';
import 'package:indent/indent.dart';

const appName = libName;
const appVersion = '1.0.0';
const helpFlag = 'help';
const nonBlankFlag = 'number-nonblank';
const numberFlag = 'number';
const showEndsFlag = 'show-ends';
const showTabsFlag = 'show-tabs';
const squeezeBlank = 'squeeze-blank';
const versionFlag = 'version';

/// Concatenates files specified in [arguments].
///
/// Usage: `dcat [OPTION]... [FILE]...`
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
    return await printError(
        "${e.message}\nTry '$appName --$helpFlag' for more information.",
        appName: appName);
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

/// Prints the version info.
Future<int> printVersion() async {
  print('''$appName (Dart cat) $appVersion
Copyright (C) 2021 Erik C. Thauvin
License: 3-Clause BSD <https://opensource.org/licenses/BSD-3-Clause>
 
Inspired by <https://dart.dev/tutorials/server/cmdline>
Written by Erik C. Thauvin <https://erik.thauvin.net/>''');
  return exitSuccess;
}

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
