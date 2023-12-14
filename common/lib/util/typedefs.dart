
import 'dart:async';

typedef Predicate<T> = bool Function(T);
typedef Producer<T> = T Function();
typedef AsyncProducer<T> = Producer<FutureOr<T>>;
typedef VoidCallback = void Function();
