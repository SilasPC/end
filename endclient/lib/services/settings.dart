
import 'dart:convert';
import 'dart:io';
import 'package:common/util.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {

	late final ValueNotifier<Settings> _current;

	ValueListenable<Settings> get current => _current;

	SettingsService._() {
		_current = ValueNotifier(Settings.defaults(this));
	}
	static Future<SettingsService> create() async {
		var self = SettingsService._();
		await self._load();
		return self;
	}

	static SettingsService createSync() =>
		SettingsService._().._load();

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
			print("settings parse failed $val");
			_save();
		}
		await prefs.setString("settings", _current.value.toJsonString());
	}

	void set(Settings value) {
		_current.value = value;
		print("settings = ${_current.value.toJsonString()}");
		_save();
	}

}

class Settings extends IJSON {

	final SettingsService _service;

	String serverURI;
	String author;
	bool darkTheme;
	bool largeUI;
	bool showAdmin;
	bool sendNotifs;
	bool autoYield;
	bool useP2P;
	bool useWakeLock;

	Settings(
		this._service,
		this.serverURI,
		this.author,
		this.darkTheme,
		this.largeUI,
		this.showAdmin,
		this.sendNotifs,
		this.autoYield,
		this.useP2P,
		this.useWakeLock,
	);
	Settings.defaults(this._service):
		serverURI = "https://kastanie.ddns.net/esys",
		author = Platform.localHostname,
		darkTheme = false,
		largeUI = false,
		showAdmin = false,
		sendNotifs = Platform.isAndroid || Platform.isIOS,
		autoYield = true,
		useP2P = true,
		useWakeLock = true;

	// IGNORED: TODO: this is not very nice
	void setDefaults() {
		serverURI = "https://kastanie.ddns.net/esys";
		author = Platform.localHostname;
		darkTheme = false;
		largeUI = false;
		showAdmin = false;
		sendNotifs = Platform.isAndroid || Platform.isIOS;
		autoYield = true;
		useP2P = true;
		useWakeLock = true;
	}

	void save() {
		_service.set(clone());
	}

	Settings clone() => Settings(
		_service,
		serverURI,
		author,
		darkTheme,
		largeUI,
		showAdmin,
		sendNotifs,
		autoYield,
		useP2P,
		useWakeLock
	);

	@override
	JSON toJson() => {
		'serverURI': serverURI,
		'author': author,
		'darkTheme': darkTheme,
		'largeUI': largeUI,
		'showAdmin': showAdmin,
		'sendNotifs': sendNotifs,
		'autoYield': autoYield,
		'useP2P': useP2P,
		'useWakeLock': useWakeLock
	};

	factory Settings.fromJson(JSON json, SettingsService service) =>
		Settings(
			service,
			json['serverURI'] as String,
			json['author'] as String,
			json['darkTheme'] as bool,
			json['largeUI'] as bool,
			json['showAdmin'] as bool,
			json['sendNotifs'] as bool,
			json['autoYield'] as bool,
			json['useP2P'] as bool,
			json['useWakeLock'] as bool,
		);

	factory Settings.fromJsonString(String json, SettingsService service) =>
		Settings.fromJson(jsonDecode(json), service);

}
