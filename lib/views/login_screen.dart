import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proximity_guard/views/pre_trip/pre_trip_flow_view.dart';
import 'package:proximity_guard/views/theme/app_theme.dart';
import '../../models/auth_result_model.dart';

/// Driver sign-in screen for Proximity Guard.
///
/// Uses [AppTheme] for colors (so it follows light/dark), and produces an
/// [AuthResultModel] on submit. Wire the real authentication into
/// [_handleSignIn] where indicated.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocus = FocusNode();
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
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _idFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    // if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ---- Integration point -------------------------------------------------
    // Replace this simulated delay with your real auth call, e.g.:
    //   final result = await context.read<AuthController>()
    //       .authenticate(method: AuthMethod.pin, driverId: _idController.text);
    await Future.delayed(const Duration(milliseconds: 1200));

    final result = AuthResultModel(
      method: AuthMethod.pin,
      status: AuthStatus.success,
      driverId: _idController.text.trim(),
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
    final c = AppTheme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _buildLogo()),
                        const SizedBox(height: 24),
                        Text(
                          'Proximity Guard',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Driver sign-in',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildLabel(c, 'DRIVER ID OR EMAIL'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          c: c,
                          controller: _idController,
                          focusNode: _idFocus,
                          hint: 'DRV-0241',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your driver ID or email'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        _buildLabel(c, 'PASSWORD'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          c: c,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hint: 'Enter your password',
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
                              color: c.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your password'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: forgot-password flow
                            },
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        _buildSignInButton(),
                        const SizedBox(height: 26),

                        Text(
                          'Secure  ·  MFA-ready  ·  role-based access',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(26, 30),
          painter: _ShieldIconPainter(),
        ),
      ),
    );
  }

  Widget _buildLabel(AppColors c, String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: c.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required AppColors c,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      cursorColor: AppTheme.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 15, color: c.textMuted),
        prefixIcon: Icon(icon, color: c.textMuted, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: c.card,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.6),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
          elevation: 6,
          shadowColor: AppTheme.primary.withValues(alpha: 0.4),
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
            : Text(
                'Sign in',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Minimal vector shield with a check mark — same motif as the splash logo.
class _ShieldIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.05, h * 0.08, w * 0.08, h * 0.38)
      ..quadraticBezierTo(w * 0.1, h * 0.68, w * 0.5, h)
      ..quadraticBezierTo(w * 0.9, h * 0.68, w * 0.92, h * 0.38)
      ..quadraticBezierTo(w * 0.95, h * 0.08, w * 0.5, 0)
      ..close();

    canvas.drawPath(shieldPath, Paint()..color = Colors.white);

    final checkPaint = Paint()
      ..color = AppTheme.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(w * 0.28, h * 0.48)
      ..lineTo(w * 0.44, h * 0.64)
      ..lineTo(w * 0.72, h * 0.32);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}