import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // Step 1: Request, Step 2: OTP, Step 3: Reset
  final _formKey1 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Input Controllers
  final _usernameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Shared state variables
  String _maskedEmail = '';
  int? _userId;
  String _errorMessage = '';

  // Timer variables
  Timer? _countdownTimer;
  int _remainingSeconds = 600; // 10 minutes
  String _timerText = '10:00';

  @override
  void dispose() {
    _usernameController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = 600;
      _timerText = '10:00';
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _remainingSeconds--;
          final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
          final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
          _timerText = '$minutes:$seconds';
        });
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
  }

  // --- Step 1 Action ---
  Future<void> _handleRequestOtp() async {
    if (!_formKey1.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.forgotPassword(_usernameController.text.trim());

    if (result['success']) {
      setState(() {
        _maskedEmail = result['maskedEmail'] ?? '';
        _currentStep = 2;
        _startTimer();
      });
      // Clear OTP inputs
      for (var controller in _otpControllers) {
        controller.clear();
      }
      // Focus first digit box after frame builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNodes[0].requestFocus();
      });
      
      _showToast(result['message'] ?? 'OTP sent to your registered Gmail address.');
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to send OTP';
      });
    }
  }

  // --- Step 2 Action ---
  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the OTP.';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyOtp(_usernameController.text.trim(), otp);

    if (result['success']) {
      _stopTimer();
      setState(() {
        _userId = result['userId'];
        _currentStep = 3;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'OTP verification failed';
      });
    }
  }

  // --- Step 3 Action ---
  Future<void> _handleResetPassword() async {
    if (!_formKey3.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (_userId == null) {
      setState(() {
        _errorMessage = 'Session expired. Please start over.';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.resetPasswordWithOtp(
      _userId!,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    if (result['success']) {
      _showToast('Password reset successfully! Redirecting to login...');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to reset password';
      });
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF007F70),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Dynamic Password Strength Calculator
  Map<String, dynamic> _getPasswordStrength(String password) {
    if (password.isEmpty) {
      return {'score': 0, 'label': '', 'color': Colors.transparent};
    }
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    final strengthMap = [
      {'score': 0, 'label': 'Weak', 'color': Colors.red[400]},
      {'score': 1, 'label': 'Weak', 'color': Colors.red[400]},
      {'score': 2, 'label': 'Fair', 'color': Colors.orange[400]},
      {'score': 3, 'label': 'Good', 'color': Colors.amber[600]},
      {'score': 4, 'label': 'Strong', 'color': Colors.green[500]},
    ];
    return strengthMap[score];
  }

  void _goBack() {
    setState(() {
      _errorMessage = '';
    });
    if (_currentStep == 1) {
      Navigator.pop(context);
    } else {
      if (_currentStep == 2) {
        _stopTimer();
      }
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const tealColor = Color(0xFF007F70);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: Text(
          _currentStep == 1 ? 'Forgot Password' : (_currentStep == 2 ? 'Enter OTP' : 'Set New Password'),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top teal curve (similar to login)
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: tealColor,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(80),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Password Recovery',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentStep == 1 
                                ? 'Verify account with OTP'
                                : (_currentStep == 2 ? 'Check your registered Gmail' : 'Choose a strong password'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Step Indicator Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    _buildStepIndicator(1, _currentStep >= 1),
                    _buildStepLine(_currentStep > 1),
                    _buildStepIndicator(2, _currentStep >= 2),
                    _buildStepLine(_currentStep > 2),
                    _buildStepIndicator(3, _currentStep >= 3),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error banner if any
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Dynamic wizard steps content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildStepContent(authProvider, tealColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepNumber, bool isActive) {
    const tealColor = Color(0xFF007F70);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _currentStep > stepNumber
            ? tealColor
            : (isActive ? Colors.white : Colors.grey[100]),
        border: Border.all(
          color: isActive ? tealColor : Colors.grey[300]!,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: _currentStep > stepNumber
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: isActive ? (_currentStep == stepNumber ? tealColor : Colors.white) : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    const tealColor = Color(0xFF007F70);
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? tealColor : Colors.grey[200],
      ),
    );
  }

  Widget _buildStepContent(AuthProvider authProvider, Color themeColor) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(authProvider, themeColor);
      case 2:
        return _buildStep2(authProvider, themeColor);
      case 3:
        return _buildStep3(authProvider, themeColor);
      default:
        return Container();
    }
  }

  // --- STEP 1: Request OTP Form ---
  Widget _buildStep1(AuthProvider authProvider, Color themeColor) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Username or Email',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Enter username or email',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username or email is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          authProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _handleRequestOtp,
                  child: const Text(
                    'SEND OTP',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ),
                ),
        ],
      ),
    );
  }

  // --- STEP 2: Verify OTP Form ---
  Widget _buildStep2(AuthProvider authProvider, Color themeColor) {
    final timerExpired = _remainingSeconds <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'A 6-digit verification code has been sent to:',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          _maskedEmail,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),

        // Countdown Timer Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: timerExpired ? Colors.red[50] : const Color(0xFF007F70).withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: timerExpired ? Colors.red[100]! : const Color(0xFF007F70).withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timerExpired ? 'Code expired' : 'Code expires in',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: timerExpired ? Colors.red[700] : Colors.grey[700],
                ),
              ),
              Text(
                _timerText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: timerExpired ? Colors.red[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6 digit digit entries
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpDigitField(index)),
        ),
        const SizedBox(height: 32),

        authProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: timerExpired ? null : _handleVerifyOtp,
                child: const Text(
                  'VERIFY OTP',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                ),
              ),
        const SizedBox(height: 16),

        // Resend Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.refresh, size: 18, color: Colors.black54),
          label: const Text(
            'RESEND OTP',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: authProvider.isLoading ? null : _handleRequestOtp,
        ),
      ],
    );
  }

  Widget _buildOtpDigitField(int index) {
    const tealColor = Color(0xFF007F70);
    return SizedBox(
      width: 45,
      height: 52,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding: EdgeInsets.zero,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: tealColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          }

          // Auto verify if all are filled
          if (_otpControllers.every((c) => c.text.isNotEmpty)) {
            _handleVerifyOtp();
          }
        },
      ),
    );
  }

  // --- STEP 3: Reset Password Form ---
  Widget _buildStep3(AuthProvider authProvider, Color themeColor) {
    final strength = _getPasswordStrength(_newPasswordController.text);

    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Password',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              hintText: 'Enter new password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'New password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onChanged: (val) {
              // Trigger rebuild to update password strength bar
              setState(() {});
            },
          ),
          
          // Password Strength Bar
          if (_newPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(4, (index) {
                      final segmentScore = index + 1;
                      final isColored = segmentScore <= strength['score'];
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: isColored ? strength['color'] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strength['label'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: strength['color'] ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 20),

          const Text(
            'Confirm Password',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm password is required';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 32),

          authProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _handleResetPassword,
                  child: const Text(
                    'SAVE NEW PASSWORD',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ),
                ),
        ],
      ),
    );
  }
}
