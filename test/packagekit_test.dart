import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:packagekit/packagekit.dart';

class MockPackageKitRoot extends DBusObject {
  final MockPackageKitServer server;

  MockPackageKitRoot(this.server)
      : super(DBusObjectPath('/org/freedesktop/PackageKit'));

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{
      'BackendDescription': DBusString(server.backendDescription),
      'BackendName': DBusString(server.backendName),
      'VersionMajor': DBusUint32(server.versionMajor),
      'VersionMicro': DBusUint32(server.versionMicro),
      'VersionMinor': DBusUint32(server.versionMinor)
    };
    return DBusGetAllPropertiesResponse(properties);
  }
}

class MockPackageKitServer extends DBusClient {
  late final MockPackageKitRoot _root;

  final String backendDescription;
  final String backendName;
  final int versionMajor;
  final int versionMicro;
  final int versionMinor;

  MockPackageKitServer(DBusAddress clientAddress,
      {this.backendDescription = '',
      this.backendName = '',
      this.versionMajor = 0,
      this.versionMicro = 0,
      this.versionMinor = 0})
      : super(clientAddress);

  Future<void> start() async {
    await requestName('org.freedesktop.PackageKit');
    _root = MockPackageKitRoot(this);
    await registerObject(_root);
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        versionMajor: 1, versionMinor: 2, versionMicro: 3);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.versionMajor, equals(1));
    expect(client.versionMinor, equals(2));
    expect(client.versionMicro, equals(3));

    await client.close();
  });

  test('backend', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        backendName: 'aptcc', backendDescription: 'APTcc');
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.backendName, equals('aptcc'));
    expect(client.backendDescription, equals('APTcc'));

    await client.close();
  });
}
