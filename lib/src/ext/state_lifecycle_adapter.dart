import 'package:flib_lifecycle/src/lifecycle.dart';
import 'package:flib_lifecycle/src/lifecycle_impl.dart';
import 'package:flutter/material.dart';

class FStateLifecycleAdapter implements FLifecycleOwner, FStateLifecycle {
  final SimpleLifecycle _lifecycle = SimpleLifecycle();
  bool _started;

  @override
  FLifecycle getLifecycle() {
    return _lifecycle;
  }

  @override
  void initState() {
    _lifecycle.handleLifecycleEvent(FLifecycleEvent.onCreate);
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
    _lifecycle.handleLifecycleEvent(FLifecycleEvent.onDestroy);
  }

  void _notifyStartOrStop() {
    if (_started == null) {
      return;
    }
    if (_started) {
      _lifecycle.handleLifecycleEvent(FLifecycleEvent.onStart);
    } else {
      _lifecycle.handleLifecycleEvent(FLifecycleEvent.onStop);
    }
  }
}

abstract class FStateLifecycle {
  void initState();

  Widget build(BuildContext context);

  void deactivate();

  void dispose();
}
