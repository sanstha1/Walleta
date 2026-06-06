import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:walleta/screen/onboarding/viewmodel/get_started_view_model.dart';
import 'package:walleta/widgets/gradient_button.dart';

class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<GetStartedViewModel>.reactive(
      viewModelBuilder: () => GetStartedViewModel(),
      builder: (context, model, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFB8C8D8),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          'Get Started!',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E8B6E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Image.asset(
                            'assets/images/get_started.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Stay in control of your spending & manage\nfinances effortlessly with Walleta',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A3A),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureChip(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Smart Expense\nTracking',
                            ),
                            _FeatureChip(
                              icon: Icons.auto_awesome_outlined,
                              label: 'AI Expense\nEntry',
                            ),
                            _FeatureChip(
                              icon: Icons.bar_chart_outlined,
                              label: 'Spending\nInsights',
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      GradientButton(
                        onPressed: () => model.onSignInPressed(context),
                        text: 'LOG IN',
                        height: 52,
                        borderRadius: 30,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => model.onCreateAccountPressed(context),
                        child: Text(
                          'Create an account',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D2D2D),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF8FAABC).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF3A5A6A), size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF2D2D2D),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
