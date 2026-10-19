import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/web_auth_domain_provider.dart';
import 'package:broiler_fms/domain/web_current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/loading_button_content.dart';

class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  String? _errorMessage;
  bool _isResending = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
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

    // Check if complete
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _onBackspace(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
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
      ref.invalidate(webCurrentAccountProvider);
      if (!mounted) return;
      context.go('/');
    } on DomainException catch (e) {
      setState(() {
        _errorMessage = e.message;
        for (var controller in _controllers) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 32),
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _errorMessage != null ? AppColors.brick : AppColors.hairlineStrong),
                              ),
                            ),
                            onChanged: (value) => _onChanged(value, index),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.brick,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: busyGuard(_verifyCode, _isVerifying),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA8442A),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: ButtonLoadingContent(
                      label: 'Verify and sign in',
                      loading: _isVerifying,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isResending ? null : _resendCode,
                    child: const Text('Resend code', style: TextStyle(color: Color(0xFFA8442A))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
