import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/mobile_auth_domain_provider.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/loading_button_content.dart';

/// Second login screen: the 6-digit code sent to [email] is entered
/// here in six separate boxes — typing auto-advances, backspace steps
/// back, and a pasted code spreads itself across the boxes and
/// verifies on its own once all six digits are in. On success,
/// AuthDomain has already resolved and cached this device's own
/// Account, so the app can go straight to the home screen with no
/// extra step.
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  String? _errorMessage;
  bool _isResending = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    // A multi-character value means a paste landed in this box (typing
    // can only ever produce one character at a time): spread the digits
    // across this box and the ones after it instead of cramming them
    // into one.
    if (value.length > 1) {
      _distributePaste(value, index);
      return;
    }
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _onBackspace(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  /// Spreads a pasted string across the boxes starting at [startIndex],
  /// one digit per box. Afterwards focus sits on the last filled box;
  /// if every box ended up full, verification starts immediately, the
  /// same as when the sixth digit is typed by hand. Assigning
  /// controller text programmatically does not re-trigger onChanged,
  /// so this cannot recurse back into itself.
  void _distributePaste(String pasted, int startIndex) {
    var target = startIndex;
    for (var j = 0; j < pasted.length && target < 6; j++, target++) {
      _controllers[target].text = pasted[j];
    }
    _focusNodes[target - 1].requestFocus();
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authDomainProvider).verifyLoginCode(
        email: widget.email,
        code: code,
      );
      ref.invalidate(currentAccountProvider);
      if (!mounted) return;
      context.go('/');
    } on DomainException catch (e) {
      setState(() {
        _errorMessage = e.message;
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }


  /// Sends a fresh code to the same email and resets the code boxes.
  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authDomainProvider).sendLoginCode(widget.email);
      if (!mounted) return;
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    } on DomainException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your code',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent to ${widget.email}',
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onBackspace(event, index),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontFamily: 'RobotoSlab',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? AppColors.brick
                                  : AppColors.hairlineStrong,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.rust,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onChanged(value, index),
                      ),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 13,
                    color: AppColors.brick,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: busyGuard(_verifyCode, _isVerifying),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: ButtonLoadingContent(
                  label: 'Verify and sign in',
                  loading: _isVerifying,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isResending ? null : _resendCode,
                child: const Text(
                  'Resend code',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w600,
                    color: AppColors.rust,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
