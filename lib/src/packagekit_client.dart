import 'dart:async';

import 'package:dbus/dbus.dart';

/// D-Bus interface names.
const _packageKitBusName = 'org.freedesktop.PackageKit';
const _packageKitInterfaceName = 'org.freedesktop.PackageKit';

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

  /// Terminates the connection to the PackageKit daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}
