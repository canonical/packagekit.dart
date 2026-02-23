// ignore_for_file: avoid_print

import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package path(s)');
    return;
  }
  final paths = args;

  final client = PackageKitClient();
  await client.connect();

  final installTransaction = await client.createTransaction();
  final detailsCompleter = Completer();
  installTransaction.events.listen((event) {
    if (event is PackageKitDetailsEvent) {
      print('${event.packageId}');
      print('  summary: ${event.summary}');
      print('  url: ${event.url}');
      print('  license: ${event.license}');
      print('  size: ${event.size}');
    } else if (event is PackageKitFinishedEvent) {
      detailsCompleter.complete();
    }
  });
  await installTransaction.getDetailsLocal(paths);
  await detailsCompleter.future;

  await client.close();
}
