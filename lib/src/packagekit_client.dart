import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';

/// D-Bus interface names.
const _packageKitBusName = 'org.freedesktop.PackageKit';
const _packageKitInterfaceName = 'org.freedesktop.PackageKit';
const _packageKitTransactionInterfaceName =
    'org.freedesktop.PackageKit.Transaction';

DateTime? _decodeDateTime(String value) =>
    value != '' ? DateTime.parse(value) : null;

/// The type of distribution upgrade, as used in [PackageKitTransaction.upgradeSystem].
enum PackageKitDistroUpgrade { unknown, stable, unstable }

/// Errors returned by the PackageKit daemon.
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

/// The exit status of a [PackageKitTransaction].
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

/// Filters used to query packages.
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

/// Groups a package belongs to.
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

PackageKitGroup _decodeGroup(int value) {
  return value >= 0 && value < PackageKitGroup.values.length
      ? PackageKitGroup.values[value]
      : PackageKitGroup.unknown;
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

/// Information about a package, as returned in [PackageKitPackageEvent].
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

/// Type of media containing packages.
enum PackageKitMediaType { unknown, cd, dvd, disc }

/// State of the network.
enum PackageKitNetworkState { unknown, offline, online, wired, wifi, mobile }

/// Roles a backend supports.
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

/// Type of restart required in a [PackageKitRequireRestartEvent].
enum PackageKitRestart {
  unknown,
  none,
  application,
  session,
  system,
  securitySession,
  securitySystem
}

PackageKitRestart _decodeRestart(int value) =>
    value < PackageKitRestart.values.length
        ? PackageKitRestart.values[value]
        : PackageKitRestart.unknown;

/// Status of a [PackageKitItemProgressEvent].
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

/// Flags passed to methods on [PackageKitTransaction].
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

Set<PackageKitTransactionFlag> _decodeTransactionFlags(int value) {
  var flags = <PackageKitTransactionFlag>{};
  for (var f in PackageKitTransactionFlag.values) {
    if ((1 << f.index) & value != 0) {
      flags.add(f);
    }
  }
  return flags;
}

/// The state of an update.
enum PackageKitUpdateState { unknown, stable, unstable, testing }

PackageKitUpdateState _decodeUpdateState(int value) =>
    value >= 0 && value < PackageKitUpdateState.values.length
        ? PackageKitUpdateState.values[value]
        : PackageKitUpdateState.unknown;

/// An ID that uniquely identifies a package.
class PackageKitPackageId {
  /// The name of the package, e.g. "zenity".
  final String name;

  /// The version of the package, e.g. "1.2.3".
  final String version;

  /// The architecture of the package, e.g. "amd64".
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
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitPackageId &&
        other.name == name &&
        other.version == version &&
        other.arch == arch &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(name, version, arch, data);

  @override
  String toString() {
    return '$name;$version;$arch;$data';
  }
}

/// An event received from the backend.
class PackageKitEvent {
  const PackageKitEvent();
}

/// An unknown event received from the backend.
class PackageKitUnknownEvent extends PackageKitEvent {
  /// The name of the event.
  final String name;

  /// Information with the event.
  final List<DBusValue> values;

  PackageKitUnknownEvent(this.name, this.values);

  @override
  String toString() => "$runtimeType('$name', $values)";
}

/// An event from the backend to give details about a package.
class PackageKitDetailsEvent extends PackageKitEvent {
  /// The ID of the package this event relates to.
  final PackageKitPackageId packageId;

  /// The group this package belongs to.
  final PackageKitGroup group;

  /// The one line package summary, e.g. "Clipart for OpenOffice"
  final String summary;

  ///The multi-line package description in markdown syntax.
  final String description;

  /// The upstream project homepage.
  final String url;

  /// The license string, e.g. GPLv2+
  final String license;

  /// The size of the package in bytes.
  final int size;

  PackageKitDetailsEvent(
      {required this.packageId,
      this.group = PackageKitGroup.unknown,
      this.summary = '',
      this.description = '',
      this.url = '',
      this.license = '',
      this.size = 0});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitDetailsEvent &&
        other.packageId == packageId &&
        other.group == group &&
        other.summary == summary &&
        other.description == description &&
        other.url == url &&
        other.license == license &&
        other.size == size;
  }

  @override
  int get hashCode =>
      Object.hash(packageId, group, summary, description, url, license, size);

  @override
  String toString() =>
      '$runtimeType(packageId: $packageId, group: $group, summary: $summary, description: $description, url: $url, license: $license, size: $size)';
}

