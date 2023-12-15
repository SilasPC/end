
import 'dart:convert';

import '../util.dart';
import 'package:http/http.dart' as http;

class ClassSection {

   final String name;
   final int id;
   final dynamic data;

   late final int? dist, minSpeed, maxSpeed, idealSpeed;
   late final String? lvl;
   late final bool clearRound;

   ClassSection(this.name, this.id, this.data) {
      dist = maybe(rgxDist.firstMatch(name)?[1], int.parse);
      lvl = rgxCatLvl.firstMatch(name)?[0];

      minSpeed = maybe(rgxMinSpd.firstMatch(name)?[1], int.parse);
      maxSpeed = maybe(rgxMaxSpd.firstMatch(name)?[1], int.parse);
      idealSpeed = maybe(rgxIdeal.firstMatch(name)?[1], int.parse);
      clearRound = rgxClearRound.hasMatch(name);
   }

   static Future<ClassSection?> load(String name, int classId) async {
	   var data = await _loadJSON("api/v1/class_sections/${classId}");
	   if (nullOrEmpty((data["starts"] as List).firstOrNull?["start_no"])) return null;
      return ClassSection(name, classId, data);
   }

   List<Equipage> starts() =>
      data["starts"].map(Equipage.new).toList();

}

class Equipage {

   final dynamic data;

   const Equipage(this.data);

   int get eid => int.parse(data["start_no"]);
   String get rider => data["rider_name"];
   String get horse => data["horse_name"];

}

Future<dynamic> _loadJSON(String loc) async {
	var res = await http.get(Uri.https("online.equipe.com", loc));
	if (res.statusCode != 200)
		throw Exception("Equipe $loc status ${res.statusCode}");
	return jsonDecode(res.body);
}

Future<List<(String, int)>> loadMeets() async {
   var res = (await _loadJSON("api/v1/meetings")) as List;
   res.retainWhere((e) => e["discipline"] == "endurance");
   return res.map((e) => (e["display_name"] as String, e["id"] as int)).toList();
}

Future<List<ClassSection>> loadSections(int classId) async {
   dynamic schd = await _loadJSON("api/v1/meetings/$classId/schedule");
	if (schd["discipline"] != "endurance")
		throw Exception("Could not load a non-endurance event");

	var days = [schd];
	if ((schd as JSON).containsKey("days")) {
		days = schd["days"];
	}

   return (await Future.wait(days
         .expand((day) => day["meeting_classes"] ?? [])
         .map((cl) {
            if (cl["name"] == null) {
               return null;
            }
            String name = cl["name"];
            var class_sections = (cl["class_sections"] ?? []) as List;
            if (class_sections.isEmpty) return null;
            int id = class_sections.first["id"];
            return ClassSection.load(name, id);
      }).whereType<Future>()))
      .whereType<ClassSection>()
      .toList();
}

RegExp rgxDist = RegExp(r"(\d+)(?:[.,]\d+)?\s?km");
RegExp rgxCatLvl = RegExp(r"[LMS][ABCDE]|CEI.*\d?\*+");
RegExp rgxMinSpd = RegExp(r"min\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxMaxSpd = RegExp(r"max\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxIdeal = RegExp(r"idealtid\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxClearRound = RegExp(r"clear.*round", caseSensitive: false);
