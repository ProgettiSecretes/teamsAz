import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Forza orientamento portrait + landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TeamsApp());
}

class TeamsApp extends StatelessWidget {
  const TeamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teams',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6264A7), // Viola Teams
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TeamsWebView(),
    );
  }
}

class TeamsWebView extends StatefulWidget {
  const TeamsWebView({super.key});

  @override
  State<TeamsWebView> createState() => _TeamsWebViewState();
}

class _TeamsWebViewState extends State<TeamsWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isConnected = true;
  double _progress = 0;

  // User Agent desktop Chrome su Windows — fondamentale per Teams web
  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';

  static const String _teamsUrl = 'https://teams.microsoft.com';

  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        setState(() => _isConnected = connected);
        if (connected && _hasError) {
          _reload();
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result.any((r) => r != ConnectivityResult.none);
    });
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController?.canGoBack() ?? false) {
          await _webViewController?.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF201F1F),
        body: SafeArea(
          child: Stack(
            children: [
              // ── Schermata no-internet ──────────────────────────────
              if (!_isConnected)
                _buildNoConnectionScreen()
              else ...[
                // ── WebView principale ─────────────────────────────
                InAppWebView(
                  key: _webViewKey,
                  initialUrlRequest: URLRequest(
                    url: WebUri(_teamsUrl),
                  ),
                  initialSettings: InAppWebViewSettings(
                    userAgent: _desktopUserAgent,
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    // Desktop viewport
                    useWideViewPort: true,
                    loadWithOverviewMode: true,
                    // Cookie e sessioni
                    thirdPartyCookiesEnabled: true,
                    // Microfono e fotocamera per chiamate
                    allowsAirPlayForMediaPlayback: true,
                    // Geolocation
                    geolocationEnabled: true,
                    // Cache
                    cacheEnabled: true,
                    // Permetti tutti i contenuti misti
                    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() => _isLoading = false);
                    // Inject JS per ottimizzare la visualizzazione mobile
                    await controller.evaluateJavascript(source: '''
                      // Rimuove eventuali banner "usa l'app nativa"
                      const removeBanners = () => {
                        const selectors = [
                          '[data-tid="app-download-prompt"]',
                          '.ts-download-app-banner',
                          '#download-app-banner',
                        ];
                        selectors.forEach(s => {
                          const el = document.querySelector(s);
                          if (el) el.remove();
                        });
                      };
                      removeBanners();
                      setTimeout(removeBanners, 2000);
                      setTimeout(removeBanners, 5000);
                    ''');
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame ?? false) {
                      setState(() {
                        _isLoading = false;
                        _hasError = true;
                      });
                    }
                  },
                  onPermissionRequest: (controller, request) async {
                    // Accetta automaticamente microfono, fotocamera, ecc.
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url?.toString() ?? '';
                    // Blocca tentativi di aprire l'app nativa Teams
                    if (url.startsWith('msteams://') || url.startsWith('ms-teams://')) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),

                // ── Errore caricamento ─────────────────────────────
                if (_hasError) _buildErrorScreen(),

                // ── Barra progresso in cima ────────────────────────
                if (_isLoading && !_hasError)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: Colors.transparent,
                      color: const Color(0xFF6264A7),
                      minHeight: 3,
                    ),
                  ),

                // ── Splash iniziale ────────────────────────────────
                if (_isLoading && _progress < 0.1)
                  _buildSplashScreen(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Container(
      color: const Color(0xFF201F1F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6264A7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Microsoft Teams',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Color(0xFF6264A7),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionScreen() {
    return Container(
      color: const Color(0xFF201F1F),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nessuna connessione',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Controlla la tua connessione internet e riprova.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await _checkConnectivity();
                  if (_isConnected) _reload();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Riprova'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6264A7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: const Color(0xFF201F1F),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Errore di caricamento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Impossibile caricare Teams. Verifica la connessione.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Ricarica'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6264A7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
