[![License (3-Clause BSD)](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg?logo=open-source-initiative&logoColor=white)](https://opensource.org/licenses/BSD-3-Clause)
[![GitHub CI](https://github.com/ethauvin/dcat/actions/workflows/dart.yml/badge.svg)](https://github.com/ethauvin/dcat/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/ethauvin/dcat/branch/master/graph/badge.svg?token=9PC4K4IZXJ)](https://codecov.io/gh/ethauvin/dcat)
[![pub package](https://img.shields.io/pub/v/dcat.svg?logo=dart)](https://pub.dev/packages/dcat)

# dcat: Concatenate File(s) to Standard Output or File

A [Dart](https://dart.dev/) command-line and library implementation of the standard **cat** Unix utility, inspired by the [Write command-line apps sample code](https://dart.dev/tutorials/server/cmdline).

## Synopsis

**dcat** sequentially reads files, or standard input if none are given, writing them to standard output or file.

## Command-Line Usage

```console
dcat --help
```

```text
Usage: dcat [OPTION]... [FILE]...
Concatenate FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.

  -A, --show-all                 equivalent to -vET
  -b, --number-nonblank          number nonempty output lines, overrides -n
  -e, --show-nonprinting-ends    equivalent to -vE
  -E, --show-ends                display $ at end of each line
  -h, --help                     display this help and exit
  -n, --number                   number all output lines
  -t, --show-nonprinting-tabs    equivalent to -vT
  -T, --show-tabs                display TAB characters as ^I
  -s, --squeeze-blank            suppress repeated empty output lines
  -v, --show-nonprinting         use ^ and M- notation, except for LFD and TAB
      --version                  output version information and exit

Examples:
  dcat f - g  Output f's contents, then standard input, then g's contents.
  dcat        Copy standard input to standard output.
  ```

## Compile Standalone Application
  
### Linux / MacOS

```console
dart compile exe -o bin/dcat bin/dcat.dart
```

### Windows

```console
dart compile exe bin/dcat.dart
```

## Library Usage

```console
dart pub add dcat
```

```dart
import 'package:dcat/dcat.dart';

final result = await cat(['path/to/file', 'path/to/otherfile]'],
    File('path/to/outfile').openWrite());
if (result.isFailure) {
  for (final error in result.errors) {
    print('Error: ${error.message}');
  }
}
```

[View Full Instructions](https://pub.dev/packages/dcat/install)

The `cat` function supports the following parameters:

Parameter        | Description                   |  Type
:--------------- |:----------------------------- | :-------------------
paths            | The file paths.               | String[]
output           | The standard output or file.  | [IOSink](https://api.dart.dev/dart-io/IOSink-class.html)
input            | The standard input.           | [Stream](https://api.dart.dev/dart-io/Stdin-class.html)
showEnds         | Same as `-e`                  | bool
numberNonBlank   | Same as `-b`                  | bool
showLineNumbers  | Same as `-n`                  | bool
showTabs         | Same as `-T`                  | bool
squeezeBlank     | Same as `-s`                  | bool
showNonPrinting  | Same as `-v`                  | bool

* `paths` and `output` are required.
* `output` should be an [IOSink](https://api.dart.dev/dart-io/IOSink-class.html) such as `stdout` or a [File](https://api.dart.dev/dart-io/File/openWrite.html) stream.
* `input` can be [stdin](https://api.dart.dev/dart-io/Stdin-class.html).

The remaining optional parameters are similar to the [GNU cat](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation) utility.

A `CatResult` object is returned which contains the `exitCode` (`exitSuccess` or `exitFailure`) and `errors`, if any:

```dart
final result = 
    await cat(['path/to/file'], stdout, showLineNumbers: true);
if (result.exitCode == exitSuccess) { // or result.isSuccess
  // ...
} else {
  for (final error in result.errors) {
    stderr.writeln("Error with '${error.path}': ${error.message}");
  }
}
```

[View Full Example](https://github.com/ethauvin/dcat/blob/master/example/example.dart)