/// And event when a [PackageKitTransaction] is complete.
class PackageKitDestroyEvent extends PackageKitEvent {
  const PackageKitDestroyEvent();

  @override
  String toString() => '$runtimeType()';
}

/// An event from the backend to pass a file list.
class PackageKitFilesEvent extends PackageKitEvent {
  /// The ID of the package this event relates to.
  final PackageKitPackageId packageId;

  /// List of filenames.
  final List<String> fileList;

  PackageKitFilesEvent({required this.packageId, required this.fileList});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is PackageKitFilesEvent &&
        other.packageId == packageId &&
        listEquals(other.fileList, fileList);
  }

  @override
  int get hashCode => Object.hash(packageId, Object.hashAll(fileList));

  @override
  String toString() =>
      "$runtimeType(packageId: '$packageId', fileList: $fileList)";
}

/// An event from the backend to indicate an error occurred.
class PackageKitErrorCodeEvent extends PackageKitEvent {
  /// The type of error.
  final PackageKitError code;

  /// Long description of error, e.g. "failed to download package".
  final String details;

  const PackageKitErrorCodeEvent({required this.code, required this.details});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitErrorCodeEvent &&
        other.code == code &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(code, details);

  @override
  String toString() => "$runtimeType(code: $code, details: '$details')";
}

/// An event from the backend to indicate the transaction has finished.
class PackageKitFinishedEvent extends PackageKitEvent {
  /// The exit status of the transaction.
  final PackageKitExit exit;

  /// The amount of time in milliseconds that the transaction ran for.
  final int runtime;

  const PackageKitFinishedEvent({required this.exit, required this.runtime});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitFinishedEvent &&
        other.exit == exit &&
        other.runtime == runtime;
  }

  @override
  int get hashCode => Object.hash(exit, runtime);

  @override
  String toString() => '$runtimeType(exit: $exit, runtime: $runtime)';
}

/// An event from the backend to update the progress of the transaction.
class PackageKitItemProgressEvent extends PackageKitEvent {
  /// The ID of the package this event relates to.
  final PackageKitPackageId packageId;

  /// The status of the package.
  final PackageKitStatus status;

  /// The percentage of this package action is completed.
  final int percentage;

  const PackageKitItemProgressEvent(
      {required this.packageId,
      required this.status,
      required this.percentage});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitItemProgressEvent &&
        other.packageId == packageId &&
        other.status == status &&
        other.percentage == percentage;
  }

  @override
  int get hashCode => Object.hash(packageId, status, percentage);

  @override
  String toString() =>
      "PackageKitItemProgressEvent(packageId: '$packageId', status: $status, percentage: $percentage)";
}

/// An event from the backend to indicate a media change is required to get packages.
class PackageKitMediaChangeRequiredEvent extends PackageKitEvent {
  /// The type of media required.
  final PackageKitMediaType mediaType;

  /// An ID to indicate which media is required.
  final String mediaId;

  /// A label that is on the media, e.g. "Fedora Disk 1".
  final String mediaText;

  const PackageKitMediaChangeRequiredEvent(
      {required this.mediaType,
      required this.mediaId,
      required this.mediaText});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitMediaChangeRequiredEvent &&
        other.mediaType == mediaType &&
        other.mediaId == mediaId &&
        other.mediaText == mediaText;
  }

  @override
  int get hashCode => Object.hash(mediaType, mediaId, mediaText);

  @override
  String toString() =>
      "PackageKitMediaChangeRequiredEvent(mediaType: $mediaType, mediaId: '$mediaId', mediaText: '$mediaText')";
}

/// An event from the backend to indicate a package.
class PackageKitPackageEvent extends PackageKitEvent {
  /// Information about this package.
  final PackageKitInfo info;

