
import 'dart:convert';
import 'dart:io';
import 'package:common/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
			print("loading settings $val");
			set(Settings.fromJsonString(val, this));
		} catch (_) {
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
	
	Settings(this._provider, this.serverURI, this.author, this.darkTheme, this.showAdmin, this.sendNotifs);
	Settings.defaults(this._provider):
		serverURI = "https://kastanie.ddns.net/esys",
		author = Platform.localHostname,
		darkTheme = false,
		showAdmin = false,
		sendNotifs = Platform.isAndroid || Platform.isIOS;

	// TODO: this is not very nice
	void setDefaults() {
		serverURI = "https://kastanie.ddns.net/esys";
		author = Platform.localHostname;
		darkTheme = false;
		showAdmin = false;
		sendNotifs = Platform.isAndroid || Platform.isIOS;
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
		sendNotifs
	);

	@override
	JSON toJson() => {
		'serverURI': serverURI,
		'author': author,
		'darkTheme': darkTheme,
		'showAdmin': showAdmin,
		'sendNotifs': sendNotifs,
	};

	factory Settings.fromJson(JSON json, SettingsProviderState provider) =>
		Settings(
			provider,
			json['serverURI'] as String,
			json['author'] as String,
			json['darkTheme'] as bool,
			json['showAdmin'] as bool,
			json['sendNotifs'] as bool,
		);

	factory Settings.fromJsonString(String json, SettingsProviderState provider) =>
		Settings.fromJson(jsonDecode(json), provider);

}
