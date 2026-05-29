import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../models/auth_result_model.dart';
import '../theme/app_theme.dart';

class PinAuthView extends StatefulWidget {
  const PinAuthView({super.key});

  @override
  State<PinAuthView> createState() => _PinAuthViewState();
}

class _PinAuthViewState extends State<PinAuthView> {
  String _pin = '';

  void _onKeyPressed(String key) {
    if (_pin.length < 4) {
      setState(() => _pin += key);
      if (_pin.length == 4) {
        context.read<AuthController>().authenticateWithPin(_pin);
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _onClear() {
    setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        if (authController.status == AuthStatus.success) {
          return _buildSuccess(context, authController);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_rounded, size: 28, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter Security PIN',
                style: TextStyle(
                  color: AppTheme.of(context).textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your 4-digit verification code',
                style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _buildPinDots(authController.status),
              if (authController.status == AuthStatus.failed) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authController.message,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildKeypad(),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => authController.reset(),
                icon: Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.of(context).textSecondary),
                label: Text('Choose another method',
                    style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinDots(AuthStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        final isError = status == AuthStatus.failed;
        final color = isError ? AppTheme.danger : AppTheme.primary;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(
              color: isFilled ? color : AppTheme.of(context).cardBorder,
              width: 2,
            ),
            boxShadow: isFilled
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildKey(key),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isAction = key == '⌫' || key == 'C';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (key == '⌫') {
            _onBackspace();
          } else if (key == 'C') {
            _onClear();
          } else {
            _onKeyPressed(key);
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAction ? Colors.transparent : AppTheme.of(context).card,
            border: Border.all(
              color: isAction ? Colors.transparent : AppTheme.of(context).cardBorder,
            ),
          ),
          child: Center(
            child: key == '⌫'
                ? Icon(Icons.backspace_outlined, size: 22, color: AppTheme.of(context).textSecondary)
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: isAction ? 14 : 24,
                      fontWeight: FontWeight.w500,
                      color: isAction ? AppTheme.of(context).textSecondary : AppTheme.of(context).textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, AuthController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.accent),
          ),
          const SizedBox(height: 24),
          Text(
            'PIN Verified',
            style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.authenticatedDriver?.name ?? 'Driver',
              style: const TextStyle(color: AppTheme.accent, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 36),
          AppTheme.gradientButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.read<PreTripController>().onAuthSuccess(),
          ),
        ],
      ),
    );
  }
}
