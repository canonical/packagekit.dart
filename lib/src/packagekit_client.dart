import 'dart:async';

import 'package:dbus/dbus.dart';

/// D-Bus interface names.
const _serverInterfaceName = 'org.freedesktop.PackageKit';

/// A client that connects to PackageKit.
class PackageKitClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// The root D-Bus PackageKit object.
  late final DBusRemoteObject _root;

  /// Properties on the root object.
  final _properties = <String, DBusValue>{};

  String get backendDescription =>
      (_properties['BackendDescription'] as DBusString).value;
  String get backendName => (_properties['BackendName'] as DBusString).value;
  int get versionMajor => (_properties['VersionMajor'] as DBusUint32).value;
  int get versionMinor => (_properties['VersionMinor'] as DBusUint32).value;
  int get versionMicro => (_properties['VersionMicro'] as DBusUint32).value;

  /// Creates a new PackageKit client connected to the system D-Bus.
  PackageKitClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root = DBusRemoteObject(_bus, 'org.freedesktop.PackageKit',
        DBusObjectPath('/org/freedesktop/PackageKit'));
  }

  /// Connects to the PackageKit daemon.
  Future<void> connect() async {
    _properties.addAll(await _root.getAllProperties(_serverInterfaceName));
  }

  /// Terminates the connection to the PackageKit daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}
