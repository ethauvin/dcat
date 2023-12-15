dart run test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib,bin
genhtml -o coverage coverage/lcov.info
open coverage/index.html 2>/dev/null
