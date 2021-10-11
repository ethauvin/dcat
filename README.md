[![License (3-Clause BSD)](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg?style=flat-square)](http://opensource.org/licenses/BSD-3-Clause)
[![GitHub CI](https://github.com/ethauvin/dcat/actions/workflows/dart.yml/badge.svg)](https://github.com/ethauvin/dcat/actions/workflows/dart.yml)

# dcat: Concatenate File(s) to Standard Output

A **cat** command-line implemenation in [Dart](https://dart.dev/), inspired by the [Write command-line apps sample code](https://dart.dev/tutorials/server/cmdline).

## Synopsis

**dcat** copies each file, or standard input if none are given, to standard output.

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
  -v, --show-nonprinting         use ^ and M- notation, except for LFD and TAB

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

## Differences from [GNU cat](https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html#cat-invocation)
  - No binary file support.
  - A line is considered terminated by either a `CR` (carriage return), a `LF` (line feed), a `CR+LF` sequence (DOS line ending).
  - The non-printing `M-^?` notation is always used for unicode characters.