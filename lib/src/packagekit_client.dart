import 'dart:async';

import 'package:dbus/dbus.dart';

/// D-Bus interface names.
const _packageKitBusName = 'org.freedesktop.PackageKit';
const _packageKitInterfaceName = 'org.freedesktop.PackageKit';
const _packageKitTransactionInterfaceName =
    'org.freedesktop.PackageKit.Transaction';

enum PackageKitDistroUpgrade { unknown, stable, unstable }

enum PackageKitError {
  unknown,
  outOfMemory,
  noNetwork,
  notSupported,
  internalError,
  gpgFailure,
  packageIdInvalid,
  packageNotInstalled,
  packageNotFound,
  packageAlreadyInstalled,
  packageDownloadFailed,
  groupNotFound,
  groupListInvalid,
  dependencyResolutionFailed,
  filterInvalid,
  createThreadFailed,
  transactionError,
  transactionCancelled,
  noCache,
  repositoryNotFound,
  cannotRemoveSystemPackage,
  processKill,
  failedInitialization,
  failedFinalize,
  failedConfigParsing,
  cannotCancel,
  cannotGetLock,
  noPackagesToUpdate,
  cannotWriteRepositoryConfig,
  localInstallFailed,
  badGpgSignature,
  missingGpgSignature,
  cannotInstallSourcePackage,
  repositoryConfigurationError,
  noLicenseAgreement,
  fileConflicts,
  packageConflicts,
  repositoryNotAvailable,
  invalidPackageFile,
  packageInstallBlocked,
  packageCorrupt,
  allPackagesAlreadyInstalled,
  fileNotFound,
  noMoreMirrorsToTry,
  noDistroUpgradeData,
  incompatibleArchitecture,
  noSpaceOnDevice,
  mediaChangeRequired,
  notAuthorized,
  updateNotFound,
  cannotInstallRepositoryUnsigned,
  cannotUpdateRepositoryUnsigned,
  cannotGetFileList,
  cannotGetRequires,
  cannotDisableRepository,
  restrictedDownload,
  packageFailedToConfigure,
  packageFailedToBuild,
  packageFailedToInstall,
  packageFailedToRemove,
  updateFailedDueToRunningProcess,
  packageDatabaseChanged,
  provideTypeNotSupported,
  installRootInvalid,
  cannotFetchSources,
  cancelledPriority,
  unfinishedTransaction,
  lockRequired,
  repositoryAlreadySet
}

enum PackageKitExit {
  unknown,
  success,
  failed,
  cancelled,
  keyRequired,
  eulaRequired,
  killed,
  mediaChangeRequired,
  needUntrusted,
  cancelledPriority,
  skipTransaction,
  repairRequired
}

enum PackageKitFilter {
  unknown,
  none,
  installed,
  notInstalled,
  development,
  notDevelopment,
  gui,
  notGui,
  free,
  notFree,
  visible,
  notVisible,
  supported,
  notSupported,
  baseName,
  notBaseName,
  newest,
  notNewest,
  arch,
  notArch,
  source,
  notSource,
  collections,
  notCollections,
  application,
  notApplication,
  downloaded,
  notDownloaded
}

Set<PackageKitFilter> _decodeFilters(int mask) {
  var filters = <PackageKitFilter>{};
  for (var value in PackageKitFilter.values) {
    if ((mask & (1 << value.index)) != 0) {
      filters.add(value);
    }
  }
  return filters;
}

int _encodeFilters(Set<PackageKitFilter> filter) {
  var value = 0;
  for (var f in filter) {
    value |= 1 << f.index;
  }
  return value;
}

enum PackageKitGroup {
  unknown,
  accessibility,
  accessories,
  adminTools,
  communication,
  desktopGnome,
  desktopKde,
  desktopOther,
  desktopXfce,
  education,
  fonts,
  games,
  graphics,
  internet,
  legacy,
  localization,
  maps,
  multimedia,
  network,
  office,
  other,
  powerManagement,
  programming,
  publishing,
  repos,
  security,
  servers,
  system,
  virtualization,
  science,
  documentation,
  electronics,
  collections,
  vendor,
  newest
}

Set<PackageKitGroup> _decodeGroups(int mask) {
  var groups = <PackageKitGroup>{};
  for (var value in PackageKitGroup.values) {
    if ((mask & (1 << value.index)) != 0) {
      groups.add(value);
    }
  }
  return groups;
}

