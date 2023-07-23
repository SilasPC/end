import 'package:common/AbstractEventModel.dart';
import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:common/Event.dart';
import 'package:common/model.dart';
import 'package:common/util.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

const String serverUri = "localhost:3000";
const bool clientModelOnly = true;

class LocalModel
	extends AbstractEventModelWithRemoteSync<Model>
	with ChangeNotifier
{

   String _author = "default";
   String get author => _author;
   set author(val) {
      _author = val;
      SharedPreferences.getInstance()
         .then((sp) {
            sp.setString("author", _author);
         });
   }
	final ValueNotifier connection = ValueNotifier(false);
	// ChangeNotifier get connection => _connection;

	static LocalModel? _instance;
	static LocalModel get instance {
		if (_instance != null) {
			return _instance!;
		}
		
		io.Socket socket = io.io(
			serverUri,
			io.OptionBuilder()
				.setTransports(["websocket"])
				.disableAutoConnect()
				.build()
		);

		List<Event> evs = clientModelOnly
			? jlist_map(jsonDecode(eventData2), eventFromJSON)
			: [];
		LocalModel model = LocalModel._(socket, Model(), evs);

		socket.onDisconnect((_) {
			print("disconnected");
			model.connection.value = false;
		});

		socket.on("push", (json) {
			print("push $json");
			model.acceptPush(SyncPush.fromJSON(json));
		});

		socket.onConnect((_) {
			print("connected");
			model.connection.value = true;
			model.syncRemote();
		});
		
		if (!clientModelOnly)
			socket.connect();
		
		_instance = model;
		return model;
	}

	final io.Socket _socket;

	LocalModel._(this._socket, super.model, super.events);

	@override
	Future<SyncResult<Model>> $doRemoteSync(SyncRequest req) {
		Completer<SyncResult<Model>> c = Completer();
		_socket.emitWithAck("sync", req.toJsonString(), ack: (json) {
			c.complete(SyncResult.fromJSON(jsonDecode(json), Model.fromJson));
		});
		return c.future;
	}

	@override
	Model $reviveModel(JSON json) => Model.fromJson(json);

	@override
	void $onUpdate() {
		print("notify");
		notifyListeners();
	}

}

