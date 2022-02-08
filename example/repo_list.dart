import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main() async {
  var client = PackageKitClient();
  await client.connect();

  var transaction = await client.createTransaction();
  var completer = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitRepositoryDetailEvent) {
      print(
          '${event.enabled ? 'Enabled ' : 'Disabled'} ${event.repoId} ${event.description}');
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