enum PackageKitInfo {
  unknown,
  installed,
  available,
  low,
  enhancement,
  normal,
  bugfix,
  important,
  security,
  blocked,
  downloading,
  updating,
  installing,
  removing,
  cleanup,
  obsoleting,
  collectionInstalled,
  collectionAvailable,
  finished,
  reinstalling,
  downgrading,
  preparing,
  decompressing,
  untrusted,
  trusted,
  unavailable
}

enum PackageKitMediaType { unknown, cd, dvd, disc }

enum PackageKitNetworkState { unknown, offline, online, wired, wifi, mobile }

enum PackageKitRole {
  unknown,
  cancel,
  dependsOn,
  getDetails,
  getFiles,
  getPackages,
  getRepositoryList,
  requiredBy,
  getUpdateDetail,
  getUpdates,
  installFiles,
  installPackages,
  installSignature,
  refreshCache,
  removePackages,
  repoEnable,
  repoSetData,
  resolve,
  searchDetails,
  searchFile,
  searchGroup,
  searchName,
  updatePackages,
  whatProvides,
  acceptEula,
  downloadPackages,
  getDistroUpgrades,
  getCategories,
  getOldTransactions,
  repairSystem,
  getDetailsLocal,
  getFilesLocal,
  repoRemove,
  upgradeSystem
}

Set<PackageKitRole> _decodeRoles(int mask) {
  var roles = <PackageKitRole>{};
  for (var value in PackageKitRole.values) {
    if ((mask & (1 << value.index)) != 0) {
      roles.add(value);
    }
  }
  return roles;
}

enum PackageKitRestart {
  unknown,
  none,
  application,
  session,
  system,
  securitySession,
  securitySystem
}

enum PackageKitStatus {
  unknown,
  wait,
  setup,
  running,
  query,
  info,
  remove,
  refreshCache,
  download,
  install,
  update,
  cleanup,
  obsolete,
  dependencyResolve,
  signatureCheck,
  testCommit,
  commit,
  request,
  finished,
  cancel,
  downloadRepository,
  downloadPackageList,
  downloadFileList,
  downloadChangelog,
  downloadGroup,
  downloadUpdateInfo,
  repackaging,
  loadingCache,
  scanApplications,
  generatePackageList,
  waitingForLock,
  waitingForAuth,
  scanProcessList,
  checkExecutableFiles,
  checkLibraries,
  copyFiles,
  runHook
}

enum PackageKitTransactionFlag {
  onlyTrusted,
  simulate,
  onlyDownload,
  allowReinstall,
  justReinstall,
  allowDowngrade
}

int _encodeTransactionFlags(Set<PackageKitTransactionFlag> flags) {
  var value = 0;
  for (var f in flags) {
    value |= 1 << f.index;
  }
  return value;
}

class PackageKitPackageId {
  final String name;
  final String version;
  final String arch;
  final String data;

  const PackageKitPackageId(
      {required this.name,
      required this.version,
      this.arch = '',
      this.data = ''});

  factory PackageKitPackageId.fromString(String value) {
    var tokens = value.split(';');
    if (tokens.length != 4) {
      throw FormatException('Invalid number of components in Package ID');
    }

    return PackageKitPackageId(
        name: tokens[0], version: tokens[1], arch: tokens[2], data: tokens[3]);
  }

  @override
  bool operator ==(other) =>
      other is PackageKitPackageId &&
      other.name == name &&
      other.version == version &&
      other.arch == arch &&
      other.data == data;

  @override
  String toString() {
    return '$name;$version;$arch;$data';
  }
}

class PackageKitEvent {
  const PackageKitEvent();
}

class PackageKitUnknownEvent extends PackageKitEvent {
  final String name;
  final List<DBusValue> values;

  PackageKitUnknownEvent(this.name, this.values);

  @override
  String toString() => "$runtimeType('$name', $values)";
}

class PackageKitDestroyEvent extends PackageKitEvent {
  const PackageKitDestroyEvent();

  @override
  String toString() => '$runtimeType()';
}

class PackageKitFilesEvent extends PackageKitEvent {
  final PackageKitPackageId packageId;
  final List<String> fileList;

  PackageKitFilesEvent({required this.packageId, required this.fileList});