  /// The id for this package.
  final PackageKitPackageId packageId;

  /// The one line package summary, e.g. "Clipart for OpenOffice".
  final String summary;

  const PackageKitPackageEvent(
      {required this.info, required this.packageId, required this.summary});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitPackageEvent &&
        other.info == info &&
        other.packageId == packageId &&
        other.summary == summary;
  }

  @override
  int get hashCode => Object.hash(info, packageId, summary);

  @override
  String toString() =>
      "$runtimeType(info: $info, packageId: '$packageId', summary: '$summary')";
}

/// An event from the backend to describe a repository on the system.
class PackageKitRepositoryDetailEvent extends PackageKitEvent {
  /// The ID of the repository.
  final String repoId;

  /// A description of the repository.
  final String description;

  /// True if the repository is enabled an in use.
  final bool enabled;

  const PackageKitRepositoryDetailEvent(
      {required this.repoId, required this.description, required this.enabled});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitRepositoryDetailEvent &&
        other.repoId == repoId &&
        other.description == description &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(repoId, description, enabled);

  @override
  String toString() =>
      "$runtimeType(repoId: '$repoId', description: '$description', enabled: $enabled)";
}

/// An event from the backend to indicate the something requires restarting to complete the transaction.
class PackageKitRequireRestartEvent extends PackageKitEvent {
  /// The type of restart required.
  final PackageKitRestart type;

  /// The ID of the package that caused the restart.
  final PackageKitPackageId packageId;

  const PackageKitRequireRestartEvent(
      {required this.type, required this.packageId});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is PackageKitRequireRestartEvent &&
        other.type == type &&
        other.packageId == packageId;
  }

  @override
  int get hashCode => Object.hash(type, packageId);

  @override
  String toString() => "$runtimeType(type: $type, packageId: '$packageId')";
}

/// An event from the backend to indicate the something requires restarting to complete the transaction.
class PackageKitUpdateDetailEvent extends PackageKitEvent {
  /// The ID of the package this event relates to.
  final PackageKitPackageId packageId;

  /// Packages that are being updated.
  final List<PackageKitPackageId> updates;

  /// Packages that are being obsoleted by this update.
  final List<PackageKitPackageId> obsoletes;

  /// A list of URLs containing more details about this update.
  final List<String> vendorUrls;

  /// A list of issue URLs fixed by this update.
  final List<String> bugzillaUrls;

  /// A list of CVE URLs fixed by this update.
  final List<String> cveUrls;

  /// Restart requirements for this update.
  final PackageKitRestart restart;

  /// Text describing the update.
  final String updateText;

  /// Text describing the changes since the last version.
  final String changelog;

  /// The state of the update.
  final PackageKitUpdateState state;

  /// The date that the update was issued.
  final DateTime? issued;

  /// The date that the update was updated.
  final DateTime? updated;

  const PackageKitUpdateDetailEvent(
      {required this.packageId,
      this.updates = const [],
      this.obsoletes = const [],
      this.vendorUrls = const [],
      this.bugzillaUrls = const [],
      this.cveUrls = const [],
      this.restart = PackageKitRestart.unknown,
      this.updateText = '',
      this.changelog = '',
      this.state = PackageKitUpdateState.unknown,
      this.issued,
      this.updated});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is PackageKitUpdateDetailEvent &&
        other.packageId == packageId &&
        listEquals(other.updates, updates) &&
        listEquals(other.obsoletes, obsoletes) &&
        listEquals(other.vendorUrls, vendorUrls) &&
        listEquals(other.cveUrls, cveUrls) &&
        other.restart == restart &&
        other.updateText == updateText &&
        other.state == state &&
        other.issued == issued &&
        other.updated == updated;
  }

  @override
  int get hashCode => Object.hash(
      packageId,
      Object.hashAll(updates),
      Object.hashAll(obsoletes),
      Object.hashAll(vendorUrls),
      Object.hashAll(cveUrls),
      restart,
      updateText,
      state,
      issued,
      updated);

  @override
  String toString() =>
      "$runtimeType(packageId: '$packageId', updates: $updates, obsoletes: $obsoletes, vendorUrls: $vendorUrls, cveUrls: $cveUrls, restart: $restart, updateText: $updateText, state: $state, issued: $issued, updated: $updated)";
}

