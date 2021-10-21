import 'dart:io';

import 'package:dcat/dcat.dart';

// Usage: dart example.dart file...
Future<void> main(List<String> arguments) async {
  // Display the file(s) with line numbers to the standard output
  final result = await cat(arguments, stdout, showLineNumbers: true);
  if (result.isFailure) {
    for (final error in result.errors) {
      print("Error with '${error.path}': ${error.message}");
    }
  }
}
