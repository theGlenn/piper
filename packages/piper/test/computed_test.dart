import 'package:piper_state/piper_state.dart';
import 'package:test/test.dart';

void main() {
  group('Computed', () {
    test('derives from a single dependency', () {
      final count = StateHolder(1);
      final doubled = computed(() => count.value * 2);

      expect(doubled.value, 2);
      count.value = 5;
      expect(doubled.value, 10);
    });

    test('tracks multiple dependencies automatically', () {
      final first = StateHolder('Ada');
      final last = StateHolder('Lovelace');
      final full = computed(() => '${first.value} ${last.value}');

      expect(full.value, 'Ada Lovelace');
      first.value = 'Grace';
      expect(full.value, 'Grace Lovelace');
    });

    test('notifies listeners only when the result changes', () {
      final n = StateHolder(2);
      final isEven = computed(() => n.value.isEven);
      var notifications = 0;
      isEven.addListener(() => notifications++);

      n.value = 4; // still even -> no notification
      expect(notifications, 0);
      n.value = 5; // now odd -> one notification
      expect(notifications, 1);
    });

    test('supports computed-of-computed', () {
      final base = StateHolder(3);
      final doubled = computed(() => base.value * 2);
      final plusOne = computed(() => doubled.value + 1);

      expect(plusOne.value, 7);
      base.value = 10;
      expect(plusOne.value, 21);
    });

    test('configurable equals suppresses notification for equal new lists', () {
      bool listEquals(List<int> a, List<int> b) {
        if (a.length != b.length) return false;
        for (var i = 0; i < a.length; i++) {
          if (a[i] != b[i]) return false;
        }
        return true;
      }

      final source = StateHolder(0);
      // Allocates a fresh list every run; default == would notify every time.
      final evens = computed(
        () => [for (var i = 0; i <= source.value; i++) if (i.isEven) i],
        equals: listEquals,
      );
      var notifications = 0;
      evens.addListener(() => notifications++);

      expect(evens.value, [0]);
      source.value = 1; // still [0] -> equal -> no notification
      expect(notifications, 0);
      source.value = 2; // now [0, 2] -> changed -> one notification
      expect(notifications, 1);
    });

    test('throws when state is written during a tracked scope', () {
      final holder = StateHolder(0);
      expect(
        () => PiperTracker.track(() => holder.value = 1, (_) {}),
        throwsStateError,
      );
      // Writing outside tracking still works.
      holder.value = 2;
      expect(holder.value, 2);
    });

    test('detects cyclic dependencies', () {
      late Computed<int> a;
      final b = computed(() => a.value + 1);
      a = computed(() => b.value + 1);

      expect(() => a.value, throwsStateError);
    });

    test('re-tracks dependencies across branches', () {
      final useA = StateHolder(true);
      final a = StateHolder(1);
      final b = StateHolder(100);
      final result = computed(() => useA.value ? a.value : b.value);
      var notifications = 0;
      result.addListener(() => notifications++);

      expect(result.value, 1);

      // While using A, changes to B must not notify.
      b.value = 200;
      expect(notifications, 0);

      // Switch to B.
      useA.value = false;
      expect(result.value, 200);
    });
  });
}
