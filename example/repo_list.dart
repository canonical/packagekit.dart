// ignore_for_file: avoid_print

import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main() async {
  final client = PackageKitClient();
  await client.connect();

  final transaction = await client.createTransaction();
  final completer = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitRepositoryDetailEvent) {
      print(
        '${event.enabled ? 'Enabled ' : 'Disabled'} ${event.repoId} ${event.description}',
      );
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      completer.complete();
    }
  });
  await transaction.getRepositoryList();
  await completer.future;

  await client.close();
}
