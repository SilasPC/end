import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

abstract class Edge<F extends Object, T extends Object> {
  final ServiceGraph g;
  final Service<F> from;
  final Service<T> to;

  Edge(this.g, this.from, this.to) {
    update();
  }

  void update();

  void dispose() {}
}

class ValueDependencyEdge<F extends Object, T extends Object>
    extends Edge<F, T> {
  F? _prev;
  final FutureOr<T> Function(F) _f;

  ValueDependencyEdge(super.g, super.from, super.to, this._f);

  @override
  void update() async {
    if (from._value != _prev && from._value != null) {
      var value = await _f((_prev = from._value)!);
      to.write(value);
    }
  }
}

class DerivedStreamEdge<F extends Object, T extends Object> extends Edge<F, T> {
  StreamSubscription<T>? _sub;

  F? _prev;
  final Stream<T> Function(F) _f;

  DerivedStreamEdge(super.g, super.from, super.to, this._f);

  @override
  void update() async {
    if (from._value != _prev && from._value != null) {
      _sub?.cancel();
      _sub = _f((_prev = from._value)!).listen(to.write);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
  }
}

class DerivedEdge<F extends Object, T extends Object> extends Edge<F, T> {
  final T Function(F) _f;

  DerivedEdge(super.g, super.from, super.to, this._f);

  @override
  void update() async {
    if (from._value != null) {
      to.write(_f(from._value!));
    }
  }
}

class DerivedListenableEdge<F extends Object, T extends Object>
    extends Edge<F, T> {
  F? _prev;
  ValueListenable<T>? _listenable;
  final ValueListenable<T> Function(F) _f;

  DerivedListenableEdge(super.g, super.from, super.to, this._f);

  @override
  void update() async {
    // print("update listenable");
    if (from._value != _prev && from._value != null) {
      _listenable?.removeListener(_listener);
      _listenable = _f((_prev = from._value)!);
      _listenable!.addListener(_listener);
      to.write(_listenable!.value);
    }
  }

  void _listener() {
    // print("listenable _listener");
    if (_listenable?.value case T value) {
      to.write(value);
    }
  }

  @override
  void dispose() {
    _listenable?.removeListener(_listener);
  }
}

class PipeEdge<F extends Object, T extends Object> extends Edge<F, T> {
  final void Function(F, T) _f;

  PipeEdge(super.g, super.from, super.to, this._f);

  @override
  void update() async {
    if (from._value == null || to._value == null) return;
    _f(from._value!, to._value!);
  }
}

class Service<T extends Object> extends ChangeNotifier {
  // ignore: unused_field
  final ServiceGraph _graph;

  T? _value;
  T? get value => _value;
  final List<Edge> _outEdges = [];

  Service(this._graph, T? value) {
    if (value != null) {
      write(value);
    }
  }

  Widget toProvider([Widget? child]) => AnimatedBuilder(
        animation: this,
        builder: (_, __) => Provider<T>.value(value: _value!, child: child),
      );

  void write(T value) {
    if (_value == value) return;
    willChangeValue(value);
    _value = value;
    updateEdges();
    notifyListeners();
    // print("wrote/notified $value");
  }

  void willChangeValue(T newValue) {}

  void updateEdges() {
    for (var edge in _outEdges) {
      edge.update();
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (var edge in _outEdges) {
      edge.dispose();
    }
  }
}

class ListenableService<T extends Listenable> extends Service<T> {
  ListenableService(super._graph, super._value);

  @override
  Widget toProvider([Widget? child]) => AnimatedBuilder(
        animation: this,
        builder: (_, __) =>
            ListenableProvider<T>.value(value: _value!, child: child),
      );

  @override
  void willChangeValue(T newValue) {
    _value?.removeListener(updateEdges);
    _value?.removeListener(notifyListeners);
    newValue.addListener(updateEdges);
    newValue.addListener(notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    _value?.removeListener(updateEdges);
    _value?.removeListener(notifyListeners);
  }
}

class ServiceGraph {
  final Map<Type, dynamic> _services = {};

  Service<T> get<T extends Object>() => _services[T];
  T read<T extends Object>() => _services[T].value!;

  void addListenable<T extends Listenable>(FutureOr<T> service) async {
    var node = _services[T] =
        ListenableService<T>(this, service is T ? service : null);
    if (service case Future<T> fut) {
      node.write(await fut);
    }
  }

  void add<T extends Object>(FutureOr<T> service) async {
    var node = _services[T] = Service<T>(this, service is T ? service : null);
    if (service case Future<T> fut) {
      node.write(await fut);
    }
  }

  void addListenableDep<F extends Object, T extends Listenable>(
      FutureOr<T> Function(F) f) {
    var node = _services[T] = ListenableService<T>(this, null);
    var from = _services[F]! as Service<F>;
    var edge = ValueDependencyEdge<F, T>(this, from, node, f);
    from._outEdges.add(edge);
  }

  void addDep<F extends Object, T extends Object>(FutureOr<T> Function(F) f) {
    var node = _services[T] = Service<T>(this, null);
    var from = _services[F]! as Service<F>;
    var edge = ValueDependencyEdge<F, T>(this, from, node, f);
    from._outEdges.add(edge);
  }

  void deriveStream<F extends Object, T extends Object>(
      Stream<T> Function(F) f) {
    var node = _services[T] = Service<T>(this, null);
    var from = _services[F]! as Service<F>;
    var edge = DerivedStreamEdge<F, T>(this, from, node, f);
    from._outEdges.add(edge);
  }

  void deriveListenable<F extends Object, T extends Object>(
      ValueListenable<T> Function(F) f) {
    var node = _services[T] = Service<T>(this, null);
    var from = _services[F]! as Service<F>;
    var edge = DerivedListenableEdge<F, T>(this, from, node, f);
    from._outEdges.add(edge);
  }

  void derive<F extends Object, T extends Object>(T Function(F) f) {
    var node = _services[T] = Service<T>(this, null);
    var from = _services[F]! as Service<F>;
    var edge = DerivedEdge<F, T>(this, from, node, f);
    from._outEdges.add(edge);
  }

  void pipe<F extends Object, T extends Object>(void Function(F, T) f) {
    var from = _services[F] as Service<F>;
    var edge = PipeEdge<F, T>(this, from, _services[T] as Service<T>, f);
    from._outEdges.add(edge);
  }

  void dispose() {
    for (var service in _services.values.cast<Service>()) {
      service.dispose();
    }
  }
}

class ServiceGraphProvider extends StatelessWidget {
  final ServiceGraph graph;
  final Widget child;

  const ServiceGraphProvider.value(
      {super.key, required this.graph, required this.child});

  @override
  Widget build(BuildContext context) {
    var prev = child;
    for (var service in graph._services.values.cast<Service>()) {
      prev = service.toProvider(prev);
    }
    return prev;
  }
}
