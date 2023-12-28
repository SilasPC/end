import 'dart:async';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/keys.dart';
import 'package:common/p2p/protocol.dart';
import 'package:common/p2p/sqlite_db.dart';
import 'package:common/util.dart';
import 'package:socket_io/socket_io.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'socket_peer.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final identity = PrivatePeerIdentity.server();
  final man = PeerManager<EnduranceModel>(
    identity,
    SqliteDatabase.create,
    MetaModel(),
  );

  Server io = Server();
  io.on("connection", (client_) {
    var client = client_ as Socket;
    print("connect");
    var peer = SocketPeer(client);
    man.addPeer(peer);

    setBinAck(client, "yield", (_) async {
      if (peer.ident?.perms.serverAdmin != true) {
        return SyncProtocol.NOT_OK;
      }
      var ok = await man.yieldTo(peer);
      return ok ? SyncProtocol.OK : SyncProtocol.NOT_OK;
    });

    setJsonAck(client, "auth", (json) {
      // VULN: plaintext / hardcoded
      // VULN: author duplication
      print(json);
      PeerIdentity? id;
      var ok = json["password"] == "password";
      if (ok) {
        id = PeerIdentity.signedBy(
          PublicKeyConverter().fromJson(json["key"]),
          json["name"] as String,
          PeerPermission.all,
          identity,
        );
      }
      return {"id": id};
    });
  });
  io.listen(3000);
}

void setJsonAck(
    dynamic client, String msg, FutureOr<JSON?>? Function(JSON) handler) {
  client.on(msg, (data) async {
    List dataList = data as List;
    var reqData = (dataList.first as List).cast<int>();
    var ack = dataList.last;
    var res = await handler(IJSON.fromBin(reqData));
    if (res != null) {
      ack(IJSON.toBin(res));
    }
  });
}

void setStringAck(
    dynamic client, String msg, FutureOr<String?>? Function(String) handler) {
  client.on(msg, (data) async {
    List dataList = data as List;
    var reqData = dataList.first;
    var ack = dataList.last;
    var res = await handler(reqData);
    if (res != null) {
      ack(res);
    }
  });
}

void setBinAck<T extends IJSON>(dynamic client, String msg,
    FutureOr<List<int>?>? Function(List<int>) handler) {
  client.on(msg, (data) async {
    List dataList = data as List;
    var reqData = (dataList.first as List).cast<int>();
    var ack = (dataList.last) as void Function(dynamic);
    var res = await handler(reqData);
    if (res != null) {
      ack(res);
    }
  });
}
