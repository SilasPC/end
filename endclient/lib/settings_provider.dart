
import 'dart:convert';
import 'dart:io';

import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/util.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocalModel.dart';
import 'util/input_modals.dart';

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
		} on FormatException catch (_) {
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
	
	Settings(this._provider, this.serverURI, this.author, this.darkTheme, this.showAdmin);
	Settings.defaults(this._provider):
		serverURI = "http://192.168.8.100:3000",
		author = "default",
		darkTheme = false,
		showAdmin = false;

	// TODO: this is not very nice
	void setDefaults() {
		serverURI = "http://192.168.8.100:3000";
		author = "default";
		darkTheme = false;
		showAdmin = false;
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
	);

	@override
	JSON toJson() => {
		'serverURI': serverURI,
		'author': author,
		'darkTheme': darkTheme,
		'showAdmin': showAdmin,
	};

	factory Settings.fromJson(JSON json, SettingsProviderState provider) =>
		Settings(
			provider,
			json['serverURI'] as String,
			json['author'] as String,
			json['darkTheme'] as bool,
			json['showAdmin'] as bool,
		);

	factory Settings.fromJsonString(String json, SettingsProviderState provider) =>
		Settings.fromJson(jsonDecode(json), provider);

}
