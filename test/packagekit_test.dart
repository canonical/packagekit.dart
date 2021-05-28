import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:packagekit/packagekit.dart';

const int ErrorPackageNotFound = 8;

const int ExitSuccess = 1;
const int ExitFailed = 2;

const int InfoInstalled = 1;
const int InfoAvailable = 2;
const int InfoNormal = 5;
const int InfoDownloading = 10;
const int InfoUpdating = 11;
const int InfoInstalling = 12;
const int InfoRemoving = 13;
const int InfoFinished = 18;
const int InfoPreparing = 21;
const int InfoDecompressing = 22;

const int MediaTypeDvd = 2;

const int RestartSystem = 4;

const int StatusSetup = 2;
const int StatusRemove = 6;
const int StatusDownload = 8;
const int StatusInstall = 9;

const int FilterInstalled = 0x4;

class MockPackageKitTransaction extends DBusObject {
  final MockPackageKitServer server;

  MockPackageKitTransaction(this.server, DBusObjectPath path) : super(path);

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.PackageKit.Transaction') {
      return DBusMethodErrorResponse.unknownMethod();
    }

    switch (methodCall.name) {
      case 'DownloadPackages':
        var packageIds = (methodCall.values[1] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(ErrorPackageNotFound, 'Package not found');
            emitFinished(ExitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          var packageId = PackageKitPackageId.fromString(id);
          emitFiles(id, [
            '/var/cache/apt/archives/${packageId.name}_${packageId.version}_${packageId.arch}.deb'
          ]);
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetPackages':
        var filter = (methodCall.values[0] as DBusUint64).value;
        for (var p in server.installedPackages) {
          emitPackage(InfoInstalled,
              '${p.name};${p.version};${p.arch};installed', p.summary);
        }
        if ((filter & FilterInstalled) == 0) {
          for (var source in server.availablePackages.keys) {
            var packages = server.availablePackages[source]!;
            for (var p in packages) {
              emitPackage(InfoAvailable,
                  '${p.name};${p.version};${p.arch};$source', p.summary);
            }
          }
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetRepoList':
        for (var repo in server.repositories) {
          emitRepoDetail(repo.id, repo.description, repo.enabled);
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetUpdates':
        for (var package in server.installedPackages) {
          for (var source in server.availablePackages.keys) {
            var packages = server.availablePackages[source]!;
            for (var p in packages) {
              if (p.name == package.name && p.version != package.version) {
                emitPackage(InfoNormal,
                    '${p.name};${p.version};${p.arch};$source', p.summary);
              }
            }
          }
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'InstallPackages':
        var packageIds = (methodCall.values[1] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(ErrorPackageNotFound, 'Package not found');
            emitFinished(ExitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitPackage(InfoDownloading, id, package.summary);
          emitItemProgress(id, StatusDownload, 0);
          emitItemProgress(id, StatusDownload, 21);
          emitItemProgress(id, StatusDownload, 86);
          emitPackage(InfoFinished, id, package.summary);
          emitPackage(InfoPreparing, id, package.summary);
          emitItemProgress(id, StatusSetup, 25);
          emitPackage(InfoDecompressing, id, package.summary);
          emitItemProgress(id, StatusSetup, 50);
          emitPackage(InfoFinished, id, package.summary);
          emitPackage(InfoInstalling, id, package.summary);
          emitPackage(InfoFinished, id, package.summary);
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RefreshCache':
        for (var repo in server.repositories) {
          emitRepoDetail(repo.id, repo.description, repo.enabled);
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RemovePackages':
        var packageIds = (methodCall.values[1] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        for (var id in packageIds) {
          var package = server.findInstalled(id);
          if (package == null) {
            emitErrorCode(ErrorPackageNotFound, 'Package not found');
            emitFinished(ExitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitPackage(InfoRemoving, id, package.summary);
          emitItemProgress(id, StatusSetup, 50);
          emitItemProgress(id, StatusRemove, 75);
          emitPackage(InfoFinished, id, package.summary);
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'Resolve':
        var packageNames = (methodCall.values[1] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        for (var name in packageNames) {
          for (var p in server.installedPackages) {
            if (p.name == name) {
              emitPackage(InfoInstalled,
                  '${p.name};${p.version};${p.arch};installed', p.summary);
            }
          }
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'SearchNames':
        var values = (methodCall.values[1] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        bool nameMatches(String name) {
          for (var value in values) {
            if (!name.contains(value)) {
              return false;
            }
          }
          return true;
        }
        for (var p in server.installedPackages) {
          if (nameMatches(p.name)) {
            emitPackage(InfoInstalled,
                '${p.name};${p.version};${p.arch};installed', p.summary);
          }
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'UpdatePackages':
        var packageIds = (methodCall.values[1] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(ErrorPackageNotFound, 'Package not found');
            emitFinished(ExitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitPackage(InfoUpdating, id, package.summary);
          emitPackage(InfoFinished, id, package.summary);
        }
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'UpgradeSystem':
        var id = 'linux;2.0;arm64;installed';
        var summary = 'Linux kernel';
        emitMediaChangeRequired(
            MediaTypeDvd, 'ubuntu-21-10.iso', 'Ubuntu 21.10 DVD');
        emitPackage(InfoUpdating, id, summary);
        emitPackage(InfoFinished, id, summary);
        emitRequireRestart(RestartSystem, id);
        emitFinished(ExitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  void emitErrorCode(int code, String details) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'ErrorCode',
        [DBusUint32(code), DBusString(details)]);
  }

  void emitFiles(String packageId, Iterable<String> fileList) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'Files',
        [DBusString(packageId), DBusArray.string(fileList)]);
  }

  void emitFinished(int exit, int runtime) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'Finished',
        [DBusUint32(exit), DBusUint32(runtime)]);
  }

  void emitItemProgress(String packageId, int status, int percentage) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'ItemProgress',
        [DBusString(packageId), DBusUint32(status), DBusUint32(percentage)]);
  }

  void emitMediaChangeRequired(
      int mediaType, String mediaId, String mediaText) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'MediaChangeRequired',
        [DBusUint32(mediaType), DBusString(mediaId), DBusString(mediaText)]);
  }

  void emitPackage(int info, String packageId, String summary) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'Package',
        [DBusUint32(info), DBusString(packageId), DBusString(summary)]);
  }

  void emitRepoDetail(String id, String description, bool enabled) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'RepoDetail',
        [DBusString(id), DBusString(description), DBusBoolean(enabled)]);
  }

  void emitRequireRestart(int type, String packageId) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'RequireRestart',
        [DBusUint32(type), DBusString(packageId)]);
  }
}

class MockPackageKitRoot extends DBusObject {
  final MockPackageKitServer server;
  var nextTransactionId = 1;

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

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    List<DBusValue>? returnValues;
    if (methodCall.interface == 'org.freedesktop.PackageKit') {
      switch (methodCall.name) {
        case 'CreateTransaction':
          var path = DBusObjectPath('/Transaction$nextTransactionId');
          nextTransactionId++;
          var transaction = MockPackageKitTransaction(server, path);
          await server.registerObject(transaction);
          returnValues = [transaction.path];
          break;
      }
    }

    if (returnValues == null) {
      return DBusMethodErrorResponse.unknownMethod();
    } else {
      return DBusMethodSuccessResponse(returnValues);
    }
  }
}

class MockRepository {
  final String id;
  final String description;
  final bool enabled;

  const MockRepository(this.id, this.description, this.enabled);
}

class MockPackage {
  final String name;
  final String version;
  final String arch;
  final String summary;

  const MockPackage(this.name, this.version,
      {this.arch = '', this.summary = ''});
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

  final int transactionRuntime;
  final List<MockRepository> repositories;
  final Map<String, List<MockPackage>> availablePackages;
  final List<MockPackage> installedPackages;

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
      this.versionMinor = 0,
      this.transactionRuntime = 0,
      this.repositories = const [],
      this.availablePackages = const {},
      this.installedPackages = const []})
      : super(clientAddress);

  MockPackage? findInstalled(String packageId) {
    var id = PackageKitPackageId.fromString(packageId);
    for (var package in installedPackages) {
      if (package.name == id.name &&
          package.version == id.version &&
          package.arch == id.arch) {
        return package;
      }
    }
    return null;
  }

  MockPackage? findAvailable(String packageId) {
    var id = PackageKitPackageId.fromString(packageId);
    var packages = availablePackages[id.data];
    if (packages == null) {
      return null;
    }
    for (var package in packages) {
      if (package.name == id.name &&
          package.version == id.version &&
          package.arch == id.arch) {
        return package;
      }
    }
    return null;
  }

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

  test('get packages', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ],
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('ed', '1.17',
                arch: 'arm64', summary: 'classic UNIX line editor')
          ]
        });
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('hello;2.10;arm64;installed'),
              summary: 'example package based on GNU hello'),
          PackageKitPackageEvent(
              info: PackageKitInfo.available,
              packageId: PackageKitPackageId.fromString(
                  'ed;1.17;arm64;ubuntu-hirsute-main'),
              summary: 'classic UNIX line editor'),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getPackages();

    await client.close();
  });

  test('get packages - installed', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ],
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('ed', '1.17',
                arch: 'arm64', summary: 'classic UNIX line editor')
          ]
        });
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('hello;2.10;arm64;installed'),
              summary: 'example package based on GNU hello'),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getPackages(filter: {PackageKitFilter.installed});

    await client.close();
  });

  test('resolve', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('hello;2.10;arm64;installed'),
              summary: 'example package based on GNU hello'),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.resolve(['hello']);

    await client.close();
  });

  test('search names', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('one', '1.1', arch: 'arm64', summary: '1'),
          MockPackage('two', '1.2', arch: 'arm64', summary: '2'),
          MockPackage('three', '1.3', arch: 'arm64', summary: '3')
        ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('one;1.1;arm64;installed'),
              summary: '1'),
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('two;1.2;arm64;installed'),
              summary: '2'),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.searchNames(['o']);

    await client.close();
  });

  test('search names - multiple terms', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('one', '1.1', arch: 'arm64', summary: '1'),
          MockPackage('two', '1.2', arch: 'arm64', summary: '2'),
          MockPackage('three', '1.3', arch: 'arm64', summary: '3')
        ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('two;1.2;arm64;installed'),
              summary: '2'),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.searchNames(['t', 'o']);

    await client.close();
  });

  test('download', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var summary = 'example package based on GNU hello';
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('hello', '2.10', arch: 'arm64', summary: summary)
          ]
        });
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;ubuntu-hirsute-main');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitFilesEvent(
              packageId: packageId,
              fileList: ['/var/cache/apt/archives/hello_2.10_arm64.deb']),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.downloadPackages([packageId]);

    await client.close();
  });

  test('install', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var summary = 'example package based on GNU hello';
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('hello', '2.10', arch: 'arm64', summary: summary)
          ]
        });
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;ubuntu-hirsute-main');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.downloading,
              packageId: packageId,
              summary: summary),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.download,
              percentage: 0),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.download,
              percentage: 21),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.download,
              percentage: 86),
          PackageKitPackageEvent(
              info: PackageKitInfo.finished,
              packageId: packageId,
              summary: summary),
          PackageKitPackageEvent(
              info: PackageKitInfo.preparing,
              packageId: packageId,
              summary: summary),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.setup,
              percentage: 25),
          PackageKitPackageEvent(
              info: PackageKitInfo.decompressing,
              packageId: packageId,
              summary: summary),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.setup,
              percentage: 50),
          PackageKitPackageEvent(
              info: PackageKitInfo.finished,
              packageId: packageId,
              summary: summary),
          PackageKitPackageEvent(
              info: PackageKitInfo.installing,
              packageId: packageId,
              summary: summary),
          PackageKitPackageEvent(
              info: PackageKitInfo.finished,
              packageId: packageId,
              summary: summary),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.installPackages([packageId]);

    await client.close();
  });

  test('install - not found', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit =
        MockPackageKitServer(clientAddress, transactionRuntime: 1234);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;ubuntu-hirsute-main');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitErrorCodeEvent(
              code: PackageKitError.packageNotFound,
              details: 'Package not found'),
          PackageKitFinishedEvent(exit: PackageKitExit.failed, runtime: 1234)
        ]));
    await transaction.installPackages([packageId]);

    await client.close();
  });

  test('remove', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var summary = 'example package based on GNU hello';
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;installed');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.removing,
              packageId: packageId,
              summary: summary),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.setup,
              percentage: 50),
          PackageKitItemProgressEvent(
              packageId: packageId,
              status: PackageKitStatus.remove,
              percentage: 75),
          PackageKitPackageEvent(
              info: PackageKitInfo.finished,
              packageId: packageId,
              summary: summary),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.removePackages([packageId]);

    await client.close();
  });

  test('get repository list', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        repositories: [
          MockRepository('enabled-repo1', 'Main', true),
          MockRepository('enabled-repo2', 'Updates', true),
          MockRepository('disabled-repo', 'Universe', false)
        ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitRepositoryDetailEvent(
              repoId: 'enabled-repo1', description: 'Main', enabled: true),
          PackageKitRepositoryDetailEvent(
              repoId: 'enabled-repo2', description: 'Updates', enabled: true),
          PackageKitRepositoryDetailEvent(
              repoId: 'disabled-repo', description: 'Universe', enabled: false),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getRepositoryList();

    await client.close();
  });

  test('refresh cache', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        repositories: [
          MockRepository('enabled-repo', 'Main', true),
          MockRepository('disabled-repo', 'Universe', false)
        ]);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitRepositoryDetailEvent(
              repoId: 'enabled-repo', description: 'Main', enabled: true),
          PackageKitRepositoryDetailEvent(
              repoId: 'disabled-repo', description: 'Universe', enabled: false),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.refreshCache();

    await client.close();
  });

  test('get updates', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.9',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ],
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('hello', '2.10',
                arch: 'arm64', summary: 'example package based on GNU hello')
          ]
        });
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.normal,
              packageId: PackageKitPackageId.fromString(
                  'hello;2.10;arm64;ubuntu-hirsute-main'),
              summary: 'example package based on GNU hello'),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getUpdates();

    await client.close();
  });

  test('update', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var summary = 'example package based on GNU hello';
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.9',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ],
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('hello', '2.10',
                arch: 'arm64', summary: 'example package based on GNU hello')
          ]
        });
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;ubuntu-hirsute-main');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.updating,
              packageId: packageId,
              summary: summary),
          PackageKitPackageEvent(
              info: PackageKitInfo.finished,
              packageId: packageId,
              summary: summary),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.updatePackages([packageId]);

    await client.close();
  });

  test('upgrade system', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(
      clientAddress,
      transactionRuntime: 1234,
    );
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId = PackageKitPackageId.fromString('linux;2.0;arm64;installed');
    var summary = 'Linux kernel';
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitMediaChangeRequiredEvent(
              mediaType: PackageKitMediaType.dvd,
              mediaId: 'ubuntu-21-10.iso',
              mediaText: 'Ubuntu 21.10 DVD'),
          PackageKitPackageEvent(
              info: PackageKitInfo.updating,
              packageId: packageId,
              summary: summary),
          PackageKitPackageEvent(
              info: PackageKitInfo.finished,
              packageId: packageId,
              summary: summary),
          PackageKitRequireRestartEvent(
              type: PackageKitRestart.system, packageId: packageId),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.upgradeSystem('impish', PackageKitDistroUpgrade.stable);

    await client.close();
  });
}
