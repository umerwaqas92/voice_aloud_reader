import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../va_tokens.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/lucide_svg_icon.dart';
import '../state/settings_controller.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    const _OnboardingPageData(
      title: 'Welcome to Voxly',
      description: 'The easiest way to listen to your favorite books and articles. Turn any text into natural-sounding speech.',
      iconName: 'book',
      color: VAColors.blue600,
    ),
    const _OnboardingPageData(
      title: 'Scan and Read',
      description: 'Snap a photo of any printed page or upload a PDF. Our OCR technology will prepare it for you instantly.',
      iconName: 'camera',
      color: VAColors.purple600,
    ),
    const _OnboardingPageData(
      title: 'Focus on Listening',
      description: 'Customizable reading speeds, high-quality voices, and a distraction-free reader interface.',
      iconName: 'file-text',
      color: VAColors.emerald600,
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(settingsControllerProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPageEntrance(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: LucideSvgIcon(
                              page.iconName,
                              size: 80,
                              color: page.color,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: VAColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: VAColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[_currentPage].color
                              : VAColors.gray200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final String iconName;
  final Color color;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.iconName,
    required this.color,
  });
}
