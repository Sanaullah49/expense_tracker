import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/settings_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _localAuth = LocalAuthentication();
  Timer? _lockoutTimer;

  String _enteredPin = '';
  bool _isAuthenticating = false;
  bool _showError = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeLockState();
    _checkBiometricAvailability();
  }

  Future<void> _initializeLockState() async {
    final settings = context.read<SettingsProvider>();
    await settings.refreshPinLockout(notify: false);
    _startLockoutTimerIfNeeded();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!mounted) return;
      setState(() {
        _biometricAvailable = canCheck && isDeviceSupported;
      });

      debugPrint('Biometric available: $_biometricAvailable');

      if (mounted) {
        final settings = context.read<SettingsProvider>();
        if (settings.biometricEnabled &&
            !_biometricAvailable &&
            !settings.hasPin) {
          await settings.setBiometricEnabled(false);
          if (mounted) {
            _onAuthSuccess();
          }
          return;
        }

        if (settings.biometricEnabled && _biometricAvailable) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _authenticateWithBiometric();
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
        });
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating || !_biometricAvailable) return;

    final settings = context.read<SettingsProvider>();
    if (!settings.biometricEnabled) {
      debugPrint('Biometric not enabled in settings');
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Expense Tracker',
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: false,
      );

      debugPrint('Biometric authentication result: $didAuthenticate');

      if (didAuthenticate && mounted) {
        settings.markUnlockVerified();
        _onAuthSuccess();
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric error: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _onPinButtonPressed(String value) {
    final settings = context.read<SettingsProvider>();
    if (settings.isPinLockedOut) return;

    HapticFeedback.lightImpact();

    if (value == 'delete') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _showError = false;
        });
      }
    } else if (value == 'biometric') {
      _authenticateWithBiometric();
    } else {
      if (_enteredPin.length < 4) {
        setState(() {
          _enteredPin += value;
          _showError = false;
        });

        if (_enteredPin.length == 4) {
          _verifyPin();
        }
      }
    }
  }

  Future<void> _verifyPin() async {
    final settings = context.read<SettingsProvider>();
    if (settings.isPinLockedOut) return;

    if (settings.verifyPin(_enteredPin)) {
      await settings.recordSuccessfulPinEntry();
      _onAuthSuccess();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _showError = true;
        _enteredPin = '';
      });
      await settings.recordFailedPinAttempt();
      _startLockoutTimerIfNeeded();
    }
  }

  void _onAuthSuccess() {
    HapticFeedback.mediumImpact();
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _startLockoutTimerIfNeeded() {
    _lockoutTimer?.cancel();
    final settings = context.read<SettingsProvider>();
    if (!settings.isPinLockedOut) return;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final provider = context.read<SettingsProvider>();
      if (!provider.isPinLockedOut) {
        await provider.clearPinLockout();
        timer.cancel();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final showBiometricButton =
        settings.biometricEnabled && _biometricAvailable;
    final isLockedOut = settings.isPinLockedOut;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: _isAuthenticating
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(height: 24),

                Text(
                  settings.hasPin ? 'Enter PIN' : 'Authenticate',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  settings.hasPin
                      ? 'Enter your 4-digit PIN to unlock'
                      : 'Use biometrics to unlock',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 32),

                if (settings.hasPin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          border: Border.all(
                            color: _showError ? Colors.red : Colors.white,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_showError || isLockedOut) ...[
                    const SizedBox(height: 16),
                    Text(
                      isLockedOut
                          ? 'Too many failed attempts. Try again in ${settings.pinLockoutSecondsRemaining}s.'
                          : 'Incorrect PIN. ${settings.pinAttemptsRemaining} attempts remaining.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],

                const Spacer(),

                if (settings.hasPin) _buildKeypad(showBiometricButton),

                if (!settings.hasPin && settings.biometricEnabled) ...[
                  ElevatedButton.icon(
                    onPressed: _isAuthenticating
                        ? null
                        : _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text('Authenticate with Biometrics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool showBiometric) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map(_buildKeyButton).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map(_buildKeyButton).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map(_buildKeyButton).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeyButton(showBiometric ? 'biometric' : ''),
            _buildKeyButton('0'),
            _buildKeyButton('delete'),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyButton(String value) {
    if (value.isEmpty) {
      return const SizedBox(width: 80, height: 80);
    }

    IconData? icon;
    if (value == 'delete') {
      icon = Icons.backspace_outlined;
    } else if (value == 'biometric') {
      icon = Icons.fingerprint;
    }

    return InkWell(
      onTap: () => _onPinButtonPressed(value),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 28)
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
