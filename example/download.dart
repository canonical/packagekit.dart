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

  final downloadTransaction = await client.createTransaction();
  final downloadCompleter = Completer();
  downloadTransaction.events.listen((event) {
    if (event is PackageKitFilesEvent) {
      final id = event.packageId;
      print('${id.name}-${id.version}.${id.arch} ${event.fileList[0]}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      downloadCompleter.complete();
    }
  });
  await downloadTransaction.downloadPackages(packageIds);
  await downloadCompleter.future;

  await client.close();
}
