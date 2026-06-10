import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:walleta/common/services/auth_method.dart';
import 'package:walleta/screen/authentication/forget_password_page.dart';
import 'package:walleta/screen/authentication/signup_page.dart';
import 'package:walleta/screen/bottom_navigation_screen.dart';
import 'package:walleta/screen/profile/viewmodel/profile_viewmodel.dart';
import 'package:walleta/services/auth_service.dart';
import 'package:walleta/services/biometric_service.dart';
import 'package:walleta/services/notification_service.dart';
import 'package:walleta/services/token_service.dart';
import 'package:walleta/common/utils/my_snackbar.dart';
import 'package:walleta/screen/profile/viewmodel/notification_viewmodel.dart';
import 'package:walleta/widgets/gradient_button.dart';

class LoginPage extends StatefulWidget {
  final bool isFromPremium;
  const LoginPage({super.key, this.isFromPremium = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isAvailable();
    final enabled = await TokenService.isBiometricEnabled();
    final savedToken = await TokenService.getBiometricToken();
    if (mounted) {
      setState(
        () => _biometricAvailable = available && enabled && savedToken != null,
      );
    }
    if (_biometricAvailable) _triggerBiometric();
  }

  Future<void> _triggerBiometric() async {
    final authenticated = await _biometricService.authenticate();
    if (!authenticated || !mounted) return;

    final savedToken = await TokenService.getBiometricToken();
    final savedEmail = await TokenService.getBiometricEmail();

    if (savedToken == null || savedEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login manually first to set up biometrics'),
          ),
        );
      }
      return;
    }

    await TokenService.save(savedToken);
    await TokenService.saveUserEmail(savedEmail);
    await NotificationService.syncFcmToken();
    if (!mounted) return;
    await Provider.of<ProfileViewModel>(context, listen: false).loadUserData();
    Provider.of<NotificationViewModel>(
      // ignore: use_build_context_synchronously
      context,
      listen: false,
    ).restartListening();
    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      (route) => false,
    );
  }

  String? _validateEmail(String? value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value == null || value.trim().isEmpty) return "Email is required";
    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Min. 6 characters required";
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final res = await AuthService().login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final int statusCode = res["status"];
      final dynamic responseData = res["data"];

      switch (statusCode) {
        case 200:
        case 201:
          if (responseData != null && responseData["data"] != null) {
            final token = responseData["data"]["accessToken"];
            final userEmail = emailController.text.trim();
            final password = passwordController.text.trim();

            await TokenService.save(token);
            await TokenService.saveUserEmail(userEmail);
            await NotificationService.syncFcmToken();

            final available = await _biometricService.isAvailable();
            if (available && mounted) {
              final alreadyEnabled = await TokenService.isBiometricEnabled();
              if (!alreadyEnabled) {
                final enable = await showDialog<bool>(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Enable Biometrics',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    content: Text(
                      'Would you like to use fingerprint or face ID to login next time?',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
                if (enable == true) {
                  await TokenService.setBiometricEnabled(true);
                  await TokenService.saveBiometricSession(token, userEmail);
                }
              } else {
                await TokenService.saveBiometricSession(token, userEmail);
              }
            }

            try {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: userEmail,
                password: password,
              );
            } catch (firebaseError) {
              debugPrint("Firebase Sync Failed: $firebaseError");
            }

            if (mounted) {
              await Provider.of<ProfileViewModel>(
                context,
                listen: false,
              ).loadUserData();
              Provider.of<NotificationViewModel>(
                // ignore: use_build_context_synchronously
                context,
                listen: false,
              ).restartListening();
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const BottomNavScreen()),
                (route) => false,
              );
              // ignore: use_build_context_synchronously
              GoogleSignInService.updateTokenOnBackend(
                userEmail,
              ).catchError((e) => debugPrint(e));
            }
          } else {
            _error("Server error: Missing session data.");
          }
          break;
        case 401:
          _error("Incorrect password.");
          passwordController.clear();
          break;
        case 404:
          _error("No account found.");
          break;
        default:
          _error("Login failed ($statusCode)");
      }
    } catch (e) {
      debugPrint("Login Exception: $e");
      _error("Something went wrong.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    SnackbarUtils.showError(context, msg);
  }

  Future<void> _signInWithGoogle() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final userCredential = await GoogleSignInService.signInWithGoogle();
      if (userCredential == null || !mounted) return;

      final user = userCredential.user;
      if (user == null) return;

      final userEmail = user.email;
      if (userEmail == null) return;

      final firebaseIdToken = await user.getIdToken(true);
      final res = await AuthService().googleSignIn(firebaseIdToken!);

      if (res["status"] == 200) {
        final jwt = res["data"]["data"]["accessToken"];
        if (jwt == null) {
          _error("Server did not return a token.");
          return;
        }

        await TokenService.saveGoogleSession(token: jwt, email: userEmail);
        await NotificationService.syncFcmToken();
        if (!mounted) return;

        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).loadUserData();
        Provider.of<NotificationViewModel>(
          // ignore: use_build_context_synchronously
          context,
          listen: false,
        ).restartListening();

        if (widget.isFromPremium) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context, userEmail);
        } else {
          Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (_) => const BottomNavScreen()),
            (route) => false,
          );
        }

        GoogleSignInService.updateTokenOnBackend(userEmail).catchError((e) {
          debugPrint("Non-critical FCM sync error: $e");
        });
      } else {
        _error("Google Sign In failed. Please try again.");
      }
    } catch (e) {
      debugPrint("Google Sign In Exception: $e");
      _error("Google login failed.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGIN',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Email'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: emailController,
                            hint: 'Enter your email',
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: passwordController,
                            hint: 'Enter your password',
                            obscure: _obscurePassword,
                            validator: _validatePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF4A8F7A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            onPressed: _handleLogin,
                            text: 'LOGIN',
                            isLoading: loading,
                            height: 50,
                            borderRadius: 12,
                            fontSize: 15,
                          ),
                          if (_biometricAvailable) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _triggerBiometric,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF4A8F7A),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.fingerprint,
                                      color: Color(0xFF4A8F7A),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Login with Biometrics',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: const Color(0xFF4A8F7A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or sign in with',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: _signInWithGoogle,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF3F4F6),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.g_mobiledata,
                                  size: 32,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Create an account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF4A8F7A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      color: const Color(0xFF4A8F7A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walleta',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back!',
            // ignore: deprecated_member_use
            style: GoogleFonts.poppins(
              fontSize: 14,
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFFD1D5DB),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        suffixIcon: suffix,
        errorStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4A8F7A), width: 1.5),
        ),
      ),
    );
  }
}
