typedef FLifecycleObserver = void Function(
    FLifecycleEvent event, FLifecycle lifecycle);

abstract class FLifecycle {
  /// 添加观察者
  void addObserver(FLifecycleObserver observer);

  /// 移除观察者
  void removeObserver(FLifecycleObserver observer);

  /// 返回当前状态
  FLifecycleState getCurrentState();
}

abstract class FLifecycleRegistry extends FLifecycle {
  /// 标注为某个状态
  void markState(FLifecycleState state);

  /// 通知生命周期事件
  void handleLifecycleEvent(FLifecycleEvent event);
}

abstract class FLifecycleOwner {
  FLifecycle getLifecycle();
}

enum FLifecycleState {
  destroyed,
  initialized,
  created,
  started,
}

enum FLifecycleEvent {
  onCreate,
  onStart,
  onStop,
  onDestroy,
}
