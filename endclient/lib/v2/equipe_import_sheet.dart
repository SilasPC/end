
import 'package:common/Equipe.dart';
import 'package:common/equipe/data_types.dart';
import 'package:common/models/demo.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EquipeImportSheet extends StatefulWidget {

	const EquipeImportSheet({super.key});

	static void showAsBottomSheet(BuildContext context) {
		showModalBottomSheet(
			showDragHandle: true,
			context: context,
			builder: (_) => Navigator(
				onGenerateInitialRoutes: (navigator, initialRoute) => [
					MaterialPageRoute(
						builder: (_) => EquipeImportSheet()
					),
				]
			),
		);
	}

	@override
	State<EquipeImportSheet> createState() => _EquipeImportSheetState();

}

class _EquipeImportSheetState extends State<EquipeImportSheet> {

	List<(String, int)>? meetings;
	bool error = false;

	@override
	void initState() {
		super.initState();
		init();
	}

	void init() async {
		try {
			meetings = await loadMeets();
		} catch (e, st) {
         print(e);
         print(st);
         error = true;
		}
		setState(() {});
	}

	@override
	Widget build(BuildContext context) {
		return ListView(
			children: [
				ListTile(
					title: Text("DEMO"),
					trailing: Icon(Icons.chevron_right),
					onTap: () async {
                  LocalModel model = context.read();
                  var nav = Navigator.of(context, rootNavigator: true);
                  await model.addSync(demoInitEvent(model.id, nowUNIX()+300));
                  nav.pop();
               },
				),
				if (meetings case List<(String, int)> meetings) ...[
					for (var (name, id) in meetings)
					ListTile(
						title: Text(name),
						onTap: () {
							Navigator.push(context, MaterialPageRoute(
								builder: (_) => _SelectCategories(name, id)
							));
						},
						trailing: Icon(Icons.chevron_right),
					),
					// emptyListText("Not found?"),
				]
				else if (error)
				emptyListText("An error occurred")
				else
				AspectRatio(
					aspectRatio: 1,
					child: CircularProgressIndicator()
				)
			],
		);
	}

}

class _SelectCategories extends StatefulWidget {

   final String name;
   final int id;

   const _SelectCategories(this.name, this.id, {super.key});

  @override
  State<_SelectCategories> createState() => _SelectCategoriesState();
}

class _SelectCategoriesState extends State<_SelectCategories> {

   Set<ClassSection> selected = {};
   List<ClassSection>? sections;
   bool error = false;

   @override
   void initState() {
      super.initState();
      init();
   }

   void init() async {
      try {
         sections = await loadSections(widget.id);
         selected = sections!.toSet();
      }
      catch (e, st) {
         print(e);
         print(st);
         error = true;
      }
      setState(() {});
   }

	@override
	Widget build(BuildContext context) {
		return Column(
		  children: [
            ListTile(
               title: Text(widget.name),
            ),
		    Expanded(
							child: ListView(
								children: [
                           if (sections case List<ClassSection> sections)
                           for (var sec in sections)
									ExpansionTile(
                              initiallyExpanded: true,
                              key: PageStorageKey(sec),
										title: Text(sec.name),
										trailing: Checkbox(
                                 value: selected.contains(sec),
                                 onChanged: (value) {
                                 setState(() {
                                    if (value == true)
                                       selected.add(sec);
                                    else
                                       selected.remove(sec);
                                 });
                              },),
                              /* children: [
                                 Row(
                                    children: [
                                       SegmentedButton(
                                          selected: {3},
                                          segments: [
                                             ButtonSegment(
                                                label: Text("Clear round"),
                                                value: 1
                                             ),
                                             ButtonSegment(
                                                label: Text("Ideal time"),
                                                value: 2
                                             ),
                                             ButtonSegment(
                                                label: Text("Free time"),
                                                value: 3
                                             ),
                                          ],
                                          onSelectionChanged: (_) {},
                                       )
                                    ]
                                 )
                              ], */
									)
                           else if (!error)
                           emptyListText("Loading")
                           else
                           emptyListText("An error occured")
								],
							),
						 ),
				ListTile(
					title: Text("OK"),
					onTap: () {

               },
				)
		  ],
		);

	}
}

Future<void> _load(BuildContext context, EquipeMeeting meet) async {
	LocalModel m = context.read();
	try {
		var evs = await meet.loadEvents(m.id);
		await m.addSync(evs);
	} catch (e, s) {
		print(e);
		print(s);
		ScaffoldMessenger.of(context)
			.showSnackBar(const SnackBar(
				content: Text("Failed to load from Equipe"),
			));
	}
}