[![License (3-Clause BSD)](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg?style=flat-square)](http://opensource.org/licenses/BSD-3-Clause)
[![GitHub CI](https://github.com/ethauvin/dcat/actions/workflows/dart.yml/badge.svg)](https://github.com/ethauvin/dcat/actions/workflows/dart.yml)

# dcat: Concatenate file(s) to standard output.

A **cat** command-line implemenation in [Dart](https://dart.dev/), loosely based on the [Write command-line apps sample code](https://dart.dev/tutorials/server/cmdline).

## Command-Line Usage

```sh
dcat --help
```
```
Usage: dcat [OPTION]... [FILE]...
Concatenate FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.

  -b, --number-nonblank    number nonempty output lines, overrides -n
  -E, --show-ends          display $ at end of each line
  -h, --help               display this help and exit
  -n, --number             number all output lines
  -T, --show-tabs          display TAB characters as ^I
  -s, --squeeze-blank      suppress repeated empty output lines
      --version            output version information and exit

Examples:
  dcat f - g  Output f's contents, then standard input, then g's contents.
  dcat        Copy standard input to standard output.
  ```
## Compile Application
  
### Linux
```sh
dart compile exe -o bin/dcat bin/dcat.dart
```

### Windows
```cmd
dart compile.exe bin/dcat.dart
```

## Differences from GNU cat
  - No binary file support.
  - Line numbers are printed as `X:` where `X` is the line number.