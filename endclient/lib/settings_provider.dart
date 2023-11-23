
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

		var prefs = await SharedPreferences.getInstance();
		var val = prefs.getString("settings");
		if (val == null) return self;
		try {
			self.set(Settings.fromJsonString(val, self));
		} catch (_) {
			print("loading settings failed");
			self._save();
		}
		return self;
	}

	static SettingsService createSync() {
		var self = SettingsService._();

		SharedPreferences.getInstance()
			.then((prefs) {
				var val = prefs.getString("settings");
				if (val == null) return;
				try {
					self.set(Settings.fromJsonString(val, self));
				} catch (_) {
					print("loading settings failed");
					self._save();
				}
			});
		return self;
	}

	Future<void> _save() async {
		var prefs = await SharedPreferences.getInstance();
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
			json['showAdmin'] as bool,
			json['sendNotifs'] as bool,
			json['autoYield'] as bool,
			json['useP2P'] as bool,
			json['useWakeLock'] as bool,
		);

	factory Settings.fromJsonString(String json, SettingsService service) =>
		Settings.fromJson(jsonDecode(json), service);

}
