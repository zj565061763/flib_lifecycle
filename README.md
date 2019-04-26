# About

一个用来管理生命周期的库，库中的实现逻辑参考了android中的生命周期管理的库

## Install

* git
```
  flib_lifecycle:
    git:
      url: git://github.com/zj565061763/flib_lifecycle
      ref: 1.0.0
```

* pub
```
  dependencies:
    flib_lifecycle: ^1.0.0
```

## Example
```dart
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> implements FLifecycleOwner {
  final FLifecycleRegistry _lifecycleRegistry = SimpleLifecycleRegistry();

  @override
  FLifecycle getLifecycle() {
    return _lifecycleRegistry;
  }

  @override
  void initState() {
    super.initState();
    // 分发事件
    _lifecycleRegistry.handleLifecycleEvent(FLifecycleEvent.onCreate);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    super.dispose();
    // 分发事件
    _lifecycleRegistry.handleLifecycleEvent(FLifecycleEvent.onDestroy);
  }
}
```