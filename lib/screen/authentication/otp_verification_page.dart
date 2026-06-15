import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walleta/screen/authentication/login_page.dart';
import 'package:walleta/services/auth_service.dart';
import 'package:walleta/widgets/gradient_button.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  bool loading = false;

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() => loading = true);
    try {
      final res = await AuthService().verifyOtp(widget.email, otp);
      if (res["status"] == 200) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res["data"]?["message"] ?? "Invalid OTP")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error connecting to server")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
                    'Verify Email',
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
                          Icons.mark_email_read_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'OTP Verification',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A8F7A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please type the verification code sent to ${widget.email}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) => _buildOtpBox(i)),
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        onPressed: _verifyOtp,
                        text: 'Verify',
                        isLoading: loading,
                        height: 50,
                        borderRadius: 25,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Resend OTP")),
                                );
                              },
                        child: Text(
                          "Didn't receive code? Resend",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildOtpBox(int i) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controllers[i],
        focusNode: focusNodes[i],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xFFA9BFD7),
          contentPadding: EdgeInsets.zero,
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
            borderSide: const BorderSide(color: Color(0xFF4A8F7A), width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) focusNodes[i + 1].requestFocus();
          if (v.isEmpty && i > 0) focusNodes[i - 1].requestFocus();
          if (v.isNotEmpty && i == 5) {
            FocusScope.of(context).unfocus();
            _verifyOtp();
          }
        },
      ),
    );
  }
}
