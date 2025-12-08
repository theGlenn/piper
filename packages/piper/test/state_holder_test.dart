import 'package:flutter_test/flutter_test.dart';
import 'package:piper/piper.dart';

void main() {
  group('StateHolder', () {
    test('initializes with given value', () {
      final holder = StateHolder(42);
      expect(holder.value, 42);
      holder.dispose();
    });

    test('updates value', () {
      final holder = StateHolder(0);
      holder.value = 10;
      expect(holder.value, 10);
      holder.dispose();
    });

    test('update() applies transformation', () {
      final holder = StateHolder(5);
      holder.update((current) => current * 2);
      expect(holder.value, 10);
      holder.dispose();
    });

    test('listenable notifies on change', () {
      final holder = StateHolder(0);
      int notificationCount = 0;

      holder.notifier.addListener(() {
        notificationCount++;
      });

      holder.value = 1;
      holder.value = 2;

      expect(notificationCount, 2);
      holder.dispose();
    });

    test('does not notify when value is same', () {
      final holder = StateHolder(42);
      int notificationCount = 0;

      holder.notifier.addListener(() {
        notificationCount++;
      });

      holder.value = 42;

      expect(notificationCount, 0);
      holder.dispose();
    });
  });
}
