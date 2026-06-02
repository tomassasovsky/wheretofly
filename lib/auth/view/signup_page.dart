import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Account registration screen.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _handleController = TextEditingController();
  final _displayNameController = TextEditingController();
  var _navigatedAfterAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leaveIfAlreadyAuthenticated();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _leaveIfAlreadyAuthenticated() {
    if (!mounted || _navigatedAfterAuth) return;
    if (!context.read<AuthCubit>().state.isAuthenticated) return;
    _navigateAway();
  }

  void _navigateAway() {
    if (_navigatedAfterAuth) return;
    _navigatedAfterAuth = true;
    navigateAfterAuthentication(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authSignUpTitle)),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (previous, current) => current.isAuthenticated,
        listener: (context, state) => _navigateAway(),
        builder: (context, state) {
          if (state.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateAway();
            });
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.authEmail),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.authPassword),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _handleController,
                decoration: InputDecoration(labelText: l10n.authHandle),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: l10n.authDisplayName),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.isLoading || state.isAuthenticated
                    ? null
                    : () => context.read<AuthCubit>().signUp(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                          handle: _handleController.text.trim(),
                          displayName: _displayNameController.text.trim(),
                        ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.authSignUpTitle),
              ),
            ],
          );
        },
      ),
    );
  }
}
