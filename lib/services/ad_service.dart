import 'dart:async';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

/// Service managing the state, analytics, and placeholders for app advertisements.
/// Supports both native custom premium sponsorships and provides seamless hooks
/// to integrate real Google Mobile Ads (AdMob).
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // -------------------------------------------------------------
  // Production Hooks for Google Mobile Ads (AdMob)
  // -------------------------------------------------------------
  // To integrate real AdMob, simply:
  // 1. Add `google_mobile_ads: ^5.1.0` (or latest) to pubspec.yaml
  // 2. Add App ID to AndroidManifest.xml and Info.plist
  // 3. Initialize SDK in main(): `MobileAds.instance.initialize();`
  // 4. Uncomment the real AdMob integration adapters below.

  /*
  BannerAd? _admobBannerAd;
  InterstitialAd? _admobInterstitialAd;

  void loadRealBannerAd(VoidCallback onLoaded) {
    _admobBannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('AdMob Banner failed to load: $error');
        },
      ),
    )..load();
  }

  void loadRealInterstitialAd(VoidCallback onLoaded) {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test Ad Unit ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _admobInterstitialAd = ad;
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob Interstitial failed to load: $error');
        },
      ),
    );
  }
  */

  // -------------------------------------------------------------
  // Custom Premium Sponsorship Registry
  // -------------------------------------------------------------
  final List<SponsorAdItem> mockAds = [
    SponsorAdItem(
      id: 'sp1',
      title: 'Vibrant Finance Premium',
      subtitle: 'Unlock exclusive dynamic themes, custom categories & advanced stock indicators at 50% off!',
      ctaText: 'Upgrade Now',
      colorStart: 0xFF6366F1, // Indigo
      colorEnd: 0xFF8B5CF6,   // Violet
      badgeColor: 0xFFF59E0B, // Gold Accent
      url: 'https://vibrantfinance.app/premium',
      graphicIcon: Icons.star_rounded,
    ),
    SponsorAdItem(
      id: 'sp2',
      title: 'Vibrant UI Design Kit',
      subtitle: 'Craft professional financial apps using our premium pixel-perfect Figma component library.',
      ctaText: 'Get Figma Kit',
      colorStart: 0xFFEC4899, // Pink
      colorEnd: 0xFFF43F5E,   // Rose
      badgeColor: 0xFF10B981, // Green Accent
      url: 'https://vibrantfinance.app/ui-kit',
      graphicIcon: Icons.design_services_rounded,
    ),
    SponsorAdItem(
      id: 'sp3',
      title: 'Titanium Apple Card',
      subtitle: 'Receive 3% instant daily cash back on all tech acquisitions, app stores and flight bookings.',
      ctaText: 'Apply Today',
      colorStart: 0xFF1E293B, // Slate Grey
      colorEnd: 0xFF475569,   // Light Slate
      badgeColor: 0xFFF1F5F9, // Silver Accent
      url: 'https://apple.com/apple-card',
      graphicIcon: Icons.credit_card_rounded,
    ),
  ];
}

class SponsorAdItem {
  final String id;
  final String title;
  final String subtitle;
  final String ctaText;
  final int colorStart;
  final int colorEnd;
  final int badgeColor;
  final String url;
  final IconData graphicIcon;

  SponsorAdItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.colorStart,
    required this.colorEnd,
    required this.badgeColor,
    required this.url,
    required this.graphicIcon,
  });
}

/// A gorgeous, glassmorphic custom advertisement widget designed to integrate seamlessly
/// into the premium layout of the main dashboard and financial ledger screens.
class SponsorBannerAd extends StatefulWidget {
  const SponsorBannerAd({super.key});

  @override
  State<SponsorBannerAd> createState() => _SponsorBannerAdState();
}

class _SponsorBannerAdState extends State<SponsorBannerAd> {
  int _currentAdIndex = 0;
  Timer? _rotationTimer;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // Rotate ads every 8 seconds for dynamic premium experience
    _rotationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % _adService.mockAds.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    if (!state.adsEnabled) return const SizedBox.shrink();

