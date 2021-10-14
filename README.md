[![License (3-Clause BSD)](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg?style=flat-square)](http://opensource.org/licenses/BSD-3-Clause)
[![GitHub CI](https://github.com/ethauvin/dcat/actions/workflows/dart.yml/badge.svg)](https://github.com/ethauvin/dcat/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/ethauvin/dcat/branch/master/graph/badge.svg?token=9PC4K4IZXJ)](https://codecov.io/gh/ethauvin/dcat)

# dcat: Concatenate File(s) to Standard Output or File

A **cat** command-line and library implementation in [Dart](https://dart.dev/), inspired by the [Write command-line apps sample code](https://dart.dev/tutorials/server/cmdline).

## Synopsis

**dcat** copies each file, or standard input if none are given, to standard output or file.

## Command-Line Usage

```sh
dcat --help
```
```
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
      --version                  output version information and exit
  -v, --show-nonprinting         use ^ and U+ notation, except for LFD and TAB

Examples:
  dcat f - g  Output f's contents, then standard input, then g's contents.
  dcat        Copy standard input to standard output.
  ```
## Compile Standalone Application
  
### *nix
```sh
dart compile exe -o bin/dcat bin/dcat.dart
```

### Windows
```cmd
dart compile exe bin/dcat.dart
```

## Library Usage
```dart
import 'package:dcat/dcat.dart';

final result = await cat(['path/to/file', 'path/to/otherfile]'], File('path/to/outfile'));
if (result.exitCode == exitFailure) {
  for (final message in result.messages) {
    print("Error: $message");
  }
}
```

The `cat` function supports the following parameters:

Parameter        | Description                   |  Type    
:--------------- |:----------------------------- | :-------------------
paths            | The file paths.               | String[]
output           | The standard output or file.  | IOSink or File
input            | The standard input.           | Stream<List\<int\>\>?
log              | The log for debugging.        | List\<String\>?
showEnds         | Same as `-e`                  | bool
numberNonBlank   | Same as `-b`                  | bool
showLineNumbers  | Same as `-n`                  | bool
showTabs         | Same as `-T`                  | bool
squeezeBlank     | Same as `-s`                  | bool
showNonPrinting  | Same as `-v`                  | bool

* `paths` and `output` are required.
* `output` should be an `IOSink` like `stdout` or a `File`.
* `input` can be `stdin`.
* `log` is used for debugging/testing purposes.

The remaining optional parameters are similar to the [GNU cat](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation) utility.

A `CatResult` object is returned which contains the `exitCode` (`exitSuccess` or `exitFailure`) and error `messages` if any:

```dart
final result = await cat(['path/to/file'], stdout);
if (result.exitCode == exitSuccess) {
  ...
}
```

## Differences from [GNU cat](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation)
  - No binary file support.
  - A line is considered terminated by either a `CR` (carriage return), a `LF` (line feed), a `CR+LF` sequence (DOS line ending).
  - A line ending is automatically appended to the last line of any read file.
  - The `U+` notation is used instead of `M-` for non-printing characters.