  @override
  bool operator ==(other) =>
      other is PackageKitFilesEvent &&
      other.packageId == packageId &&
      _listsEqual(other.fileList, fileList);

  @override
  String toString() =>
      "$runtimeType(packageId: '$packageId', fileList: $fileList)";
}

class PackageKitErrorCodeEvent extends PackageKitEvent {
  final PackageKitError code;
  final String details;

  const PackageKitErrorCodeEvent({required this.code, required this.details});

  @override
  bool operator ==(other) =>
      other is PackageKitErrorCodeEvent &&
      other.code == code &&
      other.details == details;

  @override
  String toString() => "$runtimeType(code: $code, details: '$details')";
}

class PackageKitFinishedEvent extends PackageKitEvent {
  final PackageKitExit exit;
  final int runtime;

  const PackageKitFinishedEvent({required this.exit, required this.runtime});

  @override
  bool operator ==(other) =>
      other is PackageKitFinishedEvent &&
      other.exit == exit &&
      other.runtime == runtime;

  @override
  String toString() => '$runtimeType(exit: $exit, runtime: $runtime)';
}

class PackageKitItemProgressEvent extends PackageKitEvent {
  final PackageKitPackageId packageId;
  final PackageKitStatus status;
  final int percentage;

  const PackageKitItemProgressEvent(
      {required this.packageId,
      required this.status,
      required this.percentage});

  @override
  bool operator ==(other) =>
      other is PackageKitItemProgressEvent &&
      other.packageId == packageId &&
      other.status == status &&
      other.percentage == percentage;

  @override
  String toString() =>
      "PackageKitItemProgressEvent(packageId: '$packageId', status: $status, percentage: $percentage)";
}

class PackageKitMediaChangeRequiredEvent extends PackageKitEvent {
  final PackageKitMediaType mediaType;
  final String mediaId;
  final String mediaText;

  const PackageKitMediaChangeRequiredEvent(
      {required this.mediaType,
      required this.mediaId,
      required this.mediaText});

  @override
  bool operator ==(other) =>
      other is PackageKitMediaChangeRequiredEvent &&
      other.mediaType == mediaType &&
      other.mediaId == mediaId &&
      other.mediaText == mediaText;

  @override
  String toString() =>
      "PackageKitMediaChangeRequiredEvent(mediaType: $mediaType, mediaId: '$mediaId', mediaText: '$mediaText')";
}

class PackageKitPackageEvent extends PackageKitEvent {
  final PackageKitInfo info;
  final PackageKitPackageId packageId;
  final String summary;

  const PackageKitPackageEvent(
      {required this.info, required this.packageId, required this.summary});

  @override
  bool operator ==(other) =>
      other is PackageKitPackageEvent &&
      other.info == info &&
      other.packageId == packageId &&
      other.summary == summary;

  @override
  String toString() =>
      "$runtimeType(info: $info, packageId: '$packageId', summary: '$summary')";
}

class PackageKitRepositoryDetailEvent extends PackageKitEvent {
  final String repoId;
  final String description;
  final bool enabled;

  const PackageKitRepositoryDetailEvent(
      {required this.repoId, required this.description, required this.enabled});

  @override
  bool operator ==(other) =>
      other is PackageKitRepositoryDetailEvent &&
      other.repoId == repoId &&
      other.description == description &&
      other.enabled == enabled;

  @override
  String toString() =>
      "$runtimeType(repoId: '$repoId', description: '$description', enabled: $enabled)";
}

class PackageKitRequireRestartEvent extends PackageKitEvent {
  final PackageKitRestart type;
  final PackageKitPackageId packageId;

  const PackageKitRequireRestartEvent(
      {required this.type, required this.packageId});

  @override
  bool operator ==(other) =>
      other is PackageKitRequireRestartEvent &&
      other.type == type &&
      other.packageId == packageId;

  @override
  String toString() => "$runtimeType(type: $type, packageId: '$packageId')";
}

/// A PackageKit transaction.
class PackageKitTransaction {
  /// Remote transaction object.
  final DBusRemoteObject _object;

  late final Stream<PackageKitEvent> events;

