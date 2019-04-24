import 'lifecycle.dart';

class SimpleLifecycle implements FLifecycle {
  /// 销毁后是否可以从新创建
  final bool recreateAfterDestroyed;

  final Map<FLifecycleObserver, _ObserverWrapper> _mapObserver = {};
  FLifecycleState _state = FLifecycleState.initialized;

  bool _syncing = false;
  bool _needResync = false;

  SimpleLifecycle({this.recreateAfterDestroyed = false});

  @override
  void addObserver(FLifecycleObserver observer) {
    assert(observer != null);

    if (_mapObserver.containsKey(observer)) {
      return;
    }

    if (_checkDestroyed()) {
      throw Exception('Can not add observer after destroyed');
    }

    final _ObserverWrapper wrapper = _ObserverWrapper(
      observer: observer,
      lifecycle: this,
    );
    _mapObserver[observer] = wrapper;

    final bool syncing = _checkSyncing();
    if (syncing) {
      // 不做任何处理
    } else {
      _sync();
    }
  }

  @override
  void removeObserver(FLifecycleObserver observer) {
    assert(observer != null);

    final _ObserverWrapper wrapper = _mapObserver.remove(observer);
    if (wrapper != null) {
      wrapper.removed = true;
    }
  }

  @override
  FLifecycleState getCurrentState() {
    return _state;
  }

  /// 标注当前状态
  void markState(FLifecycleState state) {
    _moveToState(state);
  }

  /// 通知生命周期事件
  void handleLifecycleEvent(FLifecycleEvent event) {
    assert(event != null);

    final FLifecycleState next = _getStateAfter(event);
    _moveToState(next);
  }

  void _moveToState(FLifecycleState next) {
    assert(next != null);
    if (_state == next) {
      return;
    }

    if (_checkDestroyed()) {
      throw Exception('Can not change state after destroyed');
    }

    _state = next;

    final bool syncing = _checkSyncing();
    if (syncing) {
      // 不做任何处理
    } else {
      _sync();
    }
  }

  void _sync() {
    _syncing = true;
    while (!_isSynced()) {
      _needResync = false;

      final List<_ObserverWrapper> list =
          List.from(_mapObserver.values, growable: false);

      for (_ObserverWrapper wrapper in list) {
        wrapper.sync(
          isCancel: _cancelCurrentSync,
        );

        if (_cancelCurrentSync()) {
          break;
        }
      }
    }
    _needResync = false;
    _syncing = false;
  }

  bool _isSynced() {
    if (_mapObserver.isEmpty) {
      return true;
    }

    final List<_ObserverWrapper> list =
        List.from(_mapObserver.values, growable: false);
    final int length = list.length;

    for (int i = length - 1; i >= 0; i--) {
      final _ObserverWrapper wrapper = list[i];
      if (wrapper.state != _state) {
        return false;
      }
    }

    return true;
  }

  bool _cancelCurrentSync() {
    return _needResync;
  }

  bool _checkSyncing() {
    if (_syncing) {
      _needResync = true;
      return true;
    }
    return false;
  }

  bool _checkDestroyed() {
    if (!recreateAfterDestroyed) {
      if (_state == FLifecycleState.destroyed) {
        return true;
      }
    }
    return false;
  }
}

FLifecycleState _getStateAfter(FLifecycleEvent event) {
  switch (event) {
    case FLifecycleEvent.onCreate:
    case FLifecycleEvent.onStop:
      return FLifecycleState.created;
    case FLifecycleEvent.onStart:
      return FLifecycleState.started;
    case FLifecycleEvent.onDestroy:
      return FLifecycleState.destroyed;
    default:
      throw Exception('Unexpected event value ${event}');
  }
}

FLifecycleEvent _upEvent(FLifecycleState state) {
  switch (state) {
    case FLifecycleState.destroyed:
    case FLifecycleState.initialized:
      return FLifecycleEvent.onCreate;
    case FLifecycleState.created:
      return FLifecycleEvent.onStart;
    case FLifecycleState.started:
      throw Exception('${state} state doesn\'t have a up event');
    default:
      throw Exception('Unexpected state value ${state}');
  }
}

FLifecycleEvent _downEvent(FLifecycleState state) {
  switch (state) {
    case FLifecycleState.destroyed:
    case FLifecycleState.initialized:
      throw Exception('${state} state doesn\'t have a down event');
    case FLifecycleState.created:
      return FLifecycleEvent.onDestroy;
    case FLifecycleState.started:
      return FLifecycleEvent.onStop;
    default:
      throw Exception('Unexpected state value ${state}');
  }
}

class _ObserverWrapper {
  final FLifecycleObserver observer;
  final FLifecycle lifecycle;
  FLifecycleState state;

  bool removed = false;

  _ObserverWrapper({
    this.observer,
    this.lifecycle,
  })  : assert(observer != null),
        assert(lifecycle != null),
        this.state = lifecycle.getCurrentState() == FLifecycleState.destroyed
            ? FLifecycleState.destroyed
            : FLifecycleState.initialized;

  void sync({bool isCancel()}) {
    assert(isCancel != null);

    while (true) {
      final FLifecycleState outState = lifecycle.getCurrentState();
      if (this.state == outState) {
        break;
      }

      if (removed) {
        break;
      }

      if (isCancel()) {
        break;
      }

      final FLifecycleEvent nextEvent = this.state.index < outState.index
          ? _upEvent(state)
          : _downEvent(state);

      final FLifecycleState nextState = _getStateAfter(nextEvent);
      this.state = nextState;
      observer(nextEvent, lifecycle);
    }
  }
}
