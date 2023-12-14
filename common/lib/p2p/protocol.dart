
import 'dart:typed_data';

import 'package:common/EventModel.dart';
import 'package:common/p2p/keys.dart';
import 'package:common/util.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:json_annotation/json_annotation.dart';

part "protocol.g.dart";

AlgorithmIdentifier SIGNING_ALG = algorithms.signing.rsa.sha256;

abstract class SyncProtocol {

	/// Current version of the protocol
	static const int VERSION = 1;

	/// SyncMsg payload
	static const String SYNC = "sync";
	/// PreSyncMsg payload
	static const String PRE_SYNC = "presync";
	/// no payload
	static const String ACK_SYNC = "syncack";

	static const List<int> OK = const [1];
	static const List<int> NOT_OK = const [0];

	static Iterable<String> get events => [SYNC, PRE_SYNC, ACK_SYNC];

}

@JsonSerializable()
class PrivatePeerIdentity {

	@PrivateKeyConverter()
	final RsaPrivateKey privateKey;
	final PeerIdentity identity; 
	final Signer<PrivateKey> signer;

	PrivatePeerIdentity(this.privateKey, this.identity):
		signer = privateKey.createSigner(SIGNING_ALG);

	// TODO: should not be available
	factory PrivatePeerIdentity.server(String name) =>
		PrivatePeerIdentity(serverPrivKey, PeerIdentity.server(name));
		
	// TODO: should not be available
	factory PrivatePeerIdentity.client(String name) =>
		PrivatePeerIdentity(clientPrivKey, PeerIdentity.client(name));

}

@JsonSerializable()
class PeerIdentity extends IJSON {
	
	@PublicKeyConverter()
	final RsaPublicKey key;
	@SignatureConverter()
	late final Signature signature;
	// TODO: name is not id, key is
	final String name;

	PeerIdentity(this.key, this.signature, this.name);

	// TODO: should not be available
	factory PeerIdentity.server(String name) =>
		PeerIdentity.signed(name, serverPubKey, serverSigner);
		
	// TODO: should not be available
	factory PeerIdentity.client(String name) =>
		PeerIdentity.signed(name, clientPubKey, serverSigner);
	
	PeerIdentity.signed(this.name, this.key, Signer<PrivateKey> signer) {
		// TODO: proper signature instead of this incorrect trash
		var data =  [
			...key.exponent.toString().codeUnits,
			...key.modulus.toString().codeUnits,
			...name.codeUnits,
		];
		signature = signer.sign(data);
	}

	bool verifySignature(RsaPublicKey signerKey) {
		var verifier = signerKey.createVerifier(SIGNING_ALG);
		var data = Uint8List.fromList([
			...key.exponent.toString().codeUnits,
			...key.modulus.toString().codeUnits,
			...name.codeUnits,
		]);
		return verifier.verify(data, signature);
	}

	JSON toJson() => _$PeerIdentityToJson(this);
	factory PeerIdentity.fromJson(JSON json) => _$PeerIdentityFromJson(json);

}

@JsonSerializable()
class PreSyncMsg extends IJSON {

	final PeerIdentity identity;
	final int protocolVersion;
	final int sessionId;
	final int resetCount;
	
	const PreSyncMsg(this.identity, this.sessionId, this.resetCount, {this.protocolVersion = SyncProtocol.VERSION});

	JSON toJson() => _$PreSyncMsgToJson(this);

	factory PreSyncMsg.fromBin(List<int> bin) => PreSyncMsg.fromJson(IJSON.fromBin(bin));
	factory PreSyncMsg.fromJson(JSON json) => _$PreSyncMsgFromJson(json);

}

class SyncMsg<M extends IJSON> extends IJSON {

	final List<Event<M>> evs, dels; // VULN: dels unsigned
	final List<Signature> sigs;
	SyncMsg(this.evs, this.dels, this.sigs);

	JSON toJson() => {
		"evs": evs,
		"dels": dels,
		"sigs": sigs.map(SignatureConverter().toJson).toList()
	};

	bool get isEmpty => evs.isEmpty && dels.isEmpty;
	bool get isNotEmpty => !isEmpty;

	factory SyncMsg.fromBin(List<int> bin, Reviver<Event<M>> reviver) => SyncMsg.fromJson(IJSON.fromBin(bin), reviver);
	factory SyncMsg.fromJson(JSON json, Reviver<Event<M>> reviver) =>
		SyncMsg(
			jlist_map(json["evs"], reviver),
			jlist_map(json["dels"], reviver),
			jlist_map(json["sigs"], (s) => SignatureConverter().fromJson(s as String)),
		);

}
