import 'package:piper/flutter_piper.dart';

import '../../data/auth_repository.dart';
import '../../domain/user.dart';

class AuthViewModel extends ViewModel {
  final AuthRepository _authRepo;

  AuthViewModel(this._authRepo);

  late final user = streamTo<User?>(_authRepo.userStream, initial: null);
  late final loginState = asyncState<void>();

  void login(String email, String password) {
    load(loginState, () => _authRepo.login(email, password));
  }

  void logout() {
    load(loginState, () => _authRepo.logout());
  }

  void clearError() {
    loginState.setEmpty();
  }
}
