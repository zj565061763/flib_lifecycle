typedef void FLifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle);

abstract class FLifecycle {
  /// 添加观察者
  void addObserver(FLifecycleObserver observer);

  /// 移除观察者
  void removeObserver(FLifecycleObserver observer);

  /// 返回当前状态
  FLifecycleState getCurrentState();
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
