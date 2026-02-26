// ignore_for_file: avoid_print

import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package name(s)');
    return;
  }
  final packageNames = args;

  final client = PackageKitClient();
  await client.connect();

  final resolveTransaction = await client.createTransaction();
  final resolveCompleter = Completer();
  final packageIds = <PackageKitPackageId>[];
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

  final getFilesTransaction = await client.createTransaction();
  final getFilesCompleter = Completer();
  getFilesTransaction.events.listen((event) {
    if (event is PackageKitFilesEvent) {
      for (final file in event.fileList) {
        print(file);
      }
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      getFilesCompleter.complete();
    }
  });
  await getFilesTransaction.getFiles(packageIds);
  await getFilesCompleter.future;

  await client.close();
}
