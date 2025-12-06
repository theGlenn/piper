import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:piper/piper.dart';

class TestViewModel extends ViewModel {
  late final counter = state(0);
  late final name = state('');

  void increment() => counter.update((c) => c + 1);
}

class StreamViewModel extends ViewModel {
  StreamViewModel(Stream<int> stream) {
    subscribe(stream, (value) => data.value = value);
  }

  late final data = state(0);
}

class TransformViewModel extends ViewModel {
  TransformViewModel(Stream<int> stream) {
    doubled = stateFrom(
      stream,
      initial: 0,
      transform: (value) => value * 2,
    );
  }

  late final StateHolder<int> doubled;
}

class StreamToViewModel extends ViewModel {
  StreamToViewModel(Stream<int> stream) {
    data = streamTo(stream, initial: 0);
  }

  late final StateHolder<int> data;
}

class StreamToTransformViewModel extends ViewModel {
  StreamToTransformViewModel(Stream<int> stream) {
    data = streamTo(stream, initial: 0, transform: (v) => v * 2);
  }

  late final StateHolder<int> data;
}

class StreamToAsyncViewModel extends ViewModel {
  StreamToAsyncViewModel(Stream<int> stream) {
    data = streamToAsync(stream);
  }

  late final AsyncStateHolder<int> data;
}

class StreamToAsyncTransformViewModel extends ViewModel {
  StreamToAsyncTransformViewModel(Stream<int> stream) {
    data = streamToAsync(stream, transform: (v) => v * 2);
  }

  late final AsyncStateHolder<int> data;
}

void main() {
  group('ViewModel', () {
    test('state() creates managed StateHolder', () {
      final scope = TestScope();
      final vm = scope.create(TestViewModel());

      expect(vm.counter.value, 0);
      vm.increment();
      expect(vm.counter.value, 1);

      scope.dispose();
    });

    test('subscribe() listens to stream', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamViewModel(controller.stream));

      controller.add(42);
      await Future.microtask(() {});

      expect(vm.data.value, 42);

      controller.close();
      scope.dispose();
    });

    test('stateFrom() transforms stream values', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(TransformViewModel(controller.stream));

      controller.add(5);
      await Future.microtask(() {});

      expect(vm.doubled.value, 10);

      controller.close();
      scope.dispose();
    });

    test('dispose() cancels subscriptions', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamViewModel(controller.stream));

      scope.dispose();

      // Should not throw even after disposal
      controller.add(42);
      await Future.microtask(() {});

      controller.close();
    });

    test('launch() creates managed task', () async {
      final scope = TestScope();
      final vm = scope.create(TestViewModel());

      final task = vm.launch(() async => 42);
      expect(await task.result, 42);

      scope.dispose();
    });

    test('dispose() cancels launched tasks', () async {
      final scope = TestScope();
      final vm = scope.create(TestViewModel());

      final task = vm.launch(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 42;
      });

      scope.dispose();

      expect(task.isCancelled, true);
      expect(await task.result, null);
    });
  });

  group('streamTo', () {
    test('updates state when stream emits', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToViewModel(controller.stream));

      expect(vm.data.value, 0);

      controller.add(42);
      await Future.microtask(() {});

      expect(vm.data.value, 42);

      controller.close();
      scope.dispose();
    });

    test('applies transform when provided', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToTransformViewModel(controller.stream));

      controller.add(5);
      await Future.microtask(() {});

      expect(vm.data.value, 10);

      controller.close();
      scope.dispose();
    });

    test('subscription is cancelled on dispose', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToViewModel(controller.stream));

      scope.dispose();

      // Should not update after disposal
      controller.add(42);
      await Future.microtask(() {});

      expect(vm.data.value, 0);

      controller.close();
    });
  });

  group('streamToAsync', () {
    test('starts in loading state', () {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToAsyncViewModel(controller.stream));

      expect(vm.data.isLoading, true);
      expect(vm.data.hasData, false);

      controller.close();
      scope.dispose();
    });

    test('transitions to data on emission', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToAsyncViewModel(controller.stream));

      controller.add(42);
      await Future.microtask(() {});

      expect(vm.data.isLoading, false);
      expect(vm.data.hasData, true);
      expect(vm.data.dataOrNull, 42);

      controller.close();
      scope.dispose();
    });

    test('transitions to error on stream error', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToAsyncViewModel(controller.stream));

      controller.addError(Exception('Test error'));
      await Future.microtask(() {});

      expect(vm.data.hasError, true);
      expect(vm.data.errorOrNull, contains('Test error'));

      controller.close();
      scope.dispose();
    });

    test('applies transform when provided', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToAsyncTransformViewModel(controller.stream));

      controller.add(5);
      await Future.microtask(() {});

      expect(vm.data.dataOrNull, 10);

      controller.close();
      scope.dispose();
    });

    test('subscription is cancelled on dispose', () async {
      final scope = TestScope();
      final controller = StreamController<int>.broadcast();
      final vm = scope.create(StreamToAsyncViewModel(controller.stream));

      scope.dispose();

      // Should still be loading (not updated) after disposal
      controller.add(42);
      await Future.microtask(() {});

      expect(vm.data.isLoading, true);

      controller.close();
    });
  });

  group('TestScope', () {
    test('create() returns the ViewModel', () {
      final scope = TestScope();
      final vm = scope.create(TestViewModel());

      expect(vm, isA<TestViewModel>());
      scope.dispose();
    });

    test('dispose() disposes all ViewModels', () {
      final scope = TestScope();
      final vm1 = scope.create(TestViewModel());
      final vm2 = scope.create(TestViewModel());

      final task1 = vm1.launch(() async {
        await Future.delayed(const Duration(seconds: 1));
        return 1;
      });
      final task2 = vm2.launch(() async {
        await Future.delayed(const Duration(seconds: 1));
        return 2;
      });

      scope.dispose();

      expect(task1.isCancelled, true);
      expect(task2.isCancelled, true);
    });
  });
}
