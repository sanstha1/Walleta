import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walleta/screen/authentication/login_page.dart';
import 'package:walleta/services/auth_service.dart';
import 'package:walleta/widgets/gradient_button.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool showPass = false;
  bool showConfirm = false;
  bool isLoading = false;

  final passController = TextEditingController();
  final confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final password = passController.text.trim();
    final confirm = confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }
    if (password != confirm) {
      _showSnackBar("Passwords do not match");
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters");
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await _authService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: password,
      );

      final status = response['status'];
      if (status == 200 || status == 201) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        final msg = response['data']['message'] ?? "Reset failed";
        _showSnackBar(msg);
      }
    } catch (e) {
      _showSnackBar("Connection error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Password Updated',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Your password has been updated. You can now log in with your new credentials.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(
              'Go to Login',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4A8F7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB0C4DE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 54, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4A8F7A),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Walleta',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4A8F7A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Create New Password',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0C4DE),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF1F2937),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF9CA8BC),
                        ),
                        child: const Icon(
                          Icons.lock_reset_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Reset Password',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A8F7A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please follow your new password. It must be different from the previous one',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'New Password',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        passController,
                        showPass,
                        () => setState(() => showPass = !showPass),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirm Password',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        confirmController,
                        showConfirm,
                        () => setState(() => showConfirm = !showConfirm),
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        onPressed: _handleReset,
                        text: 'Confirm',
                        isLoading: isLoading,
                        height: 50,
                        borderRadius: 25,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    bool visible,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: 'Enter password',
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: const Color(0xFFA9BFD7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF1F2937),
            size: 20,
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4A8F7A), width: 1.5),
        ),
      ),
    );
  }
}