    final isDark = state.themeMode == ThemeMode.dark || state.themeName == 'gold';

    // Choose backing borders
    final Color borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final ad = _adService.mockAds[_currentAdIndex];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14.0),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Color(ad.colorStart).withOpacity(isDark ? 0.12 : 0.06),
            Color(ad.colorEnd).withOpacity(isDark ? 0.08 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Graphic Icon Accent
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(ad.colorStart).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ad.graphicIcon,
                  color: Color(ad.colorStart),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(ad.badgeColor).withOpacity(0.2),
                            border: Border.all(color: Color(ad.badgeColor).withOpacity(0.5), width: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            state.locale == 'en' ? 'SPONSOR' : 'TÀI TRỢ',
                            style: TextStyle(
                              color: Color(ad.badgeColor),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ad.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.subtitle,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Action button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(ad.colorStart),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Simulate launching custom URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${state.locale == 'en' ? 'Visiting' : 'Đang chuyển đến'} ${ad.title}...'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(ad.colorStart),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  ad.ctaText,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A beautiful fullscreen high-fidelity simulated interstitial advertisement dialog.
/// Includes an animated countdown timer bar, lockouts, and gold aesthetic accents.
class VibrantInterstitialAd extends StatefulWidget {
  final VoidCallback onClose;

  const VibrantInterstitialAd({super.key, required this.onClose});

  static void show(BuildContext context, VoidCallback onClose) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return VibrantInterstitialAd(onClose: onClose);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<VibrantInterstitialAd> createState() => _VibrantInterstitialAdState();
}

class _VibrantInterstitialAdState extends State<VibrantInterstitialAd> {
  int _secondsRemaining = 3;
  double _progress = 1.0;
  Timer? _timer;
  late SponsorAdItem _selectedAd;

  @override
  void initState() {
    super.initState();
    // Grab a random sponsor ad to display
    _selectedAd = AdService().mockAds[0]; // Spotlight the Premium Gold Update ad

    const int totalSteps = 30; // 30 segments for smooth progress animation (100ms each)
    int currentStep = totalSteps;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          currentStep--;
          _progress = currentStep / totalSteps;

          if (currentStep % 10 == 0) {
            _secondsRemaining = currentStep ~/ 10;
          }

          if (currentStep <= 0) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final locale = state.locale;

    return WillPopScope(
      onWillPop: () async => _secondsRemaining <= 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E293B), // Slate Dark
                    Color(0xFF0F172A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFD97706).withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top: Sponsor tag and countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.2),
                          border: Border.all(color: const Color(0xFFD97706), width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          locale == 'en' ? 'FEATURED SPONSOR' : 'TÀI TRỢ NỔI BẬT',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Close button or timer
                      GestureDetector(
                        onTap: _secondsRemaining <= 0 ? () {
                          Navigator.pop(context);
                          widget.onClose();
                        } : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _secondsRemaining <= 0
                                ? Colors.red.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _secondsRemaining <= 0
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_secondsRemaining > 0) ...[
                                Text(
                                  '$_secondsRemaining',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.timer_outlined, color: Colors.white54, size: 14),
                              ] else ...[
                                Text(
                                  locale == 'en' ? 'Close' : 'Đóng',
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.close_rounded, color: Colors.redAccent, size: 14),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Center Graphic/Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2), width: 2),
                    ),
                    child: Icon(
                      _selectedAd.graphicIcon,
                      color: const Color(0xFFF59E0B),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sponsor Titles
                  Text(
                    _selectedAd.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedAd.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Closing Progress Bar Timer
                  if (_secondsRemaining > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        color: const Color(0xFFF59E0B),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Call to Action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: const Color(0xFFF59E0B).withOpacity(0.3),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onClose();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(locale == 'en'
                                ? 'Navigating to special sponsorship deal...'
                                : 'Đang chuyển tới trang ưu đãi nhà tài trợ...'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFFF59E0B),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedAd.ctaText.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
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
}
