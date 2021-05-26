import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main() async {
  var client = PackageKitClient();
  await client.connect();

  var transaction = await client.createTransaction();
  var completer = Completer();
  transaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      var id = event.packageId;
      var status = {
            PackageKitInfo.available: 'Available',
            PackageKitInfo.installed: 'Installed'
          }[event.info] ??
          '         ';
      print(
          '$status ${id.name}-${id.version}.${id.arch} (${id.data})  ${event.summary}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      completer.complete();
    }
  });
  await transaction.getPackages();
  await completer.future;

  await client.close();
}
