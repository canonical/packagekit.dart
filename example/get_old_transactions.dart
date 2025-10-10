import 'dart:async';

import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Getting all known transactions');
  }
  var number = int.tryParse(args.first) ?? 0;

  var client = PackageKitClient();
  await client.connect();

  var transaction = await client.createTransaction();
  var detailsCompleter = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitTransactionEvent) {
      print('  objectPath: ${event.objectPath}');
      print('  timespec: ${event.timespec}');
      print('  succeeded: ${event.succeeded}');
      print('  role: ${event.role}');
      print('  duration: ${event.duration}');
      print('  data: ${event.data}');
      print('  uid: ${event.uid}');
      print('  cmdline: ${event.cmdline}');
    } else if (event is PackageKitFinishedEvent) {
      detailsCompleter.complete();
    }
  });
  await transaction.getOldTransactions(number: number);
  await detailsCompleter.future;

  await client.close();
}
