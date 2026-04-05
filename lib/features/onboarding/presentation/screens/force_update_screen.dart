import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Force Update Screen — Liquid Glass Style
///
/// Shown when the running app version is older than the latest version
/// published by the backend. Fully blocks the app (no back navigation).
class ForceUpdateScreen extends StatefulWidget {
  final String latestVersion;

  const ForceUpdateScreen({super.key, required this.latestVersion});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with TickerProviderStateMixin {
  // ---------- animation controllers ----------
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _orbController;
  late final AnimationController _shimmerController;

  // ---------- entry animations ----------
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _iconScale;

  // ---------- continuous animations ----------
  late final Animation<double> _pulseAnim;
  late final Animation<double> _orbAnim;
  late final Animation<double> _shimmerAnim;

  bool _isLaunching = false;

  // App Store URLs
  static const String _iosStoreUrl =
      'https://apps.apple.com/us/app/svayp-ai/id6759787092';
  static const String _fallbackUrl =
      'https://apps.apple.com/us/app/svayp-ai/id6759787092';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _setupAnimations() {
    // -- entry (runs once) --
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    // -- pulse ring (loops) --
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);

    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // -- floating orbs (loops) --
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _orbAnim = CurvedAnimation(parent: _orbController, curve: Curves.easeInOut);

    // -- button shimmer (loops) --
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // start entry
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _orbController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _openStore() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    final url = Platform.isIOS ? _iosStoreUrl : _fallbackUrl;
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // silently ignore — user can try again
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // Block ALL back navigation — user must update
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF050508),
        body: Stack(
          children: [
            // ── animated background orbs ──────────────────────────────
            _AnimatedOrbs(animation: _orbAnim),

            // ── main content ──────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),

                            // ── icon with pulse ring ──────────────────
                            _PulseIcon(
                              scaleAnim: _iconScale,
                              pulseAnim: _pulseAnim,
                            ),

                            const SizedBox(height: 32),

                            // ── title ─────────────────────────────────
                            Text(
                              l10n.forceUpdateTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── subtitle ──────────────────────────────
                            Text(
                              l10n.forceUpdateSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.65),
                                height: 1.55,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── version badge ─────────────────────────
                            _VersionBadge(version: widget.latestVersion),

                            const SizedBox(height: 36),

                            // ── update button ─────────────────────────
                            _ShimmerButton(
                              label: l10n.forceUpdateButton,
                              shimmerAnim: _shimmerAnim,
                              isLoading: _isLaunching,
                              onTap: _openStore,
                            ),

                            const SizedBox(height: 8),
                          ],
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

// ─── Background Orbs ─────────────────────────────────────────────────────────

class _AnimatedOrbs extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedOrbs({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Stack(
          children: [
            // Top-right warm orb
            Positioned(
              top: -60 + t * 30,
              right: -80 + t * 20,
              child: _Orb(
                size: 340,
                color: const Color(0xFFFF6B6B),
                opacity: 0.28 + t * 0.06,
              ),
            ),
            // Bottom-left cool orb
            Positioned(
              bottom: -80 - t * 20,
              left: -100 + t * 15,
              child: _Orb(
                size: 320,
                color: const Color(0xFF7C6CFC),
                opacity: 0.22 + t * 0.05,
              ),
            ),
            // Center-top accent orb (smaller, gold)
            Positioned(
              top: 100 + t * 40,
              left: MediaQuery.of(context).size.width * 0.25,
              child: _Orb(
                size: 180,
                color: const Color(0xFFFFD166),
                opacity: 0.12 + t * 0.04,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: -8,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: child,
        ),
      ),
    );
  }
}

// ─── Pulse Icon ───────────────────────────────────────────────────────────────

class _PulseIcon extends StatelessWidget {
  final Animation<double> scaleAnim;
  final Animation<double> pulseAnim;

  const _PulseIcon({required this.scaleAnim, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnim, pulseAnim]),
      builder: (context, _) {
        final pulse = pulseAnim.value;
        return SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Opacity(
                opacity: (1 - pulse).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.65 + pulse * 0.8,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Inner pulse ring
              Opacity(
                opacity: ((0.7 - pulse) * 2).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.7 + pulse * 0.5,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Icon container
              Transform.scale(
                scale: scaleAnim.value,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Version Badge ────────────────────────────────────────────────────────────

class _VersionBadge extends StatelessWidget {
  final String version;

  const _VersionBadge({required this.version});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.new_releases_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.forceUpdateVersionLabel(version),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer Button ───────────────────────────────────────────────────────────

class _ShimmerButton extends StatelessWidget {
  final String label;
  final Animation<double> shimmerAnim;
  final bool isLoading;
  final VoidCallback onTap;

  const _ShimmerButton({
    required this.label,
    required this.shimmerAnim,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedBuilder(
        animation: shimmerAnim,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment(shimmerAnim.value - 1, -0.3),
                    end: Alignment(shimmerAnim.value, 0.3),
                    colors: const [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F0F0),
                      Color(0xFFFFFFFF),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
