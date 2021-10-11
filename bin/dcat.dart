// Copyright (c) 2021, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcat/dcat.dart';
import 'package:indent/indent.dart';

const appName = 'dcat';
const appVersion = '1.0.0';
const helpFlag = 'help';
const nonBlankFlag = 'number-nonblank';
const numberFlag = 'number';
const showAllFlag = 'show-all';
const showEndsFlag = 'show-ends';
const showNonPrintingEndsFlag = 'show-nonprinting-ends';
const showNonPrintingFlag = 'show-nonprinting';
const showNonPrintingTabsFlag = 'show-nonprinting-tabs';
const showTabsFlag = 'show-tabs';
const squeezeBlank = 'squeeze-blank';
const versionFlag = 'version';

/// Concatenates files specified in [arguments].
///
/// Usage: `dcat [option] [file]…`
Future<int> main(List<String> arguments) async {
  final parser = ArgParser();
  Future<int> returnCode;
  exitCode = exitSuccess;
  parser.addFlag(showAllFlag,
      negatable: false, abbr: 'A', help: 'equivalent to -vET');
  parser.addFlag(nonBlankFlag,
      negatable: false,
      abbr: 'b',
      help: 'number nonempty output lines, overrides -n');
  parser.addFlag(showNonPrintingEndsFlag,
      negatable: false, abbr: 'e', help: 'equivalent to -vE');
  parser.addFlag(showEndsFlag,
      negatable: false, abbr: 'E', help: 'display \$ at end of each line');
  parser.addFlag(helpFlag,
      negatable: false, abbr: 'h', help: 'display this help and exit');
  parser.addFlag(numberFlag,
      negatable: false, abbr: 'n', help: 'number all output lines');
  parser.addFlag(showNonPrintingTabsFlag,
      negatable: false, abbr: 't', help: 'equivalent to -vT');
  parser.addFlag(showTabsFlag,
      negatable: false, abbr: 'T', help: 'display TAB characters as ^I');
  parser.addFlag(squeezeBlank,
      negatable: false,
      abbr: 's',
      help: 'suppress repeated empty output lines');
  parser.addFlag(versionFlag,
      negatable: false, help: 'output version information and exit');
  parser.addFlag('ignored', negatable: false, hide: true, abbr: 'u');
  parser.addFlag(showNonPrintingFlag,
      negatable: false,
      abbr: 'v',
      help: 'use ^ and M- notation, except for LFD and TAB');

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    exitCode = await printError(
        "${e.message}\nTry '$appName --$helpFlag' for more information.",
        appName: appName);
    return exitCode;
  }

  if (argResults[helpFlag]) {
    returnCode = usage(parser.usage);
  } else if (argResults[versionFlag]) {
    returnCode = printVersion();
  } else {
    final paths = argResults.rest;
    var showEnds = argResults[showEndsFlag];
    var showTabs = argResults[showTabsFlag];
    var showNonPrinting = argResults[showNonPrintingFlag];

    if (argResults[showNonPrintingEndsFlag]) {
      showNonPrinting = showEnds = true;
    }

    if (argResults[showNonPrintingTabsFlag]) {
      showNonPrinting = showTabs = true;
    }

    if (argResults[showAllFlag]) {
      showNonPrinting = showEnds = showTabs = true;
    }

    returnCode = cat(paths,
        appName: appName,
        showEnds: showEnds,
        showLineNumbers: argResults[numberFlag],
        numberNonBlank: argResults[nonBlankFlag],
        showTabs: showTabs,
        squeezeBlank: argResults[squeezeBlank],
        showNonPrinting: showNonPrinting);
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
