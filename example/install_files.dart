import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package paths(s)');
    return;
  }
  var paths = args;

  var client = PackageKitClient();
  await client.connect();

  var installTransaction = await client.createTransaction();
  var installCompleter = Completer();
  installTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      print('[${event.packageId.name}] ${event.info}');
    } else if (event is PackageKitItemProgressEvent) {
      print('[${event.packageId.name}] ${event.status} ${event.percentage}%');
    } else if (event is PackageKitFinishedEvent) {
      installCompleter.complete();
    }
  });
  await installTransaction.installFiles(paths);
  await installCompleter.future;

  await client.close();
}
