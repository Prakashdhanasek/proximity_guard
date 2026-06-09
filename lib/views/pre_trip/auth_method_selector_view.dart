import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/auth_result_model.dart';
import '../theme/app_assets.dart';
import 'face_auth_view.dart';
import 'pin_auth_view.dart';
import 'rfid_auth_view.dart';
import 'mobile_approval_view.dart';

class AuthMethodSelectorView extends StatefulWidget {
  const AuthMethodSelectorView({super.key});

  @override
  State<AuthMethodSelectorView> createState() => _AuthMethodSelectorViewState();
}

class _AuthMethodSelectorViewState extends State<AuthMethodSelectorView> {
  bool _autoStarted = false;

  static const Color _primary = Color(0xFF3B6FE8);
  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);

  @override
  void initState() {
    super.initState();
    // Auto-start face verification the first time this step appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      if (!_autoStarted && auth.currentMethod == null) {
        _autoStarted = true;
        auth.authenticateWithFace();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // A method is active (face by default, or one the user picked) -> show it.
        if (authController.currentMethod != null) {
          return _buildActiveAuthView(authController.currentMethod!);
        }
        // currentMethod == null -> user tapped "Choose another method" -> show list.
        return _buildMethodList(context, authController);
      },
    );
  }

  Widget _buildMethodList(BuildContext context, AuthController authController) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to the default face verification screen.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                foregroundColor: _primary,
              ),
              onPressed: () => authController.authenticateWithFace(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'Back to Face',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Verify your identity',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a verification method to continue.',
            style: GoogleFonts.poppins(fontSize: 14, color: _textGrey),
          ),
          const SizedBox(height: 20),

          _MethodCard(
            iconAsset: AppImages.pin,
            title: 'Security PIN',
            subtitle: 'Enter your 4-digit code',
            onTap: () => authController.selectMethod(AuthMethod.pin),
          ),
          const SizedBox(height: 14),

          _MethodCard(
            iconAsset: AppImages.nfc,
            title: 'NFC/RFID Card',
            subtitle: 'Tap your authorized card',
            onTap: () => authController.authenticateWithRfid(),
          ),
          const SizedBox(height: 14),

          _MethodCard(
            iconAsset: AppImages.managerApproval,
            title: 'Manager Approval',
            subtitle: 'Request remote authorization',
            onTap: () => authController.requestMobileApproval(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAuthView(AuthMethod method) {
    switch (method) {
      case AuthMethod.face:
        return const FaceAuthView();
      case AuthMethod.pin:
        return const PinAuthView();
      case AuthMethod.rfid:
        return const RfidAuthView();
      case AuthMethod.mobileApproval:
        return const MobileApprovalView();
    }
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _border = Color(0xFFEDEFF4);
  static const Color _chevronBg = Color(0xFFF3F5F9);
  static const Color _chevron = Color(0xFF9AA1B0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _chevronBg,
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _chevron,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}