/// A PackageKit transaction.
class PackageKitTransaction {
  /// Remote transaction object.
  final DBusRemoteObject _object;

  /// Events returned from the backend.
  late final Stream<PackageKitEvent> events;

  /// Transaction properties.
  final _properties = <String, DBusValue>{};
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  /// Creates a PackageKit transaction from [objectPath].
  /// This should not be accessed directly, use [PackageKitClient.getTransaction] to get an existing transaction, otherwise use [PackageKitClient.createTransaction].
  PackageKitTransaction(DBusClient bus, DBusObjectPath objectPath)
      : _object =
            DBusRemoteObject(bus, name: _packageKitBusName, path: objectPath) {
    events = DBusSignalStream(bus,
            sender: _packageKitBusName,
            interface: _packageKitTransactionInterfaceName,
            path: objectPath)
        .map((signal) {
      switch (signal.name) {
        case 'Details':
          if (signal.signature != DBusSignature('a{sv}')) {
            throw 'Invalid ${signal.name} signal';
          }
          var data = signal.values[0].asStringVariantDict();
          return PackageKitDetailsEvent(
              packageId: PackageKitPackageId.fromString(
                  data['package-id']?.asString() ?? ''),
              group: _decodeGroup(data['group']?.asUint32() ?? 0),
              summary: data['summary']?.asString() ?? '',
              description: data['description']?.asString() ?? '',
              url: data['url']?.asString() ?? '',
              license: data['license']?.asString() ?? '',
              size: data['size']?.asUint64() ?? 0);
        case 'Destroy':
          if (signal.signature != DBusSignature('')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitDestroyEvent();
        case 'ErrorCode':
          if (signal.signature != DBusSignature('us')) {
            throw 'Invalid ${signal.name} signal';
          }
          var codeValue = signal.values[0].asUint32();
          return PackageKitErrorCodeEvent(
              code: codeValue < PackageKitError.values.length
                  ? PackageKitError.values[codeValue]
                  : PackageKitError.unknown,
              details: signal.values[1].asString());
        case 'Files':
          if (signal.signature != DBusSignature('sas')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitFilesEvent(
              packageId:
                  PackageKitPackageId.fromString(signal.values[0].asString()),
              fileList: signal.values[1].asStringArray().toList());
        case 'Finished':
          if (signal.signature != DBusSignature('uu')) {
            throw 'Invalid ${signal.name} signal';
          }
          var exitValue = signal.values[0].asUint32();
          return PackageKitFinishedEvent(
              exit: exitValue < PackageKitExit.values.length
                  ? PackageKitExit.values[exitValue]
                  : PackageKitExit.unknown,
              runtime: signal.values[1].asUint32());
        case 'ItemProgress':
          if (signal.signature != DBusSignature('suu')) {
            throw 'Invalid ${signal.name} signal';
          }
          var statusValue = signal.values[1].asUint32();
          return PackageKitItemProgressEvent(
              packageId:
                  PackageKitPackageId.fromString(signal.values[0].asString()),
              status: statusValue < PackageKitStatus.values.length
                  ? PackageKitStatus.values[statusValue]
                  : PackageKitStatus.unknown,
              percentage: signal.values[2].asUint32());
        case 'MediaChangeRequired':
          if (signal.signature != DBusSignature('uss')) {
            throw 'Invalid ${signal.name} signal';
          }
          var mediaTypeValue = signal.values[0].asUint32();
          return PackageKitMediaChangeRequiredEvent(
              mediaType: mediaTypeValue < PackageKitMediaType.values.length
                  ? PackageKitMediaType.values[mediaTypeValue]
                  : PackageKitMediaType.unknown,
              mediaId: signal.values[1].asString(),
              mediaText: signal.values[2].asString());
        case 'Package':
          if (signal.signature != DBusSignature('uss')) {
            throw 'Invalid ${signal.name} signal';
          }
          var infoValue = signal.values[0].asUint32();
          return PackageKitPackageEvent(
              info: infoValue < PackageKitInfo.values.length
                  ? PackageKitInfo.values[infoValue]
                  : PackageKitInfo.unknown,
              packageId:
                  PackageKitPackageId.fromString(signal.values[1].asString()),
              summary: signal.values[2].asString());
        case 'RepoDetail':
          if (signal.signature != DBusSignature('ssb')) {
            throw 'Invalid ${signal.name} signal';
          }
          return PackageKitRepositoryDetailEvent(
              repoId: signal.values[0].asString(),
              description: signal.values[1].asString(),
              enabled: signal.values[2].asBoolean());
        case 'RequireRestart':
          if (signal.signature != DBusSignature('us')) {
            throw 'Invalid ${signal.name} signal';
          }
          var type = _decodeRestart(signal.values[0].asUint32());
          return PackageKitRequireRestartEvent(
              type: type,
              packageId:
                  PackageKitPackageId.fromString(signal.values[1].asString()));
        case 'UpdateDetail':
          if (signal.signature != DBusSignature('sasasasasasussuss')) {
            throw 'Invalid ${signal.name} signal';
          }
          var packageId =
              PackageKitPackageId.fromString(signal.values[0].asString());
          var updates = signal.values[1]
              .asStringArray()
              .map((s) => PackageKitPackageId.fromString(s))
              .toList();
          var obsoletes = signal.values[2]
              .asStringArray()
              .map((s) => PackageKitPackageId.fromString(s))
              .toList();
          var vendorUrls = signal.values[3].asStringArray().toList();
          var bugzillaUrls = signal.values[4].asStringArray().toList();
          var cveUrls = signal.values[5].asStringArray().toList();
          var restart = _decodeRestart(signal.values[6].asUint32());
          var updateText = signal.values[7].asString();
          var changelog = signal.values[8].asString();
          var state = _decodeUpdateState(signal.values[9].asUint32());
          var issued = _decodeDateTime(signal.values[10].asString());
          var updated = _decodeDateTime(signal.values[11].asString());
          return PackageKitUpdateDetailEvent(
              packageId: packageId,
              updates: updates,
              obsoletes: obsoletes,
              vendorUrls: vendorUrls,
              bugzillaUrls: bugzillaUrls,
              cveUrls: cveUrls,
              restart: restart,
              updateText: updateText,
              changelog: changelog,
              state: state,
              issued: issued,
              updated: updated);
        default:
          return PackageKitUnknownEvent(signal.name, signal.values);
      }
    });
  }

  /// Cancel this transaction.
  Future<void> cancel() async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'Cancel', [],
        replySignature: DBusSignature(''));
  }

