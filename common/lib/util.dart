
import 'dart:async';
export 'util/unix.dart';
export 'util/tuple.dart';
export 'util/json.dart';
export 'util/list.dart';

typedef Predicate<T> = bool Function(T);
typedef Producer<T> = T Function();
typedef AsyncProducer<T> = Producer<FutureOr<T>>;
typedef VoidCallback = void Function();


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
