
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:socket_io/socket_io.dart';

late EventModel<Model> em;
late Server io;
File backupFile = File("../backup.events.json");

Future<List<Event<Model>>> readCachedEvents() async {
	if (!await backupFile.exists()) {
		return [];
	}
	var json = jsonDecode(await backupFile.readAsString());
	return jlist_map(json, eventFromJSON);
}

Future<void> main() async {

	List<Event<Model>> evs = await readCachedEvents();

	var handle = Handle();
	em = EventModel(handle);
	em.add(evs);

	io = Server();
	int id = 0;
	io.on("connection", (client) {
		int idc = id++;
		print("connect $idc");
		setJsonAck(client, "sync", (json) {
			print("sync $idc");
			var sr = SyncRequest<Model>.fromJSON(json);
			var res = sr.applyTo(em);
			client.broadcast.emit('push', SyncPush(sr.events, sr.deletes).toJson());
			return res;
		});
		client.on("do-reset", (_) {
			print("reset $idc");
			em.reset();
			client.broadcast.emit("do-reset");
		});
		client.on("disconnect", (_) {
			print("disconnect $idc");
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
		// TODO: database or mutex/redundancy for error-correction
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
