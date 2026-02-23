// ignore_for_file: avoid_print

import 'package:packagekit/packagekit.dart';

void main() async {
  final client = PackageKitClient();
  await client.connect();

  print(
    'Server version: ${client.versionMajor}.${client.versionMinor}.${client.versionMicro}',
  );
  print('Backend: ${client.backendDescription} (${client.backendName})');
  print('Supported MIME types: ${client.mimeTypes.join(', ')}');

  await client.close();
}