  PackageKitTransaction(DBusClient bus, DBusObjectPath objectPath)
      : _object = DBusRemoteObject(bus, _packageKitBusName, objectPath) {
    events = DBusSignalStream(bus,
            sender: _packageKitBusName,
            interface: _packageKitTransactionInterfaceName,
            path: objectPath)
        .map((signal) {
      switch (signal.name) {
        case 'Destroy':
          if (signal.signature != DBusSignature('')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitDestroyEvent();
        case 'ErrorCode':
          if (signal.signature != DBusSignature('us')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitErrorCodeEvent(
              code: PackageKitError
                  .values[(signal.values[0] as DBusUint32).value],
              details: (signal.values[1] as DBusString).value);
        case 'Files':
          if (signal.signature != DBusSignature('sas')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitFilesEvent(
              packageId: PackageKitPackageId.fromString(
                  (signal.values[0] as DBusString).value),
              fileList: (signal.values[1] as DBusArray)
                  .children
                  .map((value) => (value as DBusString).value)
                  .toList());
        case 'Finished':
          if (signal.signature != DBusSignature('uu')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitFinishedEvent(
              exit:
                  PackageKitExit.values[(signal.values[0] as DBusUint32).value],
              runtime: (signal.values[1] as DBusUint32).value);
        case 'ItemProgress':
          if (signal.signature != DBusSignature('suu')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitItemProgressEvent(
              packageId: PackageKitPackageId.fromString(
                  (signal.values[0] as DBusString).value),
              status: PackageKitStatus
                  .values[(signal.values[1] as DBusUint32).value],
              percentage: (signal.values[2] as DBusUint32).value);
        case 'MediaChangeRequired':
          if (signal.signature != DBusSignature('uss')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitMediaChangeRequiredEvent(
              mediaType: PackageKitMediaType
                  .values[(signal.values[0] as DBusUint32).value],
              mediaId: (signal.values[1] as DBusString).value,
              mediaText: (signal.values[2] as DBusString).value);
        case 'Package':
          if (signal.signature != DBusSignature('uss')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitPackageEvent(
              info:
                  PackageKitInfo.values[(signal.values[0] as DBusUint32).value],
              packageId: PackageKitPackageId.fromString(
                  (signal.values[1] as DBusString).value),
              summary: (signal.values[2] as DBusString).value);
        case 'RepoDetail':
          if (signal.signature != DBusSignature('ssb')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitRepositoryDetailEvent(
              repoId: (signal.values[0] as DBusString).value,
              description: (signal.values[1] as DBusString).value,
              enabled: (signal.values[2] as DBusBoolean).value);
        case 'RequireRestart':
          if (signal.signature != DBusSignature('us')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitRequireRestartEvent(
              type: PackageKitRestart
                  .values[(signal.values[0] as DBusUint32).value],
              packageId: PackageKitPackageId.fromString(
                  (signal.values[1] as DBusString).value));
        default:
          return PackageKitUnknownEvent(signal.name, signal.values);
      }
    });
  }

  Future<void> cancel() async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'Cancel', [],
        replySignature: DBusSignature(''));
  }

  Future<void> downloadPackages(Iterable<PackageKitPackageId> packageIds,
      {bool storeInCache = false}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'DownloadPackages',
        [
          DBusBoolean(storeInCache),
          DBusArray.string(packageIds.map((id) => id.toString()))
        ],
        replySignature: DBusSignature(''));
  }

  Future<void> getFiles(Iterable<PackageKitPackageId> packageIds) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetFiles',
        [DBusArray.string(packageIds.map((id) => id.toString()))],
        replySignature: DBusSignature(''));
  }

  Future<void> getPackages({Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetPackages',
        [DBusUint64(_encodeFilters(filter))],
        replySignature: DBusSignature(''));
  }

  Future<void> getRepositoryList(
      {Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetRepoList',
        [DBusUint64(_encodeFilters(filter))],
        replySignature: DBusSignature(''));
  }

  Future<void> getUpdates({Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetUpdates',
        [DBusUint64(_encodeFilters(filter))],
        replySignature: DBusSignature(''));
  }

  Future<void> installPackages(Iterable<PackageKitPackageId> packageIds,
      {Set<PackageKitTransactionFlag> transactionFlags = const {}}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'InstallPackages',
        [
          DBusUint64(_encodeTransactionFlags(transactionFlags)),
          DBusArray.string(packageIds.map((id) => id.toString()))
        ],
        replySignature: DBusSignature(''));
  }

  Future<void> refreshCache({bool force = false}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName,
        'RefreshCache', [DBusBoolean(force)],
        replySignature: DBusSignature(''));
  }

  Future<void> removePackages(Iterable<PackageKitPackageId> packageIds,
      {Set<PackageKitTransactionFlag> transactionFlags = const {},
      bool allowDeps = false,
      bool autoremove = false}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'RemovePackages',
        [
          DBusUint64(_encodeTransactionFlags(transactionFlags)),
          DBusArray.string(packageIds.map((id) => id.toString())),
          DBusBoolean(allowDeps),
          DBusBoolean(autoremove)
        ],
        replySignature: DBusSignature(''));
  }

  Future<void> resolve(Iterable<String> packages,
      {Set<PackageKitTransactionFlag> transactionFlags = const {}}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'Resolve',
        [
          DBusUint64(_encodeTransactionFlags(transactionFlags)),
          DBusArray.string(packages)
        ],
        replySignature: DBusSignature(''));
  }

