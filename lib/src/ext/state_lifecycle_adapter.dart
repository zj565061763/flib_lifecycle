import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flib_lifecycle/src/lifecycle_impl.dart';
import 'package:flutter/material.dart';

class FStateLifecycleAdapter implements FLifecycleOwner, FStateLifecycle {
  final FLifecycleRegistry _lifecycleRegistry;
  bool _started;

  FStateLifecycleAdapter({FLifecycleRegistry lifecycleRegistry})
      : this._lifecycleRegistry =
            lifecycleRegistry ?? SimpleLifecycleRegistry();

  @override
  FLifecycle getLifecycle() {
    return _lifecycleRegistry;
  }

  @override
  void initState() {
    _lifecycleRegistry.handleLifecycleEvent(FLifecycleEvent.onCreate);
  }

  @override
  Widget build(BuildContext context) {
    if (_started == null) {
      _started = true;
      _notifyStartOrStop();
    }
  }

  @override
  void deactivate() {
    _started = !_started;
    _notifyStartOrStop();
  }

  @override
  void dispose() {
    _started = null;
    _lifecycleRegistry.handleLifecycleEvent(FLifecycleEvent.onDestroy);
  }

  void _notifyStartOrStop() {
    if (_started == null) {
      return;
    }
    if (_started) {
      _lifecycleRegistry.handleLifecycleEvent(FLifecycleEvent.onStart);
    } else {
      _lifecycleRegistry.handleLifecycleEvent(FLifecycleEvent.onStop);
    }
  }
}

abstract class FStateLifecycle {
  void initState();

  Widget build(BuildContext context);

  void deactivate();

  void dispose();
}
