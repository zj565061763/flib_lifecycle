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
      liveData: this,
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
  final FLiveData liveData;

  _ObserverWrapper({
    this.observer,
    this.lifecycle,
    this.liveData,
  })  : assert(observer != null),
        assert(lifecycle != null),
        assert(lifecycle.getCurrentState() != FLifecycleState.destroyed,
            'Can not add observer when lifecycle is destroyed'),
        assert(liveData != null) {
    liveData.addListener(liveDataListener);
    lifecycle.addObserver(lifecycleObserver);
  }

  void lifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle) {
    if (event == FLifecycleEvent.onDestroy) {
      liveData.removeObserver(observer);
    }
  }

  void liveDataListener() {
    observer(liveData.value);
  }

  void unregister() {
    liveData.removeListener(liveDataListener);
    lifecycle.removeObserver(lifecycleObserver);
  }
}
