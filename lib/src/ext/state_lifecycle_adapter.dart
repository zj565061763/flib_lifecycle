import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flib_lifecycle/src/lifecycle_impl.dart';
import 'package:flutter/material.dart';

class FStateLifecycleAdapter implements FLifecycleOwner, FStateLifecycle {
  final FLifecycleRegistry _lifecycleRegistry;
  bool _started;
  bool _startedMarker;

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
    if (_startedMarker == null) {
      _startedMarker = true;
    }

    if (_startedMarker) {
      _startedMarker = false;
      _started = true;
      _notifyStartOrStop();
    }
  }

  @override
  void deactivate() {
    assert(_startedMarker = false);

    final bool expected = !_started;
    if (expected) {
      _startedMarker = true;
      // 等待build
    } else {
      _started = false;
      _notifyStartOrStop();
    }
  }

  @override
  void dispose() {
    _started = null;
    _startedMarker = null;
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
