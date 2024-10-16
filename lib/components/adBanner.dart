import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool isTestAd;

  const AdBanner({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
    this.padding,
    this.isTestAd = false,
  }) : super(key: key);

  @override
  _AdBannerState createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-5900768209199281/9710269484';
  final String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // ID de prueba para banners en Android

  bool _isAdLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdLoading) {
      _isAdLoading = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final AdSize adSize = await _getAdSize();
    _bannerAd = BannerAd(
      adUnitId: widget.isTestAd ? _testAdUnitId : _adUnitId, // Usa el ID de prueba si isTestAd es true
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          // Maneja el fallo de carga del anuncio si es necesario
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<AdSize> _getAdSize() async {
    final AnchoredAdaptiveBannerAdSize? size =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );
    return size ?? AdSize.banner;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox.shrink();
    } else {
      return Container(
        margin: widget.margin ?? EdgeInsets.zero,
        padding: widget.padding ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          color: Colors.transparent,
        ),
        width: widget.width ?? _bannerAd!.size.width.toDouble(),
        height: widget.height ?? _bannerAd!.size.height.toDouble(),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
  }
}