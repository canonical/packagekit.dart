import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package name(s)');
    return;
  }
  var packageNames = args;

  var client = PackageKitClient();
  await client.connect();

  var resolveTransaction = await client.createTransaction();
  var resolveCompleter = Completer();
  var packageIds = <PackageKitPackageId>[];
  resolveTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      packageIds.add(event.packageId);
    } else if (event is PackageKitFinishedEvent) {
      resolveCompleter.complete();
    }
  });
  await resolveTransaction.resolve(packageNames);
  await resolveCompleter.future;
  if (packageIds.isEmpty) {
    print('No packages found');
    await client.close();
    return;
  }

  var downloadTransaction = await client.createTransaction();
  var downloadCompleter = Completer();
  downloadTransaction.events.listen((event) {
    if (event is PackageKitFilesEvent) {
      var id = event.packageId;
      print('${id.name}-${id.version}.${id.arch} ${event.fileList[0]}');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      downloadCompleter.complete();
    }
  });
  await downloadTransaction.downloadPackages(packageIds);
  await downloadCompleter.future;

  await client.close();
}
