
import 'dart:convert';
import 'dart:io';
import 'package:common/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
/* 
class SettingsService {

	ValueNotifier<Settings> _current = ValueNotifier(Settings.defaults(this));
	ValueListenable<Settings> get it => _current;

	SettingsService() {
		_load();
	}

	Future<void> _save() async {
		var prefs = await SharedPreferences.getInstance();
		await prefs.setString("settings", _current.value.toJsonString());
	}

	Future<void> _load() async {
		var prefs = await SharedPreferences.getInstance();
		var val = prefs.getString("settings");
		if (val == null) return;
		try {
			set(Settings.fromJsonString(val, this));
		} catch (_) {
			print("loading settings failed");
			_save();
		}
	}

	void set(Settings value) {
		_current.value = value;
		print("settings = ${_current.value.toJsonString()}");
		_save();
	}

}
 */
class SettingsProvider extends StatefulWidget {
	const SettingsProvider({super.key, required this.child});

	final Widget child;

	@override
	SettingsProviderState createState() => SettingsProviderState();
}

class SettingsProviderState extends State<SettingsProvider> {

	late Settings _current;

	@override
	void initState() {
		super.initState();
		_current = Settings.defaults(this);
		_load();
	}

	Future<void> _save() async {
		var prefs = await SharedPreferences.getInstance();
		await prefs.setString("settings", _current.toJsonString());
	}

	Future<void> _load() async {
		var prefs = await SharedPreferences.getInstance();
		var val = prefs.getString("settings");
		if (val == null) return;
		try {
			set(Settings.fromJsonString(val, this));
		} catch (_) {
			print("loading settings failed");
			_save();
		}
	}

	void set(Settings value) {
		if (!mounted) return;
		setState(() {
			_current = value;
			print("settings = ${_current.toJsonString()}");
		});
		_save();
	}

	@override
	Widget build(BuildContext context) =>
		Provider.value(
			value: _current,
			child: widget.child,
		);

}

class Settings extends IJSON {

	final SettingsProviderState _provider;

	String serverURI;
	String author;
	bool darkTheme;
	bool showAdmin;
	bool sendNotifs;
	bool autoYield;
	bool useP2P;
	
	Settings(
		this._provider, 
		this.serverURI, 
		this.author, 
		this.darkTheme, 
		this.showAdmin, 
		this.sendNotifs,
		this.autoYield,
		this.useP2P,
	);
	Settings.defaults(this._provider):
		serverURI = "https://kastanie.ddns.net/esys",
		author = Platform.localHostname,
		darkTheme = false,
		showAdmin = false,
		sendNotifs = Platform.isAndroid || Platform.isIOS,
		autoYield = true,
		useP2P = true;

	// IGNORED: TODO: this is not very nice
	void setDefaults() {
		serverURI = "https://kastanie.ddns.net/esys";
		author = Platform.localHostname;
		darkTheme = false;
		showAdmin = false;
		sendNotifs = Platform.isAndroid || Platform.isIOS;
		autoYield = true;
		useP2P = true;
	}

	void save() {
		_provider.set(clone());
	}

	Settings clone() => Settings(
		_provider,
		serverURI,
		author,
		darkTheme,
		showAdmin,
		sendNotifs,
		autoYield,
		useP2P,
	);

	@override
	JSON toJson() => {
		'serverURI': serverURI,
		'author': author,
		'darkTheme': darkTheme,
		'showAdmin': showAdmin,
		'sendNotifs': sendNotifs,
		'autoYield': autoYield,
		'useP2P': useP2P,
	};

	factory Settings.fromJson(JSON json, SettingsProviderState provider) =>
		Settings(
			provider,
			json['serverURI'] as String,
			json['author'] as String,
			json['darkTheme'] as bool,
			json['showAdmin'] as bool,
			json['sendNotifs'] as bool,
			json['autoYield'] as bool,
			json['useP2P'] as bool,
		);

	factory Settings.fromJsonString(String json, SettingsProviderState provider) =>
		Settings.fromJson(jsonDecode(json), provider);

}
