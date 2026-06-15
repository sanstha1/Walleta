import 'package:flutter/material.dart';
import 'package:walleta/screen/onboarding/view/get_started.dart';

class OnboardingViewModel extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentPage = 0;

  final List<OnboardingData> pages = [
    OnboardingData(
      imagePath: 'assets/images/onboarding1.png',
      title: 'Track your daily expenses',
      subtitle: 'Stay in control of your money by recording every transaction.',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding2.png',
      title: 'Add expenses with AI',
      subtitle:
          'Enter transactions manually or use AI to quickly add expenses.',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding3.png',
      title: 'Stay Within Your Budget',
      subtitle: 'Set limits and avoid overspending with simple tracking.',
    ),
  ];

  bool get isLastPage => currentPage == pages.length - 1;

  void onPageChanged(int index) {
    currentPage = index;
    notifyListeners();
  }

  void nextPage() {
    if (!isLastPage) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip(BuildContext context) {
    pageController.animateToPage(
      pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void getStarted(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedView()),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final String imagePath;
  final String title;
  final String subtitle;

  OnboardingData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}
