import 'dart:io';

import 'package:common/p2p/protocol.dart';
import 'package:flutter/material.dart';

class IdentityService extends ChangeNotifier {
  PrivatePeerIdentity _identity = PrivatePeerIdentity.anonymous();

  PrivatePeerIdentity get identity => _identity;
  String get author => Platform.localHostname;

  void setIdentity(PrivatePeerIdentity id) {
    _identity = id;
    notifyListeners();
  }

  IdentityService() {
    /* SharedPreferences.getInstance()
			.then(
				(sp) => sp.g
			) */
  }
}
