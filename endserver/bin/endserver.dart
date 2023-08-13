
import 'dart:convert';
import 'dart:io';
import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:common/AbstractEventModel.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/Equipe.dart' as equipe;
import 'package:common/models/demo.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:socket_io/socket_io.dart';

late EventModel em;
late Server io;
File backupFile = File("../backup.events.json");

Future<List<Event<Model>>> readCachedEvents() async {
	var json = jsonDecode(await backupFile.readAsString());
	return jlist_map(json, eventFromJSON);
}

Future<void> main() async {

	List<Event<Model>> evs =
		await readCachedEvents();
		//demoInitEvent(nowUNIX() + 300);
		//await equipe.loadModelEvents(44178);
		//await loadEventsFromFile("roddingeritten");
	
	//evs.removeRange((evs.length / 2).floor(), evs.length);

	em = EventModel.withBase(Model());
	em.addEvents(evs);

	// await saveCSV();

	io = Server();
	io.on('connection', (client) {
		print('connection');
		client.on('sync', (data) {
			List dataList = data as List;
			var json = dataList.first;
			var ack = dataList.last;
			print('\nsync $json');
			SyncRequest<Model> sr = SyncRequest.fromJSON(jsonDecode(json));
			SyncResult<Model> res = em.syncFromRequest(sr);
			ack(res.toJsonString());
			client.broadcast.emit('push', SyncPush(em.gen, sr.events).toJson());
		});
		client.on("disconnect", (_) => print("disconnect"));
	});
	io.listen(3000);
}

class EventModel extends AbstractEventModel<Model> {

	EventModel.withBase(Model model) : super.withBase(model);

	@override
	Model $reviveModel(JSON json) =>
		Model.fromJson(json);

	@override
	Future<void> $onUpdate() async {
		await backupFile.writeAsString(
			jsonEncode(listj(this.events)),
			flush: true
		);
		print("saved");
	}

}

Future<List<EnduranceEvent>> loadEventsFromFile(String fileName) async {
	var json = jsonDecode(await File("../$fileName.events.json").readAsString());
	return jlist_map(json, eventFromJSON);
}

// todo: complete this
Future<void> saveCSV() async {
	await File("../results.csv").writeAsString(em.model.toResultCSV(), flush: true);
}
