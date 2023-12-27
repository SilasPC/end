import 'dart:async';
import 'package:crypto_keys/crypto_keys.dart';

typedef Predicate<T> = bool Function(T);
typedef Producer<T> = T Function();
typedef AsyncProducer<T> = Producer<FutureOr<T>>;
typedef VoidCallback = void Function();
typedef PubKey = RsaPublicKey;
typedef PrivKey = RsaPrivateKey;
