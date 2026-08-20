/// User-Agent strings para forzar la vista de escritorio en WhatsApp Web.
/// WhatsApp Web detecta el UA para mostrar la interfaz correcta.
class UserAgentConfig {
  UserAgentConfig._();

  /// UA de Chrome en Windows — el más compatible con WhatsApp Web
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/126.0.0.0 Safari/537.36';

  /// UA de Chrome en macOS (alternativa)
  static const String desktopMacUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/126.0.0.0 Safari/537.36';

  /// UA de Safari en iPad — fuerza vista tablet (más amigable en móvil)
  static const String tabletUserAgent =
      'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.0 Mobile/15E148 Safari/604.1';
}
