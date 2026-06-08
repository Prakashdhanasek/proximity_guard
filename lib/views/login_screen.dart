import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proximity_guard/views/pre_trip/pre_trip_flow_view.dart';
import 'package:proximity_guard/views/theme/app_assets.dart';
import '../../models/auth_result_model.dart';

/// Driver sign-in screen for Proximity Guard.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ---- Palette (tuned to match the mock) -------------------------------
  static const Color _primary = Color(0xFF3B6FE8);
  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _label = Color(0xFF98A0B0);
  static const Color _hint = Color(0xFFAEB4C2);
  static const Color _border = Color(0xFFE6E9F1);
  static const Color _danger = Color(0xFFE5484D);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ---- Integration point -------------------------------------------------
    // Replace this simulated delay with your real auth call.
    await Future.delayed(const Duration(milliseconds: 1200));

    final result = AuthResultModel(
      method: AuthMethod.pin,
      status: AuthStatus.success,
      driverId: _emailController.text.trim(),
      message: 'Signed in',
    );
    // ------------------------------------------------------------------------

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.status == AuthStatus.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PreTripFlowView()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'Sign-in failed' : result.message,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Background image (trucks / site)
          Image.asset(
            AppImages.backgroundImage,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),

          // 2) Logo near the top
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Image.asset(
                  AppImages.logo,
                  width: size.width * 0.75,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 3) Floating white BOX with the form (margins on all sides,
          //    all corners rounded). Anchored toward the bottom.
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: _buildCard(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD3DFF5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue to your account',
                style: GoogleFonts.poppins(fontSize: 14, color: _textGrey),
              ),
              const SizedBox(height: 26),

              _fieldLabel('EMAIL'),
              const SizedBox(height: 8),
              _field(
                controller: _emailController,
                focusNode: _emailFocus,
                hint: 'Driver@gmail.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your email'
                    : null,
              ),
              const SizedBox(height: 18),

              _fieldLabel('PASSWORD'),
              const SizedBox(height: 8),
              _field(
                controller: _passwordController,
                focusNode: _passwordFocus,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSignIn(),
                suffix: IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _label,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // TODO: forgot-password flow
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                      decoration: TextDecoration.underline,
                      decorationColor: _primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _signInButton(),
              const SizedBox(height: 22),

              _footerRow(),
              const SizedBox(height: 16),

              _contactSupport(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _label,
          letterSpacing: 0.6,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: _primary,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 15, color: _hint),
        prefixIcon: Icon(icon, color: _label, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 11.5),
      ),
    );
  }

  Widget _signInButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withValues(alpha: 0.6),
          elevation: 2,
          shadowColor: _primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _footerRow() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _footerItem(Icons.verified_user_outlined, 'Secure'),
          _divider(),
          _footerItem(Icons.videocam_outlined, 'AI Monitoring'),
          _divider(),
          _footerItem(Icons.lock_outline_rounded, 'Privacy First'),
        ],
      ),
    );
  }

  Widget _footerItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _label),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11.5, color: _textGrey),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 14,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: _border,
      );

  Widget _contactSupport() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Need help? ',
            style: GoogleFonts.poppins(fontSize: 13, color: _textGrey),
          ),
          GestureDetector(
            onTap: () {
              // TODO: contact support
            },
            child: Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.headset_mic_outlined, size: 15, color: _primary),
        ],
      ),
    );
  }
}