import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;
  bool _loading = false;

  static const _slides = [
    _Slide(
      icon: Icons.sports_soccer_rounded,
      title: 'احجز ملعبك بسهولة',
      body: 'اختار الملعب المناسب، حدد الوقت، وادفع بكل أمان من خلال التطبيق.',
    ),
    _Slide(
      icon: Icons.people_rounded,
      title: 'دور على لاعبين',
      body: 'مش لاقي فريق؟ أنشئ ماتش مفتوح وادعو لاعبين من نفس المدينة.',
    ),
    _Slide(
      icon: Icons.emoji_events_rounded,
      title: 'شارك في البطولات',
      body: 'سجّل فريقك في بطولات محلية وتنافس على المراكز الأولى والجوائز.',
    ),
  ];

  Future<void> _finish() async {
    if (_loading) return;
    setState(() => _loading = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'onboardingComplete': true});

      // Wait for the Firestore snapshot stream to propagate the change
      // to the authStateProvider before navigating, to avoid the redirect
      // sending us back to /onboarding.
      bool redirected = false;

      // Listen for the auth state to reflect onboardingComplete == true
      ref.listenManual(authStateProvider, (_, next) {
        final updated = next.valueOrNull?.onboardingComplete ?? false;
        if (updated && mounted && !redirected) {
          redirected = true;
          context.go('/home');
        }
      });

      // Fallback: if the listener hasn't fired within 3 seconds,
      // force-navigate to /home. By now Firestore has confirmed the write,
      // so the redirect should allow it through.
      await Future.delayed(const Duration(seconds: 3));
      if (!redirected && mounted) {
        redirected = true;
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Failed to update onboardingComplete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // Green gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('تخطي',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                ),
              ),

              // Slides
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),

              const SizedBox(height: 40),

              // Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : (isLast
                            ? _finish
                            : () => _ctrl.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: AppColors.primary)
                        : Text(
                            isLast ? 'يلا بينا!' : 'التالي',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slide data ─────────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });
}

// ── Slide view ─────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
