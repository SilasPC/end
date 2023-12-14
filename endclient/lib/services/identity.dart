
import 'dart:io';

import 'package:common/p2p/protocol.dart';
import 'package:flutter/material.dart';

class IdentityService extends ChangeNotifier {

	final PrivatePeerIdentity _identity = PrivatePeerIdentity.client(Platform.localHostname);

	PrivatePeerIdentity? get identity => _identity;
	String get author => Platform.localHostname;

	IdentityService() {
		/* SharedPreferences.getInstance()
			.then(
				(sp) => sp.g
			) */
	}

	bool authorized = false;

	// TODO: implement
	Future<bool> isAuthorized() =>
		Future.value(authorized);

}
