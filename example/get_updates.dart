// ignore_for_file: avoid_print

import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main() async {
  final client = PackageKitClient();
  await client.connect();

  final transaction = await client.createTransaction();
  final completer = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      final id = event.packageId;
      print('${id.name}-${id.version}.${id.arch}  ${event.summary}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      completer.complete();
    }
  });
  await transaction.getUpdates();
  await completer.future;

  await client.close();
}