  /// Get the packages that the packages with [packageIds] depend on.
  /// This method generates a [PackageKitPackageEvent] event for each package that is depended on.
  Future<void> dependsOn(Iterable<PackageKitPackageId> packageIds,
      {Set<PackageKitFilter> filter = const {}, bool recursive = false}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'DependsOn',
        [
          DBusUint64(_encodeFilters(filter)),
          DBusArray.string(packageIds.map((id) => id.toString())),
          DBusBoolean(recursive)
        ],
        replySignature: DBusSignature(''));
  }

  /// Gets the details for packages with [packageIds].
  /// This method generates a [PackageKitDetailsEvent] event for each package.
  Future<void> getDetails(Iterable<PackageKitPackageId> packageIds) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetDetails',
        [DBusArray.string(packageIds.map((id) => id.toString()))],
        replySignature: DBusSignature(''));
  }

  /// Gets the details for local package files.
  /// The files are specified with their full [paths].
  /// This method generates a [PackageKitDetailsEvent] event for each package.
  Future<void> getDetailsLocal(Iterable<String> paths) async {
    await _object.callMethod(_packageKitTransactionInterfaceName,
        'GetDetailsLocal', [DBusArray.string(paths)],
        replySignature: DBusSignature(''));
  }

  /// Downloads the packages with [packageIds] into a temporary directory.
  /// This method generates a [PackageKitFilesEvent] event for each package file that is downloaded.
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

  /// Get the file lists for the packages with [packageIds].
  /// This method generates a [PackageKitFilesEvent] event for each file in these packages.
  Future<void> getFiles(Iterable<PackageKitPackageId> packageIds) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetFiles',
        [DBusArray.string(packageIds.map((id) => id.toString()))],
        replySignature: DBusSignature(''));
  }

  /// Gets the details for local package files.
  /// The files are specified with their full [paths].
  /// This method generates a [PackageKitFilesEvent] event for each file in these packages.
  Future<void> getFilesLocal(Iterable<String> paths) async {
    await _object.callMethod(_packageKitTransactionInterfaceName,
        'GetFilesLocal', [DBusArray.string(paths)],
        replySignature: DBusSignature(''));
  }

  /// Gets all the available and installed packages.
  /// This method generates a [PackageKitPackageEvent] event for each package.
  Future<void> getPackages({Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetPackages',
        [DBusUint64(_encodeFilters(filter))],
        replySignature: DBusSignature(''));
  }

  /// Gets the list of repositories used in the system.
  /// This method generates a [PackageKitRepositoryDetailEvent] for each repository.
  Future<void> getRepositoryList(
      {Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetRepoList',
        [DBusUint64(_encodeFilters(filter))],
        replySignature: DBusSignature(''));
  }

  /// Enable or disable the repository with the given [id].
  Future<void> setRepositoryEnabled(String id, bool enabled) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'RepoEnable',
        [DBusString(id), DBusBoolean(enabled)],
        replySignature: DBusSignature(''));
  }

  /// Set a [parameter] on the repository with the given [id].
  Future<void> setRepositoryData(
      String id, String parameter, String value) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'RepoSetData',
        [DBusString(id), DBusString(parameter), DBusString(value)],
        replySignature: DBusSignature(''));
  }

  /// Remove the repository with the given [id].
  /// If [autoremovePackages] is true, then packages installed from this repository are automatically removed.
  Future<void> removeRepository(String id,
      {bool autoremovePackages = false}) async {
    var flags = 0;
    await _object.callMethod(_packageKitTransactionInterfaceName, 'RepoRemove',
        [DBusString(id), DBusUint64(flags), DBusBoolean(autoremovePackages)],
        replySignature: DBusSignature(''));
  }

  /// Gets update information for packages with [packageIds].
  /// This method generates [PackageKitUpdateDetailEvent] events.
  Future<void> getUpdateDetail(Iterable<PackageKitPackageId> packageIds) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'GetUpdateDetail',
        [DBusArray.string(packageIds.map((id) => id.toString()))],
        replySignature: DBusSignature(''));
  }

  /// Gets all the installed packages that can be upgraded.
  /// This method generates a [PackageKitPackageEvent] event for each package.
  Future<void> getUpdates({Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'GetUpdates',
        [DBusUint64(_encodeFilters(filter))],
        replySignature: DBusSignature(''));
  }

  /// Install local package files onto the local system.
  /// The files are specified with their full [paths].
  /// This method generates a [PackageKitPackageEvent] event for each package that is installed.
  Future<void> installFiles(Iterable<String> paths,
      {Set<PackageKitTransactionFlag> transactionFlags = const {}}) async {
    await _object.callMethod(
        _packageKitTransactionInterfaceName,
        'InstallFiles',
        [
          DBusUint64(_encodeTransactionFlags(transactionFlags)),
          DBusArray.string(paths)
        ],
        replySignature: DBusSignature(''));
  }

  /// Install new packages with [packageIds] on the local system.
  /// This method generates a [PackageKitPackageEvent] event for each package that is installed.
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

  /// Fetch updated metadata for all enabled repositories.
  /// This method generates a [PackageKitRepositoryDetailEvent] event for each repository that is updated.
  Future<void> refreshCache({bool force = false}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName,
        'RefreshCache', [DBusBoolean(force)],
        replySignature: DBusSignature(''));
  }

  /// Remove packages with [packageIds] from the local system.
  /// This method generates a [PackageKitPackageEvent] event for each package that is removed.
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

  /// Resolved the named [packages] into package IDs.
  /// This method generates a [PackageKitPackageEvent] event for each package.
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

  /// Search the package database by for packages that provide the files given in [values].
  /// This method generates a [PackageKitPackageEvent] event for each package found.
  Future<void> searchFiles(Iterable<String> values,
      {Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'SearchFiles',
        [DBusUint64(_encodeFilters(filter)), DBusArray.string(values)],
        replySignature: DBusSignature(''));
  }

  /// Search the package database by for packages with the search terms given in [values].
  /// This method generates a [PackageKitPackageEvent] event for each package found.
  Future<void> searchNames(Iterable<String> values,
      {Set<PackageKitFilter> filter = const {}}) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'SearchNames',
        [DBusUint64(_encodeFilters(filter)), DBusArray.string(values)],
        replySignature: DBusSignature(''));
  }

  Future<void> _setHints(Iterable<String> hints) async {
    await _object.callMethod(_packageKitTransactionInterfaceName, 'SetHints',
        [DBusArray.string(hints)],
        replySignature: DBusSignature(''));
  }

  /// Update existing packages on the local system.
  /// This method generates a [PackageKitPackageEvent] event for each package being updated.
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

  /// Perform a distribution upgrade to the distribution given by [distroId].
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

  /// The transaction role enum, e.g. update-system.
  PackageKitRole get role =>
      PackageKitRole.values[_properties['Role']?.asUint32() ?? 0];

  /// The transaction status enum, e.g. downloading.
  PackageKitStatus get status =>
      PackageKitStatus.values[_properties['Status']?.asUint32() ?? 0];

  /// The last package_id that was processed, e.g. hal;0.1.2;i386;fedora.
  String get lastPackage => _properties['LastPackage']?.asString() ?? '';

  /// The uid of the user that started the transaction.
  int get uid => _properties['Uid']?.asUint32() ?? -1;

  /// The percentage complete of the transaction.
  int get percentage => _properties['Percentage']?.asUint32() ?? 0;

  /// If the transaction can be cancelled.
  bool get allowCancel => _properties['AllowCancel']?.asBoolean() ?? false;

  /// If the original caller of the method is still connected to the system bus.
  bool get callerActive => _properties['CallerActive']?.asBoolean() ?? false;

  /// The amount of time elapsed during the transaction in seconds.
  int get elapsedTime => _properties['ElapsedTime']?.asUint32() ?? 0;

  /// The estimated time remaining of the transaction in seconds, or 0 if not known.
  int get remainingTime => _properties['RemainingTime']?.asUint32() ?? 0;

  /// The estimated speed of the transaction (copying, downloading, etc.) in bits per second, or 0 if not known.
  int get speed => _properties['Speed']?.asUint32() ?? 0;

  /// The number of bytes remaining to download, 0 if nothing is left to download.
  int get downloadSizeRemaining =>
      _properties['DownloadSizeRemaining']?.asUint64() ?? -1;

  /// The flags set for this transaction, e.g. SIMULATE or ONLY_DOWNLOAD.
  Set<PackageKitTransactionFlag> get transactionFlags =>
      _decodeTransactionFlags(_properties['TransactionFlags']?.asUint64() ?? 0);

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }
}

