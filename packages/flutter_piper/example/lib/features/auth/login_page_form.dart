import 'package:flutter/material.dart';
import 'package:piper/flutter_piper.dart';

import 'auth_view_model.dart';

class LoginPageForm extends StatefulWidget {
  const LoginPageForm({super.key});

  @override
  State<LoginPageForm> createState() => _LoginPageFormState();
}

class _LoginPageFormState extends State<LoginPageForm> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _passwordController = TextEditingController(text: 'password');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.vm<AuthViewModel>();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 32),
          const Text(
            'Rivolo Todo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'State management made simple',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          _TextField.email(
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _TextField.password(
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 4) {
                return 'Password must be at least 4 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          // Error message and submit button
          StateBuilder<AsyncState<void>>(
            listenable: authVm.loginState.listenable,
            builder: (context, state, _) {
              void onSubmit() {
                if (_formKey.currentState!.validate()) {
                  authVm.login(_emailController.text, _passwordController.text);
                }
              }

              return state.when(
                empty: () => _SubmitButton(onPressed: onSubmit),
                data: (_) => _SubmitButton(onPressed: onSubmit),
                loading: () =>
                    const _SubmitButton(onPressed: null, isLoading: true),
                error: (message) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SubmitButton(onPressed: onSubmit),
                  ],
                ),
              );

              /* OR
              return switch (state) {
                AsyncEmpty<void>() ||
                AsyncData<void>() => _SubmitButton(onPressed: onSubmit),
                AsyncLoading<void>() => const _SubmitButton(isLoading: true),
                AsyncError<void>() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SubmitButton(onPressed: onSubmit),
                  ],
                ),
              };*/
            },
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  const _TextField({
    this.controller,
    required this.decoration,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  const _TextField.email({this.controller, this.validator})
    : decoration = const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType = TextInputType.emailAddress,
      obscureText = false;

  const _TextField.password({this.controller, this.validator})
    : decoration = const InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
      ),
      keyboardType = TextInputType.visiblePassword,
      obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: decoration,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SubmitButton({this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Sign In'),
      ),
    );
  }
}
