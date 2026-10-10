import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/mobile_auth_domain_provider.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/notice_banner.dart';

/// First login screen: the person enters their email, and a 6-digit
/// code is sent to it. No password anywhere in this app, matching the
/// OTP-only login decided at the very start of the project.
///
/// [message] is shown when present — set when arriving here from a
/// forced logout, so the person knows why they are signing in again.
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key, this.message});

  final String? message;

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authDomainProvider).sendLoginCode(email);
      if (!mounted) return;
      context.push('/login/code', extra: email);
    } on DomainException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.message != null) ...[
                NoticeBanner(message: widget.message!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Sign in',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and we will send you a 6-digit code.',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13.5,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _sendCode(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 12.5,
                    color: AppColors.brick,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSending ? null : _sendCode,
                child: _isSending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Send code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}