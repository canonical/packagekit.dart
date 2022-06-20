import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    print('Need repository id');
    return;
  }
  var id = args[0];

  var client = PackageKitClient();
  await client.connect();

  var transaction = await client.createTransaction();
  var completer = Completer();
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
