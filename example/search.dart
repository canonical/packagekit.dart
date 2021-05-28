import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need search type, e.g. name or file');
    return;
  }
  var type = args[0];

  if (args.length < 2) {
    print('Need a search term');
  }
  var terms = args.skip(1);

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
