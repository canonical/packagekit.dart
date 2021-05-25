import 'package:packagekit/packagekit.dart';

void main() async {
  var client = PackageKitClient();
  await client.connect();
  print(
      'Server version: ${client.versionMajor}.${client.versionMinor}.${client.versionMicro}');
  await client.close();
}
