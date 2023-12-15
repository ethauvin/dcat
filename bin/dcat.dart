// Copyright (c) 2021-2022, Erik C. Thauvin. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcat/dcat.dart';
import 'package:indent/indent.dart';

const appName = 'dcat';
const appVersion = '1.0.0';
const helpFlag = 'help';
const homePage = 'https://github.com/ethauvin/dcat';
const numberFlag = 'number';
const numberNonBlankFlag = 'number-nonblank';
const showAllFlag = 'show-all';
const showEndsFlag = 'show-ends';
const showNonPrintingEndsFlag = 'show-nonprinting-ends';
const showNonPrintingFlag = 'show-nonprinting';
const showNonPrintingTabsFlag = 'show-nonprinting-tabs';
const showTabsFlag = 'show-tabs';
const squeezeBlankFlag = 'squeeze-blank';
const versionFlag = 'version';

// Concatenates file(s) to standard output.
//
// Usage: `dcat [option] [file]…`
Future<int> main(List<String> arguments) async {
  exitCode = exitSuccess;

  final parser = await setupArgsParser();
  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('''$appName: ${e.message}
Try '$appName --$helpFlag' for more information.''');
    exitCode = exitFailure;
    return exitCode;
  }

  if (argResults[helpFlag]) {
    exitCode = await usage(parser.usage);
  } else if (argResults[versionFlag]) {
    exitCode = await printVersion();
  } else {
    final paths = argResults.rest;
    var showEnds = argResults[showEndsFlag];
    var showLineNumbers = argResults[numberFlag];
    final showNonBlank = argResults[numberNonBlankFlag];
    var showNonPrinting = argResults[showNonPrintingFlag];
    var showTabs = argResults[showTabsFlag];

    if (argResults[showNonPrintingEndsFlag]) {
      showNonPrinting = showEnds = true;
    }

    if (argResults[showNonPrintingTabsFlag]) {
      showNonPrinting = showTabs = true;
    }

    if (argResults[showAllFlag]) {
      showNonPrinting = showEnds = showTabs = true;
    }

    if (showNonBlank) {
      showLineNumbers = true;
    }

    final result = await cat(paths, stdout,
        input: stdin,
        numberNonBlank: showNonBlank,
        showEnds: showEnds,
        showLineNumbers: showLineNumbers,
        showNonPrinting: showNonPrinting,
        showTabs: showTabs,
        squeezeBlank: argResults[squeezeBlankFlag]);

    for (final error in result.errors) {
      await printError(error);
    }

    exitCode = result.exitCode;
  }

  return exitCode;
}

// Sets up the command-line arguments parser.
Future<ArgParser> setupArgsParser() async {
  final parser = ArgParser();

  parser.addFlag(showAllFlag,
      negatable: false, abbr: 'A', help: 'equivalent to -vET');
  parser.addFlag(numberNonBlankFlag,
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
  parser.addFlag(squeezeBlankFlag,
      negatable: false,
      abbr: 's',
      help: 'suppress repeated empty output lines');
  parser.addFlag('ignored', negatable: false, hide: true, abbr: 'u');
  parser.addFlag(showNonPrintingFlag,
      negatable: false,
      abbr: 'v',
      help: 'use ^ and M- notation, except for LFD and TAB');
  parser.addFlag(versionFlag,
      negatable: false, help: 'output version information and exit');

  return parser;
}

// Prints an error to stderr.
Future<void> printError(CatError error) async {
  stderr.writeln(
      '$appName: ${error.hasPath ? '${error.path}: ' : ''}${error.message}');
}

// Prints the version info.
Future<int> printVersion() async {
  stdout.writeln('''$appName (Dart cat) $appVersion
Copyright (C) 2021-2022 Erik C. Thauvin
License 3-Clause BSD: <https://opensource.org/licenses/BSD-3-Clause>

Written by Erik C. Thauvin <https://erik.thauvin.net/>
Source: $homePage''');
  return exitSuccess;
}

// Prints the help/usage.
Future<int> usage(String options) async {
  stdout.writeln('''Usage: $appName [OPTION]... [FILE]...
Concatenate FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.

${options.indent(2)}
Examples:
  $appName f - g  Output f's contents, then standard input, then g's contents.
  $appName        Copy standard input to standard output.

Source and documentation: <$homePage>''');
  return exitSuccess;
}