  Future<void> searchNames(Iterable<String> values,
      {Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'SearchNames',
        [DBusUint64(_encodeFilters(filter)), DBusArray.string(values)],
        replySignature: DBusSignature(''));
  }

  Future<void> updatePackages(Iterable<PackageKitPackageId> packageIds,
      {Set<PackageKitTransactionFlag> transactionFlags = const {}}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'UpdatePackages',
        [
          DBusUint64(_encodeTransactionFlags(transactionFlags)),
          DBusArray.string(packageIds.map((id) => id.toString()))
        ],
        replySignature: DBusSignature(''));
  }

  Future<void> upgradeSystem(
      String distroId, PackageKitDistroUpgrade upgradeKind,
      {Set<PackageKitTransactionFlag> transactionFlags = const {}}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'UpgradeSystem',
        [
          DBusUint64(_encodeTransactionFlags(transactionFlags)),
          DBusString(distroId),
          DBusUint32(upgradeKind.index)
        ],
        replySignature: DBusSignature(''));
  }
}

/// A client that connects to PackageKit.
class PackageKitClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// The root D-Bus PackageKit object.
  late final DBusRemoteObject _root;

  /// Properties on the root object.
  final _properties = <String, DBusValue>{};

  String get backendAuthor =>
      (_properties['BackendAuthor'] as DBusString).value;
  String get backendDescription =>
      (_properties['BackendDescription'] as DBusString).value;
  String get backendName => (_properties['BackendName'] as DBusString).value;
  String get distroId => (_properties['DistroId'] as DBusString).value;
  Set<PackageKitFilter> get filters =>
      _decodeFilters((_properties['Filters'] as DBusUint64).value);
  Set<PackageKitGroup> get groups =>
      _decodeGroups((_properties['Groups'] as DBusUint64).value);
  bool get locked => (_properties['Locked'] as DBusBoolean).value;
  List<String> get mimeTypes => (_properties['MimeTypes'] as DBusArray)
      .children
      .map((value) => (value as DBusString).value)
      .toList();
  Set<PackageKitRole> get roles =>
      _decodeRoles((_properties['Roles'] as DBusUint64).value);
  PackageKitNetworkState get networkState => PackageKitNetworkState
      .values[(_properties['NetworkState'] as DBusUint32).value];
  int get versionMajor => (_properties['VersionMajor'] as DBusUint32).value;
  int get versionMinor => (_properties['VersionMinor'] as DBusUint32).value;
  int get versionMicro => (_properties['VersionMicro'] as DBusUint32).value;

  /// Creates a new PackageKit client connected to the system D-Bus.
  PackageKitClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root = DBusRemoteObject(_bus, _packageKitBusName,
        DBusObjectPath('/org/freedesktop/PackageKit'));
  }

  /// Connects to the PackageKit daemon.
  Future<void> connect() async {
    _properties.addAll(await _root.getAllProperties(_packageKitInterfaceName));
  }

  Future<PackageKitTransaction> createTransaction() async {
    var result = await _root.callMethod(
        _packageKitInterfaceName, 'CreateTransaction', [],
        replySignature: DBusSignature('o'));
    return PackageKitTransaction(
        _bus, result.returnValues[0] as DBusObjectPath);
  }

  /// Terminates the connection to the PackageKit daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
