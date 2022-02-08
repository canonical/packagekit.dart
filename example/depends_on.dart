import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package name(s)');
    return;
  }
  var packageNames = args;

  var client = PackageKitClient();
  await client.connect();

  var resolveTransaction = await client.createTransaction();
  var resolveCompleter = Completer();
  var packageIds = <PackageKitPackageId>[];
  resolveTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      packageIds.add(event.packageId);
    } else if (event is PackageKitFinishedEvent) {
      resolveCompleter.complete();
    }
  });
  await resolveTransaction.resolve(packageNames);
  await resolveCompleter.future;
  if (packageIds.isEmpty) {
    print('No packages found');
    await client.close();
    return;
  }

  var dependsOnTransaction = await client.createTransaction();
  var dependsOnCompleter = Completer();
  dependsOnTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      var id = event.packageId;
      var status = {
            PackageKitInfo.available: 'Available',
            PackageKitInfo.installed: 'Installed'
          }[event.info] ??
          '         ';
      print(
          '$status ${id.name}-${id.version}.${id.arch} (${id.data})  ${event.summary}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      dependsOnCompleter.complete();
    }
  });
  await dependsOnTransaction.dependsOn(packageIds);
  await dependsOnCompleter.future;

  await client.close();
}
