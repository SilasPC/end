
import 'dart:async';
import 'package:crypto_keys/crypto_keys.dart';
import 'util/typedefs.dart';
export 'util/unix.dart';
export 'util/json.dart';
export 'util/list.dart';
export 'util/typedefs.dart';

T? try_cast<T>(dynamic from) => from is T ? from : null;

T unimpl<T>([msg]) => throw UnimplementedError(msg);

P? maybe<T,P>(T? t, P? Function(T) f) =>
	t == null ? null : f(t);

Stream<T> futStream<T>(Iterable<Future<T>> ts) {
   var stream = StreamController<T>();
   int i = 1;
   for (var t in ts) {
      i++;
      t
         .then(
				(value) => stream.add(value),
				onError: (e) => stream.addError(e),
			)
         .whenComplete(() {
            if (--i == 0) {
               stream.close();
            }
         });
   }
   if (--i == 0) {
		stream.close();
	}
   return stream.stream;
}

bool nullOrEmpty(str) => str == null || str == "";

(PubKey, PrivKey) genKeyPair() {
   var pair = KeyPair.generateRsa(bitStrength: 512);
   return (pair.publicKey as PubKey, pair.privateKey as PrivKey);
}
