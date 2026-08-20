/// CSS inyectado en WhatsApp Web para adaptar la interfaz al tamaño móvil.
/// Se ejecuta después de que la página termina de cargar.
class InjectedCSS {
  InjectedCSS._();

  static String getInjectionScript() {
    // El CSS se inyecta creando un <style> en el <head>
    final css = _mobileCss.replaceAll('\n', ' ').replaceAll("'", "\\'");
    return '''
(function() {
  // Evitar inyección duplicada
  if (document.getElementById('flutter-wa-style')) return;

  const style = document.createElement('style');
  style.id = 'flutter-wa-style';
  style.textContent = '$css';
  document.head.appendChild(style);

  console.log('[WA Client] CSS inyectado correctamente');
})();
''';
  }

  /// CSS que adapta la interfaz de escritorio de WhatsApp Web a pantalla móvil
  static const String _mobileCss = '''
    /* ============================================================
       WA Client — CSS de adaptación móvil
       Adapta la UI de escritorio de WhatsApp Web a pantalla chica
    ============================================================ */

    /* Forzar viewport completo sin borde de escritorio */
    body, html {
      width: 100% !important;
      height: 100% !important;
      overflow: hidden !important;
    }

    /* Contenedor principal — ocupar todo el ancho */
    #app, 
    ._aigs,
    [data-testid="default-user"] {
      width: 100% !important;
      max-width: 100% !important;
    }

    /* Panel lateral de chats: visible en mobile, ocupa todo el ancho 
       cuando no hay chat activo */
    #pane-side,
    ._aigw {
      width: 100% !important;
      min-width: unset !important;
      flex: 1 !important;
    }

    /* Ocultar el panel lateral cuando hay un chat abierto en mobile */
    @media (max-width: 768px) {
      #pane-side.is-active-chat {
        display: none !important;
      }

      /* El panel de conversación ocupa todo el ancho */
      #main {
        width: 100% !important;
        left: 0 !important;
        position: relative !important;
      }
    }

    /* Barra de búsqueda y encabezado del panel lateral */
    ._aigv,
    [data-testid="chat-list-search"] {
      font-size: 15px !important;
    }

    /* Ajustar tamaño de texto en lista de chats */
    ._ao3e, ._aohh {
      font-size: 14px !important;
    }

    /* Thumbnail de contacto — tamaño táctil adecuado */
    ._aig-, ._ao3f {
      width: 48px !important;
      height: 48px !important;
    }

    /* Input de mensaje — más alto para dedos */
    [data-testid="conversation-compose-box-input"],
    ._ak1r {
      font-size: 15px !important;
      min-height: 44px !important;
      padding: 8px 12px !important;
    }

    /* Botones de acción (enviar, adjunto, emoji) — área táctil */
    [data-testid="send-button"],
    [data-testid="attach-button"],
    [data-testid="compose-btn-send"],
    ._ak1s, ._ak1t {
      min-width: 44px !important;
      min-height: 44px !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
    }

    /* Burbujas de mensaje — padding móvil */
    ._akbu, .message-in, .message-out,
    [data-testid="msg-container"] {
      max-width: 85% !important;
    }

    /* Ocultar elementos innecesarios en pantalla pequeña */
    /* Barra de descarga de app móvil de WhatsApp */
    [data-testid="app-download-banner"],
    .app-wrapper-web > ._ajv7 {
      display: none !important;
    }

    /* Scrollbar delgada en listas */
    ::-webkit-scrollbar {
      width: 4px !important;
      height: 4px !important;
    }
    ::-webkit-scrollbar-track {
      background: transparent !important;
    }
    ::-webkit-scrollbar-thumb {
      background: rgba(255,255,255,0.2) !important;
      border-radius: 2px !important;
    }

    /* Mejorar tap highlight en móvil */
    * {
      -webkit-tap-highlight-color: rgba(37, 211, 102, 0.2) !important;
    }

    /* Encabezado del chat — botones de llamada visibles */
    [data-testid="conversation-header"] {
      display: flex !important;
      align-items: center !important;
      padding: 4px 8px !important;
    }

    /* Botones de llamada de voz y video en la cabecera */
    [data-testid="conversation-header"] button,
    ._ak17 button {
      min-width: 40px !important;
      min-height: 40px !important;
    }

    /* Pantalla de vinculación QR — centrar y escalar bien */
    [data-testid="qrcode"],
    ._akau {
      max-width: 260px !important;
      margin: 0 auto !important;
    }

    /* Texto de instrucciones del QR */
    ._akas {
      font-size: 14px !important;
      text-align: center !important;
      padding: 0 16px !important;
    }

    /* Pantalla de carga inicial */
    .landing-wrapper {
      padding: 16px !important;
    }

    /* Menú contextual de mensajes — más grande */
    [data-testid="popup-contents"] {
      font-size: 15px !important;
    }
    [data-testid="popup-contents"] li {
      padding: 12px 16px !important;
    }

    /* Modal de imagen/video — ocupar pantalla completa */
    [data-testid="media-viewer-container"] {
      width: 100vw !important;
      height: 100vh !important;
    }

    /* Indicador de escritura */
    ._ak9g {
      font-size: 12px !important;
    }

    /* Hora de mensaje */
    ._akq, [data-testid="msg-time"] {
      font-size: 11px !important;
    }
  ''';
}
