// ignore_for_file: avoid_print

import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need search type, e.g. name or file');
    return;
  }
  final type = args[0];

  if (args.length < 2) {
    print('Need a search term');
  }
  final terms = args.skip(1);

  final client = PackageKitClient();
  await client.connect();

  final transaction = await client.createTransaction();
  final completer = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      final id = event.packageId;
      final status = {
            PackageKitInfo.available: 'Available',
            PackageKitInfo.installed: 'Installed',
          }[event.info] ??
          '         ';
      print('$status ${id.name}-${id.version}.${id.arch}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      completer.complete();
    }
  });
  switch (type) {
    case 'name':
      await transaction.searchNames(terms);
      break;
    case 'file':
      await transaction.searchFiles(terms);
      break;
    default:
      print('Invalid search type $type');
      return;
  }

  await completer.future;

  await client.close();
}
