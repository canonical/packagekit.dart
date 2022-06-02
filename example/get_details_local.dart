import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package path(s)');
    return;
  }
  var paths = args;

  var client = PackageKitClient();
  await client.connect();

  var installTransaction = await client.createTransaction();
  var detailsCompleter = Completer();
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
