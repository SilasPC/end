
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:common/EnduranceEvent.dart';
import 'package:common/Equipe.dart' as equipe;
import 'package:common/EventModel.dart';
import 'package:common/models/demo.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:socket_io/socket_io.dart';

late EventModel<Model> em;
late Server io;
File backupFile = File("../backup.events.json");

Future<List<Event<Model>>> readCachedEvents() async {
	var json = jsonDecode(await backupFile.readAsString());
	return jlist_map(json, eventFromJSON);
}

Future<void> main() async {

	List<Event<Model>> evs =
		//await readCachedEvents();
		demoInitEvent(nowUNIX() + 300);
		//await equipe.loadModelEvents(44178);
		//await loadEventsFromFile("roddingeritten");
	
	//evs.removeRange((evs.length / 2).floor(), evs.length);

	var handle = Handle();
	em = EventModel(handle);
	em.add(evs);

	// await saveCSV();

	io = Server();
	io.on("connection", (client) {
		setJsonAck(client, "sync", (json) {
			var sr = SyncRequest<Model>.fromJSON(json);
			var res = sr.applyTo(em);
			client.broadcast.emit('push', SyncPush(sr.events, sr.deletes).toJson());
			return res;
		});
	});
	io.listen(3000);
}

void setJsonAck<T extends IJSON>(dynamic client, String msg, FutureOr<T?>? Function(JSON data) handler) {
	client.on(msg, (data) async {
		List dataList = data as List;
		var json = dataList.first;
		var ack = dataList.last;
		var res = await handler(jsonDecode(json));
		if (res != null) {
			ack(res.toJsonString());
		}
	});
}

class Handle extends EventModelHandle<Model> {

	@override
	Model createModel() => Model();

	@override
	Model revive(JSON json) => Model.fromJson(json);

	@override
	Future<void> didUpdate() async {
		await backupFile.writeAsString(
			jsonEncode(iterj(model.events.iteratorInsertion)),
			flush: true
		);
		print("saved");
	}

}

Future<List<EnduranceEvent>> loadEventsFromFile(String fileName) async {
	var json = jsonDecode(await File("../$fileName.events.json").readAsString());
	return jlist_map(json, eventFromJSON);
}

// TODO: complete this
Future<void> saveCSV() async {
	await File("../results.csv").writeAsString(em.model.toResultCSV(), flush: true);
}
