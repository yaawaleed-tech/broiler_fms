import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/web_auth_domain_provider.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/loading_button_content.dart';
import 'package:broiler_fms/presentation/shared/widgets/notice_banner.dart';

/// First login screen for web: email, then a 6-digit code is sent.
/// Identical login mechanism to mobile's EmailScreen, AuthDomain does
/// not know or care which platform called it. Only the layout differs,
/// centered on a wider screen rather than filling a phone's width.
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
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim().toLowerCase();
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
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.message != null) ...[
                      NoticeBanner(message: widget.message!),
                      const SizedBox(height: 16),
                    ],
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9A5A1F), // Dark terracotta/rust fill from mockup
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'BF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Broiler farm management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'RobotoSlab',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 14,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(),
                        focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.brick, width: 2)),
                        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.brick, width: 2)),
                      ),
                      onFieldSubmitted: (_) => _sendCode(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.brick,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: busyGuard(_sendCode, _isSending),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA8442A), // Terracotta/rust
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: ButtonLoadingContent(
                        label: 'Send login code',
                        loading: _isSending,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We’ll email you a one-time code to sign in. No password needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
