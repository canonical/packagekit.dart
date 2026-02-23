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
      if (event.info == PackageKitInfo.available) {
        packageIds.add(event.packageId);
      }
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

  final transaction = await client.createTransaction();
  final completer = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitUpdateDetailEvent) {
      final id = event.packageId;
      print('Package: ${id.name}-${id.version}.${id.arch}');
      print('Updates: ${event.updates.join(';')}');
      print('Update text: ${event.updateText}');
      print('Changes: ${event.changelog}');
      print('Issued: ${event.issued?.toString() ?? ''}');
      print('Updated: ${event.updated?.toString() ?? ''}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      completer.complete();
    }
  });
  await transaction.getUpdateDetail(packageIds);
  await completer.future;

  await client.close();
}
