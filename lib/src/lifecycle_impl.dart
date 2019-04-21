import 'lifecycle.dart';

class SimpleLifecycle implements FLifecycle {
  final List<_ObserverWrapper> _listObserver = [];
  FLifecycleState _state = FLifecycleState.initialized;

  bool _syncing = false;
  bool _needResync = false;

  @override
  void addObserver(FLifecycleObserver observer) {
    assert(observer != null);
    for (_ObserverWrapper item in _listObserver) {
      if (item.observer == observer) {
        return;
      }
    }

    final FLifecycleState state = _state == FLifecycleState.destroyed
        ? FLifecycleState.destroyed
        : FLifecycleState.initialized;

    final _ObserverWrapper wrapper = _ObserverWrapper(
      observer: observer,
      state: state,
    );

    _listObserver.add(wrapper);

    final bool willResync = _checkWillResync();
    if (willResync) {
      // 不做任何处理
    } else {
      _sync();
    }
  }

  @override
  void removeObserver(FLifecycleObserver observer) {
    assert(observer != null);

    final int index = _listObserver.indexWhere((item) {
      return item.observer == observer;
    });

    if (index >= 0) {
      final _ObserverWrapper wrapper = _listObserver.removeAt(index);
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

    _state = next;

    final bool willResync = _checkWillResync();
    if (willResync) {
      // 不做任何处理
    } else {
      _sync();
    }
  }

  void _sync() {
    _syncing = true;
    while (!_isSynced()) {
      _needResync = false;

      final List<_ObserverWrapper> listCopy =
          List.from(_listObserver, growable: false);

      for (_ObserverWrapper item in listCopy) {
        item.sync(
          getLifecycle: () => this,
          isCancel: () => _needResync,
        );

        if (_needResync) {
          break;
        }
      }
    }
    _needResync = false;
    _syncing = false;
  }

  bool _checkWillResync() {
    if (_syncing) {
      _needResync = true;
      return true;
    }
    return false;
  }

  bool _isSynced() {
    if (_listObserver.isEmpty) {
      return true;
    }

    for (int i = _listObserver.length - 1; i >= 0; i--) {
      final _ObserverWrapper item = _listObserver[i];
      if (item.state != _state) {
        return false;
      }
    }

    return true;
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

typedef FLifecycle _getLifecycle();
typedef bool _isCancel();

class _ObserverWrapper {
  final FLifecycleObserver observer;
  FLifecycleState state;
  bool removed = false;

  _ObserverWrapper({
    this.observer,
    this.state,
  })  : assert(observer != null),
        assert(state == FLifecycleState.initialized ||
            state == FLifecycleState.destroyed);

  void sync({
    _getLifecycle getLifecycle,
    _isCancel isCancel,
  }) {
    assert(getLifecycle != null);

    while (true) {
      final FLifecycleState outState = getLifecycle().getCurrentState();
      if (this.state == outState) {
        break;
      }

      if (removed) {
        break;
      }

      if (isCancel != null && isCancel()) {
        break;
      }

      final FLifecycleEvent nextEvent = this.state.index < outState.index
          ? _upEvent(state)
          : _downEvent(state);

      final FLifecycleState nextState = _getStateAfter(nextEvent);
      observer(nextEvent, getLifecycle());
      this.state = nextState;
    }
  }
}