/// A client that connects to PackageKit.
class PackageKitClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// The root D-Bus PackageKit object.
  late final DBusRemoteObject _root;

  /// The transaction objects we are monitoring.
  final _transactions = <DBusObjectPath, PackageKitTransaction>{};

  /// Properties on the root object.
  final _properties = <String, DBusValue>{};
  StreamSubscription? _propertiesChangedSubscription;
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  String? locale;
  bool background = false;
  bool interactive = true;
  bool idle = true;
  int cacheAge = 0xffffffff;

  ///  The backend author, e.g. "Joe Bloggs <joe@blogs.com>"
  String get backendAuthor => _properties['BackendAuthor']?.asString() ?? '';

  /// The backend description, e.g. "Yellow Dog Update Modifier"
  String get backendDescription =>
      _properties['BackendDescription']?.asString() ?? '';

  /// The backend name, e.g. "dnf"
  String get backendName => _properties['BackendName']?.asString() ?? '';

  /// The distribution identification, in the distro;version;arch form e.g. "debian;squeeze/sid;x86_64"
  String get distroId => _properties['DistroId']?.asString() ?? '';

  /// The filters the backend supports.
  Set<PackageKitFilter> get filters =>
      _decodeFilters(_properties['Filters']?.asUint64() ?? 0);

  /// The groups the backend supports.
  Set<PackageKitGroup> get groups =>
      _decodeGroups(_properties['Groups']?.asUint64() ?? 0);

  /// Set when the backend is locked and native tools would fail.
  bool get locked => _properties['Locked']?.asBoolean() ?? false;

  /// The mime-types the backend supports, e.g. ['application/x-rpm', 'application/x-deb'].
  List<String> get mimeTypes =>
      _properties['MimeTypes']?.asStringArray().toList() ?? [];

  /// The roles the backend supports.
  Set<PackageKitRole> get roles =>
      _decodeRoles(_properties['Roles']?.asUint64() ?? 0);

  /// The network state from the daemon. This is provided as some clients may not want
  /// to use NetworkManager if the system daemon is configured to use something else.
  PackageKitNetworkState get networkState {
    var value = _properties['NetworkState']?.asUint32() ?? 0;
    return value < PackageKitNetworkState.values.length
        ? PackageKitNetworkState.values[value]
        : PackageKitNetworkState.unknown;
  }

  /// The major version number of the PackageKit daemon.
  int get versionMajor => _properties['VersionMajor']?.asUint32() ?? 0;

  /// The minor version number of the PackageKit daemon.
  int get versionMinor => _properties['VersionMinor']?.asUint32() ?? 0;

  /// The micro version number of the PackageKit daemon.
  int get versionMicro => _properties['VersionMicro']?.asUint32() ?? 0;

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  /// Creates a new PackageKit client connected to the system D-Bus.
  PackageKitClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root = DBusRemoteObject(_bus,
        name: _packageKitBusName,
        path: DBusObjectPath('/org/freedesktop/PackageKit'));
  }

  /// Connects to the PackageKit daemon.
  Future<void> connect() async {
    // Already connected
    if (_propertiesChangedSubscription != null) {
      return;
    }

    _propertiesChangedSubscription = DBusSignalStream(_bus,
            sender: _packageKitBusName,
            interface: 'org.freedesktop.DBus.Properties')
        .listen((signal) {
      if (signal.signature != DBusSignature('sa{sv}as')) {
        return;
      }

      var s = DBusPropertiesChangedSignal(signal);
      if (s.propertiesInterface == _packageKitInterfaceName) {
        if (s.path == _root.path) {
          _updateProperties(s.changedProperties);
        } else {
          var transaction = _transactions[s.path];
          transaction?._updateProperties(s.changedProperties);
        }
      }
    });
    _updateProperties(await _root.getAllProperties(_packageKitInterfaceName));
  }

  /// Get an existing transaction object at [path].
  Future<PackageKitTransaction> getTransaction(DBusObjectPath path) async {
    var transaction = PackageKitTransaction(_bus, path);
    _transactions[path] = transaction;

    transaction._updateProperties(
        await transaction._object.getAllProperties(_packageKitInterfaceName));

    return transaction;
  }

  /// Creates a new transaction that can have operations done on it.
  Future<PackageKitTransaction> createTransaction() async {
    var result = await _root.callMethod(
        _packageKitInterfaceName, 'CreateTransaction', [],
        replySignature: DBusSignature('o'));
    var transaction =
        await getTransaction(result.returnValues[0].asObjectPath());

    var hints = <String>[];
    if (locale != null) {
      hints.add('locale=$locale');
    }
    hints.add('background=${background ? 'true' : 'false'}');
    hints.add('interactive=${interactive ? 'true' : 'false'}');
    hints.add('idle=${idle ? 'true' : 'false'}');
    hints.add('cache-age=$cacheAge');
    await transaction._setHints(hints);

    return transaction;
  }

  /// Terminates the connection to the PackageKit daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_propertiesChangedSubscription != null) {
      await _propertiesChangedSubscription!.cancel();
      _propertiesChangedSubscription = null;
    }
    if (_closeBus) {
      await _bus.close();
    }
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }
}
