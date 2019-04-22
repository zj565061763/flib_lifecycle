import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flutter/foundation.dart';

typedef void FLiveDataObserver(dynamic value);

class FLiveData<T> extends ValueNotifier<T> {
  final Map<FLiveDataObserver, _ObserverWrapper> mapObserver = {};

  FLiveData(T value) : super(value);

  /// 添加观察者
  void addObserver(
    FLiveDataObserver observer,
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
            liveData: this,
          )
        : _ObserverWrapper(
            observer: observer,
            lifecycle: lifecycleOwner.getLifecycle(),
            liveData: this,
          );

    mapObserver[observer] = wrapper;

    assert(notifyAfterAdded != null);
    if (notifyAfterAdded) {
      wrapper.liveDataListener();
    }
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

class _LazyObserverWrapper extends _ObserverWrapper {
  dynamic _value;
  bool _changed = false;

  _LazyObserverWrapper({
    FLiveDataObserver observer,
    FLifecycle lifecycle,
    FLiveData liveData,
  }) : super(
          observer: observer,
          lifecycle: lifecycle,
          liveData: liveData,
        );

  @override
  void lifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle) {
    super.lifecycleObserver(event, lifecycle);
    _notifyIfNeed();
  }

  @override
  void liveDataListener() {
    _setValue(liveData.value);
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
        super.liveDataListener();
      }
    }
  }
}
