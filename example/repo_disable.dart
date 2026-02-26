// ignore_for_file: avoid_print

import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    print('Need repository id');
    return;
  }
  final id = args[0];

  final client = PackageKitClient();
  await client.connect();

  final transaction = await client.createTransaction();
  final completer = Completer();
  transaction.events.listen((event) {
    print(event);
    if (event is PackageKitFinishedEvent) {
      completer.complete();
    }
  });
  await transaction.setRepositoryEnabled(id, false);
  await completer.future;

  await client.close();
}
