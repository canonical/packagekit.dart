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
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
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
  await installTransaction.getDetails(packageIds);
  await detailsCompleter.future;

  await client.close();
}
