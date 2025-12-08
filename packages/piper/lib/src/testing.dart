import 'view_model.dart';

/// Helper for testing ViewModels without the widget tree.
///
/// Automatically disposes all created ViewModels when [dispose] is called.
///
/// Example:
/// ```dart
/// void main() {
///   late TestScope scope;
///   late MockAuthRepo mockAuth;
///   late ProfileViewModel vm;
///
///   setUp(() {
///     scope = TestScope();
///     mockAuth = MockAuthRepo();
///     vm = scope.create(ProfileViewModel(mockAuth));
///   });
///
///   tearDown(() => scope.dispose());
///
///   test('updates user when stream emits', () {
///     final user = User(name: 'Test');
///     mockAuth.userController.add(user);
///     expect(vm.user.value, equals(user));
///   });
/// }
/// ```
class TestScope {
  final List<ViewModel> _vms = [];

  /// Creates and tracks a ViewModel for automatic disposal.
  T create<T extends ViewModel>(T vm) {
    _vms.add(vm);
    return vm;
  }

  /// Disposes all ViewModels created through this scope.
  void dispose() {
    for (final vm in _vms) {
      vm.dispose();
    }
    _vms.clear();
  }
}
