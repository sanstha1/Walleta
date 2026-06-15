import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walleta/common/utils/my_snackbar.dart';
import 'package:walleta/screen/authentication/otp_verification_page.dart';
import 'package:walleta/services/auth_service.dart';
import 'package:walleta/widgets/gradient_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Name is required";
    if (value.trim().length < 2) return "Name must be at least 2 characters";
    return null;
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

  String _parseErrorMessage(Map<String, dynamic> res) {
    final data = res["data"] as Map<String, dynamic>? ?? {};
    final message = (data["message"] ?? "").toString().toLowerCase();
    if (message.contains("already") ||
        message.contains("duplicate") ||
        message.contains("exist")) {
      return "An account with this email already exists";
    }
    return data["message"] ?? "Signup failed";
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmController.text) {
      _error("Passwords do not match");
      return;
    }

    setState(() => loading = true);
    try {
      final res = await AuthService().signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (res["status"] == 201) {
        if (!mounted) return;
        SnackbarUtils.showSuccess(context, "OTP sent to your email!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationPage(email: emailController.text.trim()),
          ),
        );
      } else {
        _error(_parseErrorMessage(res));
      }
    } catch (e) {
      _error("Connection error. Please try again.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    SnackbarUtils.showError(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB0C4DE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Walleta',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4A8F7A),
                    ),
                  ),
                  const SizedBox(height: 52),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create an account',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLabel('Full Name'),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: nameController,
                    hint: 'Enter your full name',
                    validator: _validateName,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLabel('Email'),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: emailController,
                    hint: 'Enter your email',
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLabel('Password'),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: passwordController,
                    hint: 'Create a password',
                    obscure: _obscurePassword,
                    validator: _validatePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLabel('Confirm Password'),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: confirmController,
                    hint: 'Confirm your password',
                    obscure: _obscureConfirm,
                    validator: (val) => (val == null || val.isEmpty)
                        ? "Please confirm password"
                        : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 48),
                  GradientButton(
                    onPressed: _handleSignup,
                    text: 'REGISTER',
                    isLoading: loading,
                    height: 56,
                    borderRadius: 28,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
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
          color: const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: Colors.transparent,
        suffixIcon: suffix,
        errorStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4A8F7A), width: 1.5),
        ),
      ),
    );
  }
}
