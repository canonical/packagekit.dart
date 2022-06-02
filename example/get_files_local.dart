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

  var getFilesTransaction = await client.createTransaction();
  var getFilesCompleter = Completer();
  getFilesTransaction.events.listen((event) {
    if (event is PackageKitFilesEvent) {
      for (var file in event.fileList) {
        print(file);
      }
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      getFilesCompleter.complete();
    }
  });
  await getFilesTransaction.getFilesLocal(paths);
  await getFilesCompleter.future;

  await client.close();
}
