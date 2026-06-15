import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'package:walleta/widgets/gradient_button.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFBBC8DA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: vm.pageController,
                onPageChanged: vm.onPageChanged,
                itemCount: vm.pages.length,
                itemBuilder: (context, index) {
                  final page = vm.pages[index];
                  return _OnboardingPage(data: page);
                },
              ),
            ),
            _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.only(top: 62),
              decoration: BoxDecoration(
                color: const Color(0xFFCFDEEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(data.imagePath, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5A6070),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => vm.skip(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'SKIP',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5A6070),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(
              vm.pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: vm.currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: vm.currentPage == index
                      ? const Color(0xFF1A5EA8)
                      : const Color(0xFFB0BEC5),
                ),
              ),
            ),
          ),
          vm.isLastPage
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GradientButton(
                    onPressed: () => vm.getStarted(context),
                    text: 'Get Started',
                    width: 130,
                    height: 57,
                  ),
                )
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GradientButton(
                    onPressed: vm.nextPage,
                    text: 'NEXT',
                    width: 100,
                    height: 57,
                  ),
                ),
        ],
      ),
    );
  }
}
