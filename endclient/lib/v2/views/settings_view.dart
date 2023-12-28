import 'dart:io';

import 'package:common/models/Model.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/protocol.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/services/states.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:esys_client/v2/dialogs/equipe_import_sheet.dart';
import 'package:esys_client/v2/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  final MainAxisAlignment mainAxisAlignment;
  const SettingsView(
      {super.key, this.mainAxisAlignment = MainAxisAlignment.start});

  @override
  State<SettingsView> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsView> {
  final TextEditingController _servAddr = TextEditingController();

  late Settings set;

  @override
  void initState() {
    super.initState();
    set = context.read<Settings>().clone();
    _servAddr.text = set.serverURI;
  }

  PackageInfo? _packageInfo;
  PackageInfo? _loadPackageInfo() {
    if (_packageInfo != null) return _packageInfo;
    PackageInfo.fromPlatform()
        .then((i) => setState(() => _packageInfo = i))
        .catchError((_) {});
    return null;
  }

  static Future<void> saveCSV(BuildContext context) async {
    // IGNORED: CHECK: android saving works
    var m = context.read<LocalModel>();
    var sm = ScaffoldMessenger.of(context);
    var dir = await getApplicationDocumentsDirectory();
    var file = File("${dir.path}/endurance.csv");
    var data = m.model.toResultCSV();
    print(file);
    await file.writeAsString(data);
    sm.showSnackBar(const SnackBar(
      content: Text("Saved CSV results"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var model = context.read<LocalModel>();
      var conn = context.watch<ServerConnection>();
      var session = context.watch<SessionState>();
      var count = constraints.maxWidth ~/ 350;

      var general = [
        listGroupHeader("General"),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text("Enable notifications"),
          trailing: Switch(
            value: set.sendNotifs,
            onChanged: (val) => setState(() {
              set.sendNotifs = val;
              set.save();
            }),
          ),
        ),
        /* ListTile(
        									leading: const Icon(Icons.zoom_in),
        									title: const Text("Large UI"),
        									trailing: Switch(
        										value: set.largeUI,
        										onChanged: (val) => setState((){
        											set.largeUI = val;
        											set.save();
        										}),
        									),
        								), */
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text("Dark UI"),
          trailing: Switch(
            value: set.darkTheme,
            onChanged: (val) => setState(() {
              set.darkTheme = val;
              set.save();
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.stay_current_portrait),
          title: const Text("Gates keep screen alive"),
          trailing: Switch(
            value: set.useWakeLock,
            onChanged: (val) => setState(() {
              set.useWakeLock = val;
              set.save();
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text("Enable advanced mode"),
          trailing: Switch(
            value: set.showAdmin,
            onChanged: (val) => setState(() {
              set.showAdmin = val;
              set.save();
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: const Text("Reset to defaults"),
          onTap: () => setState(() {
            set = set.defaults()..save();
          }),
        ),
        ListTile(
          leading: const Icon(Icons.data_array),
          title: const Text("Save CSV"),
          onTap: () => saveCSV(context),
        ),
        listGroupHeader("About"),
        if (_loadPackageInfo() case PackageInfo info) ...[
          ListTile(
            title: const Text("Version"),
            subtitle: Text("${info.version}+${info.buildNumber}"),
          )
        ],
        ListTile(
          title: const Text("Protocol version"),
          trailing: Text(SyncProtocol.VERSION.toString()),
        ),
      ];
      List<Widget> admin() => [
            listGroupHeader("Connections"),
            ListTile(
                title: TextField(
              decoration: const InputDecoration(
                label: Text("Server address"),
              ),
              controller: _servAddr,
              onSubmitted: (val) {
                set.serverURI = val;
                set.save();
              },
            )),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text("Auto yield"),
              trailing: Switch(
                value: set.autoYield,
                onChanged: (val) => setState(() {
                  set
                    ..autoYield = val
                    ..save();
                }),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text("Use P2P"),
              trailing: Switch(
                value: set.useP2P,
                onChanged: (val) => setState(() {
                  set
                    ..useP2P = val
                    ..save();
                }),
              ),
            ),
            listGroupHeader("Session"),
            ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("New session"),
                subtitle: Text("Current: ${session.sessionId}"),
                onTap: () {
                  if (set.autoYield) {
                    setState(() {
                      set
                        ..autoYield = false
                        ..save();
                    });
                  }
                  session.leave();
                }),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text("Upload session"),
              subtitle: conn.sessionId != null
                  ? Text("Remote: ${conn.sessionId}")
                  : null,
              onTap: () => conn.yieldRemote(),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Load model..."),
              onTap: () => EquipeImportSheet.showAsBottomSheet(context),
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text("Resync"),
              onTap: () => model.resetModel(),
            ),
          ];

      return MyScaffold(
        body: Row(
          children: [
            if (count <= 1)
              Expanded(
                child: ListView(
                    children: [...general, if (set.showAdmin) ...admin()]),
              )
            else ...[
              Expanded(
                child: Card(
                    child: ListView(children: [
                  ...cardHeader("Settings"),
                  ...general,
                ])),
              ),
              if (set.showAdmin)
                Expanded(
                  child: Card(
                    child: ListView(
                      children: [...cardHeader("Advanced"), ...admin()],
                    ),
                  ),
                ),
            ]
            /* Card(
					 child: SizedBox(
						  width: 350,
						  child: Builder(builder: (context) {
							 var conn = context.watch<ServerConnection>();
							 return ListView(
								children: [
								  ...cardHeader("Connections"),
								  if (conn.peer case Peer p) _peerTile(p, "Server"),
								  for (var p in peers)
									 if (p != conn.peer) _peerTile(p)
								],
							 );
						  })), */
          ],
        ),
      );
    });
  }

  Widget _peerTile(Peer p, [String? name]) => ListTile(
        title: Text(name ?? p.id ?? "-"),
        // tileColor: p.connected ? Colors.green : Colors.red,
        subtitle: Text(p.connected ? p.state.name : "Disconnected"),
        onLongPress: () {
          if (p.connected) {
            p.disconnect();
          } else {
            p.connect();
          }
        },
        trailing: p.state.isConflict
            ? IconButton(
                icon: const Icon(Icons.cloud_download),
                onPressed: () {
                  context.read<PeerManager<EnduranceModel>>().yieldTo(p);
                },
              )
            : null,
      );
}
