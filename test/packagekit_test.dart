import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:packagekit/packagekit.dart';

const int errorPackageNotFound = 8;
const int errorRepositoryNotFound = 19;

const int exitSuccess = 1;
const int exitFailed = 2;

const int infoInstalled = 1;
const int infoAvailable = 2;
const int infoNormal = 5;
const int infoDownloading = 10;
const int infoUpdating = 11;
const int infoInstalling = 12;
const int infoRemoving = 13;
const int infoFinished = 18;
const int infoPreparing = 21;
const int infoDecompressing = 22;

const int mediaTypeDvd = 2;

const int restartSystem = 4;

const int statusSetup = 2;
const int statusRemove = 6;
const int statusDownload = 8;
const int statusInstall = 9;

const int filterInstalled = 0x4;

class MockPackageKitTransaction extends DBusObject {
  final MockPackageKitServer server;

  final int role;
  final int status;
  final String lastPackage;
  final int uid;
  final int percentage;
  final bool allowCancel;
  final bool callerActive;
  final int elapsedTime;
  final int remainingTime;
  final int speed;
  final int downloadSizeRemaining;
  final int transactionFlags;

  MockPackageKitTransaction(this.server, DBusObjectPath path,
      {this.role = 0,
      this.status = 0,
      this.lastPackage = '',
      this.uid = 0,
      this.percentage = 0,
      this.allowCancel = false,
      this.callerActive = false,
      this.elapsedTime = 0,
      this.remainingTime = 0,
      this.speed = 0,
      this.downloadSizeRemaining = 0,
      this.transactionFlags = 0})
      : super(path);

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name,
      {DBusSignature? signature}) async {
    switch (name) {
      case 'Role':
        return DBusGetPropertyResponse(DBusUint32(this.role));
      case 'Status':
        return DBusGetPropertyResponse(DBusUint32(this.status));
      case 'LastPackage':
        return DBusGetPropertyResponse(DBusString(this.lastPackage));
      case 'Uid':
        return DBusGetPropertyResponse(DBusUint32(this.uid));
      case 'Percentage':
        return DBusGetPropertyResponse(DBusUint32(this.percentage));
      case 'AllowCancel':
        return DBusGetPropertyResponse(DBusBoolean(this.allowCancel));
      case 'CallerActive':
        return DBusGetPropertyResponse(DBusBoolean(this.callerActive));
      case 'ElapsedTime':
        return DBusGetPropertyResponse(DBusUint32(this.elapsedTime));
      case 'RemainingTime':
        return DBusGetPropertyResponse(DBusUint32(this.remainingTime));
      case 'Speed':
        return DBusGetPropertyResponse(DBusUint32(this.speed));
      case 'DownloadSizeRemaining':
        return DBusGetPropertyResponse(DBusUint64(this.downloadSizeRemaining));
      case 'TransactionFlags':
        return DBusGetPropertyResponse(DBusUint64(this.transactionFlags));
      default:
        return DBusMethodErrorResponse.unknownProperty(name);
    }
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.PackageKit.Transaction') {
      return DBusMethodErrorResponse.unknownMethod();
    }

    switch (methodCall.name) {
      case 'DependsOn':
        var packageIds = methodCall.values[1].asStringArray();
        var recursive = methodCall.values[2].asBoolean();
        void findDeps(MockPackage package) {
          for (var childPackageName in package.dependsOn) {
            var p = server.findInstalledByName(childPackageName);
            if (p != null) {
              emitPackage(infoInstalled,
                  '${p.name};${p.version};${p.arch};installed', p.summary);
              if (recursive) {
                findDeps(p);
              }
            }
          }
        }
        for (var id in packageIds) {
          var package = server.findInstalled(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          findDeps(package);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'DownloadPackages':
        var packageIds = methodCall.values[1].asStringArray();
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          var packageId = PackageKitPackageId.fromString(id);
          emitFiles(id, [
            '/var/cache/apt/archives/${packageId.name}_${packageId.version}_${packageId.arch}.deb'
          ]);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetDetails':
        var packageIds = methodCall.values[0].asStringArray();
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitDetails(id,
              group: package.group,
              summary: package.summary,
              description: package.description,
              url: package.url,
              license: package.license,
              size: package.size);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetDetailsLocal':
        var paths = methodCall.values[0].asStringArray();
        for (var path in paths) {
          var package = server.findAvailableFile(path);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          var id = '${package.name};${package.version};${package.arch};+manual';
          emitDetails(id,
              group: package.group,
              summary: package.summary,
              description: package.description,
              url: package.url,
              license: package.license,
              size: package.size);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetFiles':
        var packageIds = methodCall.values[0].asStringArray();
        for (var id in packageIds) {
          var package = server.findInstalled(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitFiles(id, package.fileList);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetFilesLocal':
        var paths = methodCall.values[0].asStringArray();
        for (var path in paths) {
          var package = server.findAvailableFile(path);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          var id = '${package.name};${package.version};${package.arch};+manual';
          emitFiles(id, package.fileList);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetPackages':
        var filter = methodCall.values[0].asUint64();
        for (var p in server.installedPackages) {
          emitPackage(infoInstalled,
              '${p.name};${p.version};${p.arch};installed', p.summary);
        }
        if ((filter & filterInstalled) == 0) {
          for (var source in server.availablePackages.keys) {
            var packages = server.availablePackages[source]!;
            for (var p in packages) {
              emitPackage(infoAvailable,
                  '${p.name};${p.version};${p.arch};$source', p.summary);
            }
          }
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetRepoList':
        for (var repo in server.repositories) {
          emitRepoDetail(repo.id, repo.description, repo.enabled);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RepoEnable':
        var id = methodCall.values[0].asString();
        var enabled = methodCall.values[1].asBoolean();
        var repo = server.findRepository(id);
        if (repo == null) {
          emitErrorCode(errorRepositoryNotFound, 'Repository not found');
          emitFinished(exitFailed, server.transactionRuntime);
          return DBusMethodSuccessResponse();
        }
        repo.enabled = enabled;
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RepoSetData':
        var id = methodCall.values[0].asString();
        var parameter = methodCall.values[1].asString();
        var value = methodCall.values[2].asString();
        var repo = server.findRepository(id);
        if (repo == null) {
          emitErrorCode(errorRepositoryNotFound, 'Repository not found');
          emitFinished(exitFailed, server.transactionRuntime);
          return DBusMethodSuccessResponse();
        }
        repo.data[parameter] = value;
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RepoRemove':
        var id = methodCall.values[0].asString();
        //var flags = methodCall.values[1].asUint64();
        var autoremovePackages = methodCall.values[2].asBoolean();
        if (!server.removeRepository(id)) {
          emitErrorCode(errorRepositoryNotFound, 'Repository not found');
          emitFinished(exitFailed, server.transactionRuntime);
          return DBusMethodSuccessResponse();
        }
        if (autoremovePackages) {
          server.repositoriesRemovedPackges.add(id);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetUpdateDetail':
        var packageIds = (methodCall.values[0] as DBusArray)
            .children
            .map((value) => (value as DBusString).value);
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitUpdateDetail(id,
              updates: package.updates,
              obsoletes: package.obsoletes,
              vendorUrls: package.vendorUrls,
              bugzillaUrls: package.bugzillaUrls,
              cveUrls: package.cveUrls,
              restart: package.updateRestart,
              updateText: package.updateText,
              changelog: package.changelog,
              state: package.updateState,
              issued: package.updateIssued,
              updated: package.updateUpdated);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'GetUpdates':
        for (var package in server.installedPackages) {
          for (var source in server.availablePackages.keys) {
            var packages = server.availablePackages[source]!;
            for (var p in packages) {
              if (p.name == package.name && p.version != package.version) {
                emitPackage(infoNormal,
                    '${p.name};${p.version};${p.arch};$source', p.summary);
              }
            }
          }
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'InstallFiles':
        var paths = methodCall.values[1].asStringArray();
        for (var path in paths) {
          var package = server.findAvailableFile(path);
          if (package == null) {
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          var id = '${package.name};${package.version};${package.arch};+manual';
          emitPackage(infoPreparing, id, package.summary);
          emitPackage(infoDecompressing, id, package.summary);
          emitPackage(infoFinished, id, package.summary);
          emitPackage(infoInstalling, id, package.summary);
          emitPackage(infoFinished, id, package.summary);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'InstallPackages':
        var packageIds = methodCall.values[1].asStringArray();
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitPackage(infoDownloading, id, package.summary);
          emitItemProgress(id, statusDownload, 0);
          emitItemProgress(id, statusDownload, 21);
          emitItemProgress(id, statusDownload, 86);
          emitPackage(infoFinished, id, package.summary);
          emitPackage(infoPreparing, id, package.summary);
          emitItemProgress(id, statusSetup, 25);
          emitPackage(infoDecompressing, id, package.summary);
          emitItemProgress(id, statusSetup, 50);
          emitPackage(infoFinished, id, package.summary);
          emitPackage(infoInstalling, id, package.summary);
          emitPackage(infoFinished, id, package.summary);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RefreshCache':
        for (var repo in server.repositories) {
          emitRepoDetail(repo.id, repo.description, repo.enabled);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'RemovePackages':
        var packageIds = methodCall.values[1].asStringArray();
        for (var id in packageIds) {
          var package = server.findInstalled(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitPackage(infoRemoving, id, package.summary);
          emitItemProgress(id, statusSetup, 50);
          emitItemProgress(id, statusRemove, 75);
          emitPackage(infoFinished, id, package.summary);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'Resolve':
        var packageNames = methodCall.values[1].asStringArray();
        for (var name in packageNames) {
          for (var p in server.installedPackages) {
            if (p.name == name) {
              emitPackage(infoInstalled,
                  '${p.name};${p.version};${p.arch};installed', p.summary);
            }
          }
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'SearchFiles':
        var values = methodCall.values[1].asStringArray();
        bool fileMatches(String path) {
          for (var value in values) {
            if (value.startsWith('/')) {
              return path == value;
            } else {
              return path.split('/').last == value;
            }
          }
          return false;
        }
        for (var p in server.installedPackages) {
          for (var path in p.fileList) {
            if (fileMatches(path)) {
              emitPackage(infoInstalled,
                  '${p.name};${p.version};${p.arch};installed', p.summary);
            }
          }
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'SearchNames':
        var values = methodCall.values[1].asStringArray();
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
            emitPackage(infoInstalled,
                '${p.name};${p.version};${p.arch};installed', p.summary);
          }
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'SetHints':
        server.lastLocale = null;
        server.lastBackground = null;
        server.lastInteractive = null;
        server.lastIdle = null;
        server.lastCacheAge = null;
        var hints = methodCall.values[0].asStringArray();
        for (var hint in hints) {
          var i = hint.indexOf('=');
          if (i < 0) {
            continue;
          }
          var name = hint.substring(0, i);
          var value = hint.substring(i + 1);
          switch (name) {
            case 'locale':
              server.lastLocale = value;
              break;
            case 'background':
              server.lastBackground = value == 'true';
              break;
            case 'interactive':
              server.lastInteractive = value == 'true';
              break;
            case 'idle':
              server.lastIdle = value == 'true';
              break;
            case 'cache-age':
              server.lastCacheAge = int.parse(value);
              break;
          }
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'UpdatePackages':
        var packageIds = methodCall.values[1].asStringArray();
        for (var id in packageIds) {
          var package = server.findAvailable(id);
          if (package == null) {
            emitErrorCode(errorPackageNotFound, 'Package not found');
            emitFinished(exitFailed, server.transactionRuntime);
            return DBusMethodSuccessResponse();
          }
          emitPackage(infoUpdating, id, package.summary);
          emitPackage(infoFinished, id, package.summary);
        }
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      case 'UpgradeSystem':
        var id = 'linux;2.0;arm64;installed';
        var summary = 'Linux kernel';
        emitMediaChangeRequired(
            mediaTypeDvd, 'ubuntu-21-10.iso', 'Ubuntu 21.10 DVD');
        emitPackage(infoUpdating, id, summary);
        emitPackage(infoFinished, id, summary);
        emitRequireRestart(restartSystem, id);
        emitFinished(exitSuccess, server.transactionRuntime);
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  void emitDetails(String packageId,
      {int group = 0,
      String summary = '',
      String description = '',
      String url = '',
      String license = '',
      size = 0}) {
    var data = DBusDict.stringVariant({
      'package-id': DBusString(packageId),
      'group': DBusUint32(group),
      'summary': DBusString(summary),
      'description': DBusString(description),
      'url': DBusString(url),
      'license': DBusString(license),
      'size': DBusUint64(size)
    });
    emitSignal('org.freedesktop.PackageKit.Transaction', 'Details', [data]);
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

  void emitUpdateDetail(String packageId,
      {Iterable<String> updates = const [],
      Iterable<String> obsoletes = const [],
      Iterable<String> vendorUrls = const [],
      Iterable<String> bugzillaUrls = const [],
      Iterable<String> cveUrls = const [],
      int restart = 0,
      String updateText = '',
      String changelog = '',
      int state = 0,
      String issued = '',
      String updated = ''}) {
    emitSignal('org.freedesktop.PackageKit.Transaction', 'UpdateDetail', [
      DBusString(packageId),
      DBusArray.string(updates),
      DBusArray.string(obsoletes),
      DBusArray.string(vendorUrls),
      DBusArray.string(bugzillaUrls),
      DBusArray.string(cveUrls),
      DBusUint32(restart),
      DBusString(updateText),
      DBusString(changelog),
      DBusUint32(state),
      DBusString(issued),
      DBusString(updated)
    ]);
  }
}

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

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    List<DBusValue>? returnValues;
    if (methodCall.interface == 'org.freedesktop.PackageKit') {
      switch (methodCall.name) {
        case 'CreateTransaction':
          var transaction = await server.addTransaction();
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
  bool enabled;
  final data = <String, String>{};

  MockRepository(this.id, {this.description = '', this.enabled = true});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is MockRepository &&
        other.id == id &&
        other.description == description &&
        other.enabled == enabled &&
        collectionEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(id, description, enabled, data);
}

class MockPackage {
  final String name;
  final String version;
  final String arch;
  final int group;
  final String summary;
  final String description;
  final String url;
  final String license;
  final int size;
  final List<String> fileList;
  final List<String> dependsOn;
  final List<String> updates;
  final List<String> obsoletes;
  final List<String> vendorUrls;
  final List<String> bugzillaUrls;
  final List<String> cveUrls;
  final int updateRestart;
  final String updateText;
  final String changelog;
  final int updateState;
  final String updateIssued;
  final String updateUpdated;

  const MockPackage(this.name, this.version,
      {this.arch = '',
      this.group = 0,
      this.summary = '',
      this.description = '',
      this.url = '',
      this.license = '',
      this.size = 0,
      this.fileList = const [],
      this.updates = const [],
      this.obsoletes = const [],
      this.vendorUrls = const [],
      this.bugzillaUrls = const [],
      this.cveUrls = const [],
      this.dependsOn = const [],
      this.updateRestart = 0,
      this.updateText = '',
      this.changelog = '',
      this.updateState = 0,
      this.updateIssued = '',
      this.updateUpdated = ''});
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

  var nextTransactionId = 1;
  final int transactionRuntime;
  final List<MockRepository> repositories;
  final Map<String, List<MockPackage>> availablePackages;
  final List<MockPackage> installedPackages;
  final Map<String, MockPackage> availableFiles;

  String? lastLocale;
  bool? lastBackground;
  bool? lastInteractive;
  bool? lastIdle;
  int? lastCacheAge;
  var repositoriesRemovedPackges = <String>[];

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
      this.installedPackages = const [],
      this.availableFiles = const {}})
      : super(clientAddress);

  Future<MockPackageKitTransaction> addTransaction(
      {int role = 0,
      int status = 0,
      String lastPackage = '',
      int uid = 0,
      int percentage = 0,
      bool allowCancel = false,
      bool callerActive = false,
      int elapsedTime = 0,
      int remainingTime = 0,
      int speed = 0,
      int downloadSizeRemaining = 0,
      int transactionFlags = 0}) async {
    var path = DBusObjectPath('/Transaction$nextTransactionId');
    nextTransactionId++;
    var transaction = MockPackageKitTransaction(this, path,
        role: role,
        status: status,
        lastPackage: lastPackage,
        uid: uid,
        percentage: percentage,
        allowCancel: allowCancel,
        callerActive: callerActive,
        elapsedTime: elapsedTime,
        remainingTime: remainingTime,
        speed: speed,
        downloadSizeRemaining: downloadSizeRemaining,
        transactionFlags: transactionFlags);
    await registerObject(transaction);
    return transaction;
  }

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

  MockPackage? findInstalledByName(String name) {
    for (var package in installedPackages) {
      if (package.name == name) {
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

  MockPackage? findAvailableFile(String path) {
    return availableFiles[path];
  }

  MockRepository? findRepository(String id) {
    for (var repo in repositories) {
      if (repo.id == id) {
        return repo;
      }
    }
    return null;
  }

  bool removeRepository(String id) {
    var repo = findRepository(id);
    if (repo == null) {
      return false;
    }
    repositories.remove(repo);
    return true;
  }

  Future<void> start() async {
    await requestName('org.freedesktop.PackageKit');
    _root = MockPackageKitRoot(this);
    await registerObject(_root);
  }
}

class MockTransactionObject extends DBusRemoteObject {
  MockTransactionObject(DBusClient client,
      {required String name, required DBusObjectPath path, this.properties})
      : super(client, name: name, path: path);

  Map<String, DBusValue>? properties;

  @override
  Future<DBusValue> getProperty(String interface, String name,
      {DBusSignature? signature}) async {
    if (properties?[name] == null) {
      throw DBusUnknownPropertyException(
          DBusMethodErrorResponse.unknownProperty(name));
    }
    return properties![name]!;
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        versionMajor: 1, versionMinor: 2, versionMicro: 3);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.versionMajor, equals(1));
    expect(client.versionMinor, equals(2));
    expect(client.versionMicro, equals(3));
  });

  test('backend', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        backendName: 'aptcc',
        backendDescription: 'APTcc',
        backendAuthor: '"Testy Tester" <test@example.com>');
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.backendName, equals('aptcc'));
    expect(client.backendDescription, equals('APTcc'));
    expect(client.backendAuthor, equals('"Testy Tester" <test@example.com>'));
  });

  test('distro id', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit =
        MockPackageKitServer(clientAddress, distroId: 'ubuntu;21.04;x86_64');
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.distroId, equals('ubuntu;21.04;x86_64'));
  });

  test('locked', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, locked: true);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.locked, isTrue);
  });

  test('filters', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, filters: 0x5041154);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('groups', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, groups: 0xe8d6fcfc);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('roles', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, roles: 0x1f2fefffe);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('mime types', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, mimeTypes: [
      'application/vnd.debian.binary-package',
      'application/x-deb'
    ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.mimeTypes,
        equals(['application/vnd.debian.binary-package', 'application/x-deb']));
  });

  test('network state', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress, networkState: 2);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.networkState, equals(PackageKitNetworkState.online));
  });

  test('transaction hints', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    client.locale = 'en_NZ.utf-8';
    client.background = true;
    client.interactive = true;
    client.idle = true;
    client.cacheAge = 42;
    await client.createTransaction();
    expect(packagekit.lastLocale, equals('en_NZ.utf-8'));
    expect(packagekit.lastBackground, isTrue);
    expect(packagekit.lastInteractive, isTrue);
    expect(packagekit.lastIdle, isTrue);
    expect(packagekit.lastCacheAge, equals(42));
  });

  test('get packages', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
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
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('get packages - installed', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
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
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('resolve', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('get details', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('hello', '2.10',
                arch: 'arm64',
                summary: 'example package based on GNU hello',
                group: 22,
                description: 'description of hello',
                url: 'http://www.gnu.org/software/hello/',
                license: 'GPLv2+',
                size: 110592)
          ]
        });
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;ubuntu-hirsute-main');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitDetailsEvent(
              packageId: packageId,
              group: PackageKitGroup.programming,
              summary: 'example package based on GNU hello',
              description: 'description of hello',
              url: 'http://www.gnu.org/software/hello/',
              license: 'GPLv2+',
              size: 110592),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getDetails([packageId]);
  });

  test('get details local', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        availableFiles: {
          '/hello_2.1.0-2-ubuntu4_arm64.deb': MockPackage('hello', '2.10',
              arch: 'arm64',
              summary: 'example package based on GNU hello',
              group: 22,
              description: 'description of hello',
              url: 'http://www.gnu.org/software/hello/',
              license: 'GPLv2+',
              size: 110592)
        });
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId = PackageKitPackageId.fromString('hello;2.10;arm64;+manual');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitDetailsEvent(
              packageId: packageId,
              group: PackageKitGroup.programming,
              summary: 'example package based on GNU hello',
              description: 'description of hello',
              url: 'http://www.gnu.org/software/hello/',
              license: 'GPLv2+',
              size: 110592),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getDetailsLocal(['/hello_2.1.0-2-ubuntu4_arm64.deb']);
  });

  test('search names', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('one', '1.1', arch: 'arm64', summary: '1'),
          MockPackage('two', '1.2', arch: 'arm64', summary: '2'),
          MockPackage('three', '1.3', arch: 'arm64', summary: '3')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('search names - multiple terms', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('one', '1.1', arch: 'arm64', summary: '1'),
          MockPackage('two', '1.2', arch: 'arm64', summary: '2'),
          MockPackage('three', '1.3', arch: 'arm64', summary: '3')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('search files', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('one', '1.1', fileList: ['/usr/share/data/one.png']),
          MockPackage('two', '1.2', fileList: ['/usr/share/data/two.png']),
          MockPackage('three', '1.3', fileList: ['/usr/share/data/three.png'])
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId: PackageKitPackageId.fromString('two;1.2;;installed'),
              summary: ''),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.searchFiles(['two.png']);
  });

  test('download', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
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
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('depends on', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('parent', '1', dependsOn: ['child1', 'child2']),
          MockPackage('child1', '1.1'),
          MockPackage('child2', '1.2', dependsOn: ['grandchild']),
          MockPackage('grandchild', '1.2.1')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('child1;1.1;;installed'),
              summary: ''),
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('child2;1.2;;installed'),
              summary: ''),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction
        .dependsOn([PackageKitPackageId.fromString('parent;1;;installed')]);
  });

  test('depends on - recursive', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('parent', '1', dependsOn: ['child1', 'child2']),
          MockPackage('child1', '1.1'),
          MockPackage('child2', '1.2', dependsOn: ['grandchild']),
          MockPackage('grandchild', '1.2.1')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('child1;1.1;;installed'),
              summary: ''),
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('child2;1.2;;installed'),
              summary: ''),
          PackageKitPackageEvent(
              info: PackageKitInfo.installed,
              packageId:
                  PackageKitPackageId.fromString('grandchild;1.2.1;;installed'),
              summary: ''),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.dependsOn(
        [PackageKitPackageId.fromString('parent;1;;installed')],
        recursive: true);
  });

  test('install', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
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
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('install - not found', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit =
        MockPackageKitServer(clientAddress, transactionRuntime: 1234);
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('install files', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var summary = 'example package based on GNU hello';
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        availableFiles: {
          '/hello_2.1.0-2-ubuntu4_arm64.deb':
              MockPackage('hello', '2.10', arch: 'arm64', summary: summary)
        });
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId = PackageKitPackageId.fromString('hello;2.10;arm64;+manual');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitPackageEvent(
              info: PackageKitInfo.preparing,
              packageId: packageId,
              summary: summary),
          PackageKitPackageEvent(
              info: PackageKitInfo.decompressing,
              packageId: packageId,
              summary: summary),
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
    await transaction.installFiles(['/hello_2.1.0-2-ubuntu4_arm64.deb']);
  });

  test('remove', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var summary = 'example package based on GNU hello';
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64', summary: 'example package based on GNU hello')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('get files', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.10',
              arch: 'arm64',
              fileList: ['/usr/bin/hello', '/usr/share/man/man1/hello.1.gz'])
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId =
        PackageKitPackageId.fromString('hello;2.10;arm64;installed');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitFilesEvent(
              packageId: packageId,
              fileList: ['/usr/bin/hello', '/usr/share/man/man1/hello.1.gz']),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getFiles([packageId]);
  });

  test('get files local', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        availableFiles: {
          '/hello_2.1.0-2-ubuntu4_arm64.deb': MockPackage('hello', '2.10',
              arch: 'arm64',
              fileList: ['/usr/bin/hello', '/usr/share/man/man1/hello.1.gz'])
        });
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    var packageId = PackageKitPackageId.fromString('hello;2.10;arm64;+manual');
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitFilesEvent(
              packageId: packageId,
              fileList: ['/usr/bin/hello', '/usr/share/man/man1/hello.1.gz']),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getFilesLocal(['/hello_2.1.0-2-ubuntu4_arm64.deb']);
  });

  test('get repository list', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        repositories: [
          MockRepository('enabled-repo1', description: 'Main', enabled: true),
          MockRepository('enabled-repo2',
              description: 'Updates', enabled: true),
          MockRepository('disabled-repo',
              description: 'Universe', enabled: false)
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('enable repository', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var repo = MockRepository('repo1', enabled: false);
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234, repositories: [repo]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.setRepositoryEnabled('repo1', true);
    expect(repo.enabled, isTrue);
  });

  test('set repository data', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var repo = MockRepository('repo1', enabled: false);
    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234, repositories: [repo]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.setRepositoryData('repo1', 'name', 'value');
    expect(repo.data, equals({'name': 'value'}));
  });

  test('remove repository', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        repositories: [
          MockRepository('repo1'),
          MockRepository('repo2'),
          MockRepository('repo3')
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.removeRepository('repo2');
    expect(packagekit.repositories,
        equals([MockRepository('repo1'), MockRepository('repo3')]));

    await transaction.removeRepository('repo1', autoremovePackages: true);
    expect(packagekit.repositories, equals([MockRepository('repo3')]));
    expect(packagekit.repositoriesRemovedPackges, equals(['repo1']));
  });

  test('refresh cache', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        repositories: [
          MockRepository('enabled-repo', description: 'Main', enabled: true),
          MockRepository('disabled-repo',
              description: 'Universe', enabled: false)
        ]);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('get update detail', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(clientAddress,
        transactionRuntime: 1234,
        installedPackages: [
          MockPackage('hello', '2.9', arch: 'arm64')
        ],
        availablePackages: {
          'ubuntu-hirsute-main': [
            MockPackage('hello', '2.10',
                arch: 'arm64',
                updates: ['hello-child;1.3;arm64;ubuntu-hirsute-main'],
                obsoletes: ['old-hello;1.0;arm64;ubuntu-hirsute-main'],
                vendorUrls: ['https://example.com/update1'],
                bugzillaUrls: ['https://issues.example.com/issue1'],
                cveUrls: ['https://cve.org/cve1'],
                updateRestart: 2,
                updateText: 'UPDATE-TEXT',
                changelog: 'CHANGELOG',
                updateState: 3,
                updateIssued: '2022-06-07T11:23:00Z',
                updateUpdated: '2022-06-09T11:23:00Z')
          ]
        });
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var transaction = await client.createTransaction();
    expect(
        transaction.events,
        emitsInOrder([
          PackageKitUpdateDetailEvent(
              packageId: PackageKitPackageId.fromString(
                  'hello;2.10;arm64;ubuntu-hirsute-main'),
              updates: [
                PackageKitPackageId.fromString(
                    'hello-child;1.3;arm64;ubuntu-hirsute-main')
              ],
              obsoletes: [
                PackageKitPackageId.fromString(
                    'old-hello;1.0;arm64;ubuntu-hirsute-main')
              ],
              vendorUrls: ['https://example.com/update1'],
              bugzillaUrls: ['https://issues.example.com/issue1'],
              cveUrls: ['https://cve.org/cve1'],
              restart: PackageKitRestart.application,
              updateText: 'UPDATE-TEXT',
              changelog: 'CHANGELOG',
              state: PackageKitUpdateState.testing,
              issued: DateTime.utc(2022, 6, 7, 11, 23),
              updated: DateTime.utc(2022, 6, 9, 11, 23)),
          PackageKitFinishedEvent(exit: PackageKitExit.success, runtime: 1234)
        ]));
    await transaction.getUpdateDetail([
      PackageKitPackageId.fromString('hello;2.10;arm64;ubuntu-hirsute-main')
    ]);
  });

  test('get updates', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
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
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('update', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
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
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('upgrade system', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var packagekit = MockPackageKitServer(
      clientAddress,
      transactionRuntime: 1234,
    );
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var client = PackageKitClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
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
  });

  test('get transaction properties', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    var packagekit = MockPackageKitServer(clientAddress);
    var t = await packagekit.addTransaction(
        role: 3,
        status: 5,
        lastPackage: 'hal;0.1.2;i386;fedora',
        uid: 1000,
        percentage: 42,
        allowCancel: true,
        callerActive: false,
        elapsedTime: 12345,
        remainingTime: 54321,
        speed: 299792458,
        downloadSizeRemaining: 3000000000,
        transactionFlags: 7);
    addTearDown(() async => await packagekit.close());
    await packagekit.start();

    var transaction = PackageKitTransaction(DBusClient(clientAddress), t.path);

    expect(await transaction.getRole(), equals(PackageKitRole.getDetails));
    expect(await transaction.getStatus(), equals(PackageKitStatus.info));
    expect(await transaction.getLastPackage(), equals('hal;0.1.2;i386;fedora'));
    expect(await transaction.getUid(), equals(1000));
    expect(await transaction.getPercentage(), equals(42));
    expect(await transaction.getAllowCancel(), equals(true));
    expect(await transaction.getCallerActive(), equals(false));
    expect(await transaction.getElapsedTime(), equals(12345));
    expect(await transaction.getRemainingTime(), equals(54321));
    expect(await transaction.getSpeed(), equals(299792458));
    expect(await transaction.getDownloadSizeRemaining(), equals(3000000000));
    expect(
        await transaction.getTransactionFlags(),
        equals({
          PackageKitTransactionFlag.onlyTrusted,
          PackageKitTransactionFlag.simulate,
          PackageKitTransactionFlag.onlyDownload,
        }));
  });
}
