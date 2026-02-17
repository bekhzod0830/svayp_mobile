import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Tutorial Screen - Interactive tutorial teaching swipe mechanics
/// Final step before entering the main app
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int _currentStep = 0;
  bool _isLoading = false;
  String _gender = 'female';
  String _hijabPreference = 'uncovered';
  List<TutorialStep> _steps = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get user data from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _gender = args['gender'] as String? ?? 'female';
      _hijabPreference = args['hijabPreference'] as String? ?? 'uncovered';
    }

    // Initialize tutorial steps with localized text
    if (_steps.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _steps = [
        TutorialStep(
          icon: Icons.swipe,
          title: l10n.swipeRightToLike,
          description: l10n.swipeRightDescription,
          color: AppColors.black,
        ),
        TutorialStep(
          icon: Icons.close,
          title: l10n.swipeLeftToPass,
          description: l10n.swipeLeftDescription,
          color: AppColors.gray700,
        ),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _finishTutorial();
    }
  }

  Future<void> _finishTutorial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Mark tutorial as completed in local storage
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to style quiz with user data
      Navigator.of(context).pushNamed(
        '/style-quiz',
        arguments: {'gender': _gender, 'hijabPreference': _hijabPreference},
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.completionError);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Wait for steps to be initialized
    if (_steps.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.black)),
      );
    }

    final currentStep = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 44),

                    const SizedBox(height: 24),

                    // Content
                    AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_slideAnimation.value * 400, 0),
                          child: Opacity(
                            opacity: 1 - _slideAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with animation
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: currentStep.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              currentStep.icon,
                              size: 72,
                              color: currentStep.color,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Title
                          Text(
                            currentStep.title,
                            style: AppTypography.display2.copyWith(height: 1.2),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            currentStep.description,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Progress Indicators
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _steps.length,
                          (index) => Container(
                            width: index == _currentStep ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == _currentStep
                                  ? AppColors.black
                                  : AppColors.gray300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.white,
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.gray300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentStep == _steps.length - 1
                                  ? l10n.startShopping
                                  : l10n.next,
                              style: AppTypography.button.copyWith(
                                color: AppColors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tutorial Step Model
class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
