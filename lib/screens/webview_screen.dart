import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/user_agent.dart';
import '../utils/injected_css.dart';
import '../utils/injected_js.dart';
import '../services/notification_service.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;
  DateTime? _lastBackPressed;

  static const String _whatsappUrl = 'https://web.whatsapp.com';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
  }

  void _initWebView() {
    // Configuración específica por plataforma
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS - WKWebView
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(UserAgentConfig.desktopUserAgent)
      ..setBackgroundColor(const Color(0xFF111B21))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onProgress: (progress) {
            setState(() => _loadingProgress = progress);
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            await _injectAssets();
          },
          onWebResourceError: (error) {
            // Ignorar errores de recursos secundarios (ads, trackers, etc.)
            if (error.isForMainFrame ?? false) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            // Bloquear navegación fuera de WhatsApp Web
            final uri = Uri.parse(request.url);
            if (uri.host.contains('whatsapp.com') ||
                uri.host.contains('whatsapp.net')) {
              return NavigationDecision.navigate;
            }
            // Bloquear URLs externas
            debugPrint('Blocked navigation to: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onJsMessage,
      );

    // Configuración específica Android
    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            final granted = await Permission.location.request().isGranted;
            return GeolocationPermissionsResponse(
              allow: granted,
              retain: false,
            );
          },
          onHidePrompt: () {},
        );

      // Habilitar permisos de cámara y micrófono en Android
      AndroidWebViewController.enableDebugging(false);
    }

    // Configuración específica iOS
    if (_controller.platform is WebKitWebViewController) {
      final iosController = _controller.platform as WebKitWebViewController;
      iosController.setAllowsBackForwardNavigationGestures(true);
    }

    _controller.loadRequest(Uri.parse(_whatsappUrl));
  }

  /// Inyectar CSS y JS adaptativos después de que cargue la página
  Future<void> _injectAssets() async {
    try {
      // 1. Inyectar CSS de adaptación móvil
      await _controller.runJavaScript(InjectedCSS.getInjectionScript());

      // 2. Pequeña pausa para que aplique el CSS
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Inyectar JS de funcionalidades
      await _controller.runJavaScript(InjectedJS.getInjectionScript());

      debugPrint('Assets inyectados correctamente');
    } catch (e) {
      debugPrint('Error inyectando assets: $e');
    }
  }

  /// Manejar mensajes desde JavaScript
  void _onJsMessage(JavaScriptMessage message) {
    final data = message.message;
    debugPrint('JS Bridge: $data');

    if (data.startsWith('notification:')) {
      final parts = data.substring('notification:'.length).split('|');
      if (parts.length >= 2) {
        NotificationService.showNotification(
          title: parts[0],
          body: parts[1],
        );
      }
    } else if (data == 'request_camera') {
      _requestMediaPermissions();
    }
  }

  Future<void> _requestMediaPermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    final granted = camera.isGranted && mic.isGranted;
    await _controller.runJavaScript(
      'window._flutterPermissionsGranted = $granted;',
    );
  }

  Future<bool> _onWillPop() async {
    // Intentar navegar hacia atrás en el WebView primero
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }

    // Doble tap para salir
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presiona atrás de nuevo para salir'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Recargar'),
              onTap: () {
                Navigator.pop(ctx);
                _controller.reload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.desktop_windows),
              title: const Text('Forzar vista escritorio'),
              onTap: () {
                Navigator.pop(ctx);
                _controller.loadRequest(Uri.parse(_whatsappUrl));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Limpiar caché y sesión'),
              onTap: () {
                Navigator.pop(ctx);
                _showClearCacheDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(ctx);
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar sesión'),
        content: const Text(
          'Esto cerrará la sesión de WhatsApp y tendrás que volver a vincular el QR. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.clearCache();
              await _controller.clearLocalStorage();
              await _controller.loadRequest(Uri.parse(_whatsappUrl));
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'WA Client',
      applicationVersion: '1.0.0',
      children: const [
        Text(
          'Aplicación educativa basada en WhatsApp Web. '
          'No está afiliada con Meta Platforms, Inc.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111B21),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // WebView principal
            WebViewWidget(controller: _controller),

            // Barra de progreso de carga
            if (_isLoading && _loadingProgress < 100)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF25D366),
                  ),
                  minHeight: 3,
                ),
              ),

            // Pantalla de error
            if (_hasError) _buildErrorWidget(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF075E54),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.chat_rounded, size: 22),
          const SizedBox(width: 8),
          const Text(
            'WA Client',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (_isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Recargar',
          onPressed: () => _controller.reload(),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Menú',
          onPressed: () => _showMenu(context),
        ),
      ],
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF075E54),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF111B21),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar WhatsApp Web',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifica tu conexión a internet e intenta de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _controller.reload(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
