import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flutter/foundation.dart';

typedef void FLiveDataObserver(dynamic value);

class FLiveData<T> extends ValueNotifier<T> {
  final Map<FLiveDataObserver, _ObserverWrapper> mapObserver = {};

  FLiveData(T value) : super(value);

  /// 添加观察者
  void addObserver(FLiveDataObserver observer, FLifecycleOwner lifecycleOwner) {
    if (mapObserver.containsKey(observer)) {
      return;
    }

    mapObserver[observer] = _ObserverWrapper(
      observer: observer,
      lifecycle: lifecycleOwner.getLifecycle(),
      valueNotifier: this,
    );
  }

  /// 移除观察者
  void removeObserver(FLiveDataObserver observer) {
    final _ObserverWrapper wrapper = mapObserver.remove(observer);
    if (wrapper != null) {
      wrapper.unregister();
    }
  }
}

class _ObserverWrapper {
  final FLiveDataObserver observer;
  final FLifecycle lifecycle;
  final ValueNotifier valueNotifier;

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
