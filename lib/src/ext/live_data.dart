import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flutter/foundation.dart';

typedef FLiveDataObserver<T>(T value);

class FLiveData<T> extends ValueNotifier<T> {
  final Map<FLiveDataObserver, _ObserverWrapper> mapObserver = {};

  FLiveData(T value) : super(value);

  /// 添加观察者
  void addObserver(FLiveDataObserver<T> observer, FLifecycle lifecycle) {
    if (mapObserver.containsKey(observer)) {
      return;
    }

    mapObserver[observer] = _ObserverWrapper(
      observer: observer,
      lifecycle: lifecycle,
      valueNotifier: this,
    );
  }

  /// 移除观察者
  void removeObserver(FLiveDataObserver<T> observer) {
    final _ObserverWrapper wrapper = mapObserver.remove(observer);
    if (wrapper != null) {
      wrapper.unregister();
    }
  }
}

class _ObserverWrapper<T> {
  final FLiveDataObserver<T> observer;
  final FLifecycle lifecycle;
  final ValueNotifier<T> valueNotifier;

  _ObserverWrapper({
    this.observer,
    this.lifecycle,
    this.valueNotifier,
  })  : assert(observer != null),
        assert(lifecycle != null),
        assert(lifecycle.getCurrentState() != FLifecycleState.destroyed,
            'Can not add observer when lifecycle is destroyed'),
        assert(valueNotifier != null) {
    valueNotifier.addListener(valueNotifierListener);
    lifecycle.addObserver(lifecycleObserver);
  }

  void lifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle) {
    if (event == FLifecycleEvent.onDestroy) {
      unregister();
    }
  }

  void valueNotifierListener() {
    observer(valueNotifier.value);
  }

  void unregister() {
    valueNotifier.removeListener(valueNotifierListener);
    lifecycle.removeObserver(lifecycleObserver);
  }
}
