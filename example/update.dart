// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  final client = PackageKitClient();
  await client.connect();

  final getUpdatesTransaction = await client.createTransaction();
  final getUpdatesCompleter = Completer();
  final packageIds = <PackageKitPackageId>[];
  getUpdatesTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      packageIds.add(event.packageId);
    } else if (event is PackageKitFinishedEvent) {
      getUpdatesCompleter.complete();
    }
  });
  await getUpdatesTransaction.getUpdates();
  await getUpdatesCompleter.future;

  if (packageIds.isEmpty) {
    print('All packages up to date!');
    await client.close();
    return;
  }

  print('The following packages have updates:');
  for (final id in packageIds) {
    print('${id.name}-${id.version}.${id.arch}');
  }
  print('Proceed with changes? [N/y]');
  if (stdin.readLineSync() != 'y') {
    await client.close();
    return;
  }

  final updatePackagesTransaction = await client.createTransaction();
  final updatePackagesCompleter = Completer();
  updatePackagesTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      print('[${event.packageId.name}] ${event.info}');
    } else if (event is PackageKitItemProgressEvent) {
      print('[${event.packageId.name}] ${event.status} ${event.percentage}%');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      updatePackagesCompleter.complete();
    }
  });
  await updatePackagesTransaction.updatePackages(packageIds);
  await updatePackagesCompleter.future;

  await client.close();
}
