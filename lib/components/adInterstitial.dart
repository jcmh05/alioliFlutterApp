import 'package:alioli/components/components.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdInterstitial {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  final String _adUnitId = 'x';
  final String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // ID de prueba para intersticiales en Android

  final bool isTestAd;

  AdInterstitial({this.isTestAd = false}) {
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: isTestAd ? _testAdUnitId : _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;

          _interstitialAd!.setImmersiveMode(true);

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _isAdLoaded = false;
              _loadAd(); // Cargar un nuevo anuncio para la próxima vez
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _isAdLoaded = false;
              _loadAd(); // Intentar cargar de nuevo si falla
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
          // Puedes manejar el error aquí si lo deseas
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitial() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdLoaded = false;
    } else {
      print('Interstitial ad is not ready yet.');
      mostrarMensaje('Anuncio no disponible');
      _loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
