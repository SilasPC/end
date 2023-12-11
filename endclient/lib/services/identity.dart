
import 'package:flutter/material.dart';

class IdentityService extends ChangeNotifier {

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
