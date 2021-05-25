[![Pub Package](https://img.shields.io/pub/v/packagekit.svg)](https://pub.dev/packages/packagekit)

Provides a client to connect to [PackageKit](https://www.freedesktop.org/software/PackageKit) - the service that enables installation and removal of software packages on
Linux.

```dart
import 'package:packagekit/packagekit.dart';

var client = PackageKitClient();
await client.connect();
print('Server version: ${client.versionMajor}.${client.versionMinor}.${client.versionMicro}');
print('Backend: ${client.backendDescription} (${client.backendName})');
await client.close();
```

## Contributing to packagekit.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
