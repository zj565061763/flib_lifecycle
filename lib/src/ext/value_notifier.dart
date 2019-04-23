import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flutter/foundation.dart';

typedef void FValueNotifierObserver(dynamic value);

class FValueNotifier<T> extends ValueNotifier<T> {
  final Map<FValueNotifierObserver, _ObserverWrapper> mapObserver = {};

  FValueNotifier(T value) : super(value);

  /// 添加观察者
  void addObserver(
    FValueNotifierObserver observer,
    FLifecycleOwner lifecycleOwner, {
    bool notifyAfterAdded = true,
    bool notifyLazy = true,
  }) {
    if (mapObserver.containsKey(observer)) {
      return;
    }

    assert(notifyLazy != null);
    final _ObserverWrapper wrapper = notifyLazy
        ? _LazyObserverWrapper(
            observer: observer,
            lifecycle: lifecycleOwner.getLifecycle(),
            valueNotifier: this,
          )
        : _ObserverWrapper(
            observer: observer,
            lifecycle: lifecycleOwner.getLifecycle(),
            valueNotifier: this,
          );

    mapObserver[observer] = wrapper;

    assert(notifyAfterAdded != null);
    if (notifyAfterAdded) {
      wrapper.valueListener();
    }
  }

  /// 移除观察者
  void removeObserver(FValueNotifierObserver observer) {
    final _ObserverWrapper wrapper = mapObserver.remove(observer);
    if (wrapper != null) {
      wrapper.unregister();
    }
  }
}

class _ObserverWrapper {
  final FValueNotifierObserver observer;
  final FLifecycle lifecycle;
  final FValueNotifier valueNotifier;

  _ObserverWrapper({
    this.observer,
    this.lifecycle,
    this.valueNotifier,
  })  : assert(observer != null),
        assert(lifecycle != null),
        assert(lifecycle.getCurrentState() != FLifecycleState.destroyed,
            'Can not add observer when lifecycle is destroyed'),
        assert(valueNotifier != null) {
    valueNotifier.addListener(valueListener);
    lifecycle.addObserver(lifecycleObserver);
  }

  void lifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle) {
    if (event == FLifecycleEvent.onDestroy) {
      valueNotifier.removeObserver(observer);
    }
  }

  void valueListener() {
    observer(valueNotifier.value);
  }

  void unregister() {
    valueNotifier.removeListener(valueListener);
    lifecycle.removeObserver(lifecycleObserver);
  }
}

class _LazyObserverWrapper extends _ObserverWrapper {
  dynamic _value;
  bool _changed = false;

  _LazyObserverWrapper({
    FValueNotifierObserver observer,
    FLifecycle lifecycle,
    FValueNotifier valueNotifier,
  }) : super(
          observer: observer,
          lifecycle: lifecycle,
          valueNotifier: valueNotifier,
        );

  @override
  void lifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle) {
    super.lifecycleObserver(event, lifecycle);
    _notifyIfNeed();
  }

  @override
  void valueListener() {
    _setValue(valueNotifier.value);
    _notifyIfNeed();
  }

  void _setValue(dynamic value) {
    if (_value != value) {
      this._value = value;
      this._changed = true;
    }
  }

  void _notifyIfNeed() {
    if (_changed) {
      final FLifecycleState state = lifecycle.getCurrentState();
      if (state.index >= FLifecycleState.started.index) {
        _changed = false;
        super.valueListener();
      }
    }
  }
}
