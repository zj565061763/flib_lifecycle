import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:meta/meta.dart';

abstract class FLifecycleWrapper {
  final FLifecycle lifecycle;
  bool _isDestroyed = false;

  FLifecycleWrapper(this.lifecycle) {
    if (lifecycle != null) {
      if (lifecycle.getCurrentState() == FLifecycleState.destroyed) {
        throw Exception('lifecycle is destroyed');
      }
      lifecycle.addObserver(_lifecycleObserver);
    }
  }

  bool get isDestroyed => _isDestroyed;

  void _lifecycleObserver(FLifecycleEvent event, FLifecycle lifecycle) {
    assert(this.lifecycle == lifecycle);

    if (_isDestroyed) {
      return;
    }

    if (event == FLifecycleEvent.onDestroy) {
      destroy();
    } else {
      onLifecycleEvent(event);
    }
  }

  @mustCallSuper
  void destroy() {
    if (_isDestroyed) {
      return;
    }

    _isDestroyed = true;
    if (lifecycle != null) {
      lifecycle.removeObserver(_lifecycleObserver);
    }
    onDestroy();
  }

  void onLifecycleEvent(FLifecycleEvent event);

  void onDestroy();
}