const String eventData = '[{"kind":"init","model":{"categories":{"LA":{"name":"LA","loops":[{"distance":30},{"distance":25}]},"LB":{"name":"LB","loops":[{"distance":30},{"distance":14}]},"LC":{"name":"LC","loops":[{"distance":25}]},"LD":{"name":"LD","loops":[{"distance":14}]}},"equipages":{"120":{"status":"WAITING","eid":120,"rider":"Susie Jacobsen","horse":"FADO","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"121":{"status":"WAITING","eid":121,"rider":"Dorte Jeeppesen","horse":"UNIQUE GYPSY HORSES SCARLETT","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"122":{"status":"WAITING","eid":122,"rider":"Helle Vistisen","horse":"BS SCHANITTA","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"123":{"status":"WAITING","eid":123,"rider":"Robert Ørsted","horse":"OLYMPOS VIAGRA","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"124":{"status":"WAITING","eid":124,"rider":"Sanne Klarborg","horse":"HAAHR\'S KALAHARI","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"125":{"status":"WAITING","eid":125,"rider":"Ditte Brinch Olsen","horse":"HAMLET-F","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"126":{"status":"WAITING","eid":126,"rider":"Marie Aster Knudsen","horse":"RHIANYDD GOCH - 1","dsqReason":null,"category":"LD","preExam":null,"loops":[],"currentLoop":null},"150":{"status":"WAITING","eid":150,"rider":"Ruth Palludan","horse":"BABYMONEY","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"151":{"status":"WAITING","eid":151,"rider":"Emma Sofie Lund Hansen","horse":"SR ZANATA OX","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"152":{"status":"WAITING","eid":152,"rider":"Anne-Mette Boel Hansen","horse":"ASTOR HØJBAK","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"153":{"status":"WAITING","eid":153,"rider":"Anita Sperber Jeppesen","horse":"THUMMELUMSEN DRYAD","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"154":{"status":"WAITING","eid":154,"rider":"Kristine Haugaard Nielsen","horse":"BILLESKAERS PEPSI CHERRY","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"155":{"status":"WAITING","eid":155,"rider":"Johanne Bakmann Sørensen","horse":"ØSTERMARKENS ZANTANO","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"156":{"status":"WAITING","eid":156,"rider":"Bodil Sørensen","horse":"BELLA ENGMARK - 1","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"157":{"status":"WAITING","eid":157,"rider":"Camilla Villadsen","horse":"ARIZONA","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"158":{"status":"WAITING","eid":158,"rider":"Betina Egeberg Varde Jensen","horse":"MIO","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"159":{"status":"WAITING","eid":159,"rider":"Poul Søren Andresen","horse":"EMBRACE","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"160":{"status":"WAITING","eid":160,"rider":"Merethe Louise Bønneland Neland","horse":"HRÓI FRA TJØRN - 2","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"161":{"status":"WAITING","eid":161,"rider":"Majbrit Nielsen","horse":"LÍF FRA STENSBÆK - 2","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"162":{"status":"WAITING","eid":162,"rider":"Allan Thomsen","horse":"ZOX SHARMEUR OX","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"163":{"status":"WAITING","eid":163,"rider":"Tine Romoi-Thomsen","horse":"XING","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"164":{"status":"WAITING","eid":164,"rider":"Simone La Fontaine","horse":"SUMMERTIME","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"165":{"status":"WAITING","eid":165,"rider":"Jette Bomann Jensen","horse":"GLOBAL PLAYBOY","dsqReason":null,"category":"LC","preExam":null,"loops":[],"currentLoop":null},"200":{"status":"WAITING","eid":200,"rider":"Esther Stegert","horse":"MARZOUQ NOIR OX","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"201":{"status":"WAITING","eid":201,"rider":"Rikke Kloster Pedersen","horse":"EMIRA AZIZAH OX - 1","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"202":{"status":"WAITING","eid":202,"rider":"Frederikke Schmidt-Jessen","horse":"DJEBEL EL RAZNA","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"203":{"status":"WAITING","eid":203,"rider":"Jane Anika Mammen","horse":"VICTORY OX","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"204":{"status":"WAITING","eid":204,"rider":"Heidi Fredsted Jessen","horse":"WW BIJOU OX","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"205":{"status":"WAITING","eid":205,"rider":"Amalie Fredsted Jessen","horse":"MADEMOISELLE - 1","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"206":{"status":"WAITING","eid":206,"rider":"Maja Fredsted Jessen","horse":"COVERLAND FEMME FATAL (DNK) - 2","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"207":{"status":"WAITING","eid":207,"rider":"Emilie Lildal Jørgensen","horse":"BELLE CONDRA SAUTEUR","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"208":{"status":"WAITING","eid":208,"rider":"Heidi Fredsted","horse":"ZODIAC OX","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"209":{"status":"WAITING","eid":209,"rider":"Lis Fogh","horse":"ADASH OX","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"210":{"status":"WAITING","eid":210,"rider":"Hanne Hein","horse":"BOSS","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"212":{"status":"WAITING","eid":212,"rider":"Maria HjortKronholm","horse":"TRIPLE A MALI","dsqReason":null,"category":"LB","preExam":null,"loops":[],"currentLoop":null},"300":{"status":"WAITING","eid":300,"rider":"Lone Pockendahl","horse":"MARLON B OX","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"301":{"status":"WAITING","eid":301,"rider":"Silas Pockendahl Christensen","horse":"TARIKH","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"302":{"status":"WAITING","eid":302,"rider":"Lena Rundqvist Pedersen","horse":"TCH-TCHING K","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"303":{"status":"WAITING","eid":303,"rider":"Charlotte Høllede Ørtoft Rosenbeck","horse":"TU MOSSUL OX","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"305":{"status":"WAITING","eid":305,"rider":"Niels Jørgen Møller Petersen","horse":"GHAZA OX","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"306":{"status":"WAITING","eid":306,"rider":"Emilie Hannecke Jensen","horse":"WW SHAZAM OX","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"307":{"status":"WAITING","eid":307,"rider":"Sara Hansen Jakobsen","horse":"CLYDE - 1","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"308":{"status":"WAITING","eid":308,"rider":"Tanja Van Willigen","horse":"NAMIBIA OX","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"309":{"status":"WAITING","eid":309,"rider":"Susanne Therkelsen","horse":"SALAH AL-DIN OX","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"310":{"status":"WAITING","eid":310,"rider":"Anne Wejlemand Nielsen","horse":"MILLION DOLLAR BABY","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"311":{"status":"WAITING","eid":311,"rider":"Ida Østrup Christoffersen","horse":"DY ZEPHYR OX - 1","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null},"312":{"status":"WAITING","eid":312,"rider":"Christina Østrup","horse":"BAHAMIN","dsqReason":null,"category":"LA","preExam":null,"loops":[],"currentLoop":null}},"rideName":"Skærbæk og Omegns Rideklub"}}]';
const String eventData2 =
"""
[{"kind":"init","author":"root","model":{
    "categories": {
        "40km": {
            "name": "40km",
            "loops": [
                {
                    "distance": 20
                },
                {
                    "distance": 20
                }
            ]
        },
        "20km": {
            "name": "20km",
            "loops": [
                {
                    "distance": 20
                }
            ]
        }
    },
    "equipages": {
        "1": {
            "status": "FINISHED",
            "eid": 1,
            "rider": "Anne Safft",
            "horse": "Wasim Jamaal",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266246,
                    "vet": 1666267286,
                    "data": {
                        "passed": true,
                        "hr1": 60,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269686,
                    "departure": 1666269746,
                    "arrival": 1666277175,
                    "vet": 1666277975,
                    "data": {
                        "passed": true,
                        "hr1": 60,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "2": {
            "status": "FINISHED",
            "eid": 2,
            "rider": "Marie Bäckerud",
            "horse": "E-mail L",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666267838,
                    "vet": 1666268485,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666270885,
                    "departure": 1666270945,
                    "arrival": 1666278601,
                    "vet": 1666279513,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "3": {
            "status": "FINISHED",
            "eid": 3,
            "rider": "Mona Lysell-Widjestam",
            "horse": "Gazca ox",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266988,
                    "vet": 1666267267,
                    "data": {
                        "passed": true,
                        "hr1": 56,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269667,
                    "departure": 1666269727,
                    "arrival": 1666275889,
                    "vet": 1666276389,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "4": {
            "status": "FINISHED",
            "eid": 4,
            "rider": "Annelie Eriksson",
            "horse": "Mohaymin",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666267000,
                    "vet": 1666267330,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269730,
                    "departure": 1666269790,
                    "arrival": 1666276698,
                    "vet": 1666276976,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "5": {
            "status": "FINISHED",
            "eid": 5,
            "rider": "Ellen Elvung",
            "horse": "Ora'miss S",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266901,
                    "vet": 1666267222,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269622,
                    "departure": 1666269682,
                    "arrival": 1666277173,
                    "vet": 1666277485,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "6": {
            "status": "RIDING",
            "eid": 6,
            "rider": "Christina Eriksson plym",
            "horse": "GOLDEN TIARA, AA, (25%), SWE",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": null,
                    "vet": null,
                    "data": null
                },
                {
                    "expDeparture": null,
                    "departure": null,
                    "arrival": null,
                    "vet": null,
                    "data": null
                }
            ],
            "currentLoop": 0
        },
        "8": {
            "status": "RIDING",
            "eid": 8,
            "rider": "Sandra Andersson",
            "horse": "Malicious Deceiver",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266247,
                    "vet": 1666267311,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269711,
                    "departure": 1666269771,
                    "arrival": null,
                    "vet": null,
                    "data": null
                }
            ],
            "currentLoop": 1
        },
        "9": {
            "status": "FINISHED",
            "eid": 9,
            "rider": "Liv Burdett",
            "horse": "El Mc Donald",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266949,
                    "vet": 1666267321,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269721,
                    "departure": 1666269781,
                    "arrival": 1666275858,
                    "vet": 1666276453,
                    "data": {
                        "passed": true,
                        "hr1": 56,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "10": {
            "status": "FINISHED",
            "eid": 10,
            "rider": "Alvin Mohager",
            "horse": "Penny Lane",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266949,
                    "vet": 1666267322,
                    "data": {
                        "passed": true,
                        "hr1": 40,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269722,
                    "departure": 1666269782,
                    "arrival": 1666275856,
                    "vet": 1666276454,
                    "data": {
                        "passed": true,
                        "hr1": 44,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "11": {
            "status": "FINISHED",
            "eid": 11,
            "rider": "Ebba Bota",
            "horse": "Paldruga Du Chene",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266979,
                    "vet": 1666267200,
                    "data": {
                        "passed": true,
                        "hr1": 60,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269600,
                    "departure": 1666269660,
                    "arrival": 1666275888,
                    "vet": 1666276250,
                    "data": {
                        "passed": true,
                        "hr1": 54,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "12": {
            "status": "FINISHED",
            "eid": 12,
            "rider": "Ulrika Lönnqvist",
            "horse": "Neirona Art",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666268058,
                    "vet": 1666268280,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666270680,
                    "departure": 1666270740,
                    "arrival": 1666279333,
                    "vet": 1666279656,
                    "data": {
                        "passed": true,
                        "hr1": 44,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "13": {
            "status": "FINISHED",
            "eid": 13,
            "rider": "Hannah Stenkvist",
            "horse": "Ars Vincendi",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666268058,
                    "vet": 1666268298,
                    "data": {
                        "passed": true,
                        "hr1": 44,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666270698,
                    "departure": 1666270758,
                    "arrival": 1666279334,
                    "vet": 1666279657,
                    "data": {
                        "passed": true,
                        "hr1": 44,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "14": {
            "status": "FINISHED",
            "eid": 14,
            "rider": "Görel Sigurdson",
            "horse": "Essemess",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666267831,
                    "vet": 1666268473,
                    "data": {
                        "passed": true,
                        "hr1": 44,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666270873,
                    "departure": 1666270933,
                    "arrival": 1666278599,
                    "vet": 1666279221,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "15": {
            "status": "FINISHED",
            "eid": 15,
            "rider": "Helena Jonsson",
            "horse": "King Peak ox",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666267000,
                    "vet": 1666267331,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269731,
                    "departure": 1666269791,
                    "arrival": 1666276697,
                    "vet": 1666276981,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "16": {
            "status": "FINISHED",
            "eid": 16,
            "rider": "Annika Kristland",
            "horse": "Shakib",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266951,
                    "vet": 1666267324,
                    "data": {
                        "passed": true,
                        "hr1": 40,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269724,
                    "departure": 1666269784,
                    "arrival": 1666277172,
                    "vet": 1666277479,
                    "data": {
                        "passed": true,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "17": {
            "status": "FINISHED",
            "eid": 17,
            "rider": "Minna Lannfelt",
            "horse": "Legolas S",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666266961,
                    "vet": 1666267418,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666269818,
                    "departure": 1666269878,
                    "arrival": 1666277174,
                    "vet": 1666278127,
                    "data": {
                        "passed": true,
                        "hr1": 48,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "18": {
            "status": "FINISHED",
            "eid": 18,
            "rider": "Sarah Nilsson",
            "horse": "Terri",
            "dsqReason": null,
            "category": "40km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666267832,
                    "vet": 1666268351,
                    "data": {
                        "passed": true,
                        "hr1": 36,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                },
                {
                    "expDeparture": 1666270751,
                    "departure": 1666270811,
                    "arrival": 1666278600,
                    "vet": 1666279448,
                    "data": {
                        "passed": true,
                        "hr1": 44,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 1
        },
        "32": {
            "status": "DNF",
            "eid": 32,
            "rider": "Agnieszka Peret",
            "horse": "Starbuck Des Alpes",
            "dsqReason": null,
            "category": "20km",
            "preExam": {
                "passed": true,
                "hr1": null,
                "hr2": null,
                "resp": null,
                "mucMem": null,
                "cap": null,
                "jug": null,
                "hydr": null,
                "gut": null,
                "sore": null,
                "wounds": null,
                "gait": null,
                "attitude": null
            },
            "loops": [
                {
                    "expDeparture": 1667732614,
                    "departure": 1666260060,
                    "arrival": 1666265559,
                    "vet": 1666266000,
                    "data": {
                        "passed": false,
                        "hr1": 52,
                        "hr2": null,
                        "resp": null,
                        "mucMem": null,
                        "cap": null,
                        "jug": null,
                        "hydr": null,
                        "gut": null,
                        "sore": null,
                        "wounds": null,
                        "gait": null,
                        "attitude": null
                    }
                }
            ],
            "currentLoop": 0
        }
    },
    "rideName": "Röddingeritten"
}}]
""";
