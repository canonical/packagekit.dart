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
      'BackendAuthor': DBusString(server.backendAuthor),
      'BackendDescription': DBusString(server.backendDescription),
      'BackendName': DBusString(server.backendName),
      'DistroId': DBusString(server.distroId),
      'Filters': DBusUint64(server.filters),
      'Groups': DBusUint64(server.groups),
      'Locked': DBusBoolean(server.locked),
      'MimeTypes': DBusArray.string(server.mimeTypes),
      'NetworkState': DBusUint32(server.networkState),
      'Roles': DBusUint64(server.roles),
      'VersionMajor': DBusUint32(server.versionMajor),
      'VersionMicro': DBusUint32(server.versionMicro),
      'VersionMinor': DBusUint32(server.versionMinor)
    };
    return DBusGetAllPropertiesResponse(properties);
  }
}

class MockPackageKitServer extends DBusClient {
  late final MockPackageKitRoot _root;

  final String backendAuthor;
  final String backendDescription;
  final String backendName;
  final String distroId;
  final int filters;
  final int groups;
  final bool locked;
  final List<String> mimeTypes;
  final int networkState;
  final int roles;
  final int versionMajor;
  final int versionMicro;
  final int versionMinor;

  MockPackageKitServer(DBusAddress clientAddress,
      {this.backendAuthor = '',
      this.backendDescription = '',
      this.backendName = '',
      this.distroId = '',
      this.filters = 0,
      this.groups = 0,
      this.locked = false,
      this.mimeTypes = const [],
      this.networkState = 0,
      this.roles = 0,
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
        backendName: 'aptcc',
        backendDescription: 'APTcc',
        backendAuthor: '"Testy Tester" <test@example.com>');
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.backendName, equals('aptcc'));
    expect(client.backendDescription, equals('APTcc'));
    expect(client.backendAuthor, equals('"Testy Tester" <test@example.com>'));

    await client.close();
  });

  test('distro id', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit =
        MockPackageKitServer(clientAddress, distroId: 'ubuntu;21.04;x86_64');
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.distroId, equals('ubuntu;21.04;x86_64'));

    await client.close();
  });

  test('locked', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, locked: true);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.locked, isTrue);

    await client.close();
  });

  test('filters', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, filters: 0x5041154);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(
        client.filters,
        equals({
          PackageKitFilter.installed,
          PackageKitFilter.development,
          PackageKitFilter.gui,
          PackageKitFilter.free,
          PackageKitFilter.supported,
          PackageKitFilter.arch,
          PackageKitFilter.application,
          PackageKitFilter.downloaded
        }));

    await client.close();
  });

  test('groups', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, groups: 0xe8d6fcfc);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(
        client.groups,
        equals({
          PackageKitGroup.accessories,
          PackageKitGroup.adminTools,
          PackageKitGroup.communication,
          PackageKitGroup.desktopGnome,
          PackageKitGroup.desktopKde,
          PackageKitGroup.desktopOther,
          PackageKitGroup.fonts,
          PackageKitGroup.games,
          PackageKitGroup.graphics,
          PackageKitGroup.internet,
          PackageKitGroup.legacy,
          PackageKitGroup.localization,
          PackageKitGroup.multimedia,
          PackageKitGroup.network,
          PackageKitGroup.other,
          PackageKitGroup.programming,
          PackageKitGroup.publishing,
          PackageKitGroup.system,
          PackageKitGroup.science,
          PackageKitGroup.documentation,
          PackageKitGroup.electronics
        }));

    await client.close();
  });

  test('roles', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, roles: 0x1f2fefffe);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(
        client.roles,
        equals({
          PackageKitRole.cancel,
          PackageKitRole.dependsOn,
          PackageKitRole.getDetails,
          PackageKitRole.getFiles,
          PackageKitRole.getPackages,
          PackageKitRole.getRepositoryList,
          PackageKitRole.requiredBy,
          PackageKitRole.getUpdateDetail,
          PackageKitRole.getUpdates,
          PackageKitRole.installFiles,
          PackageKitRole.installPackages,
          PackageKitRole.installSignature,
          PackageKitRole.refreshCache,
          PackageKitRole.removePackages,
          PackageKitRole.repoEnable,
          PackageKitRole.resolve,
          PackageKitRole.searchDetails,
          PackageKitRole.searchFile,
          PackageKitRole.searchGroup,
          PackageKitRole.searchName,
          PackageKitRole.updatePackages,
          PackageKitRole.whatProvides,
          PackageKitRole.downloadPackages,
          PackageKitRole.getOldTransactions,
          PackageKitRole.repairSystem,
          PackageKitRole.getDetailsLocal,
          PackageKitRole.getFilesLocal,
          PackageKitRole.repoRemove
        }));

    await client.close();
  });

  test('mime types', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, mimeTypes: [
      'application/vnd.debian.binary-package',
      'application/x-deb'
    ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.mimeTypes,
        equals(['application/vnd.debian.binary-package', 'application/x-deb']));

    await client.close();
  });

  test('network state', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, networkState: 2);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.networkState, equals(PackageKitNetworkState.online));

    await client.close();
  });
}
