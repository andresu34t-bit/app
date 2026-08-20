/// JavaScript inyectado en WhatsApp Web para mejorar la experiencia móvil:
/// - Interceptar notificaciones del navegador y pasarlas a Flutter
/// - Pedir permisos de cámara/micrófono vía bridge
/// - Manejo del panel lateral en modo móvil
/// - Deshabilitar el banner de descarga de la app
class InjectedJS {
  InjectedJS._();

  static String getInjectionScript() {
    return r'''
(function() {
  // Evitar ejecución duplicada
  if (window._waClientInjected) return;
  window._waClientInjected = true;

  console.log('[WA Client] JS bridge inicializado');

  // ============================================================
  // 1. INTERCEPTAR NOTIFICACIONES DEL NAVEGADOR
  //    Las redirigimos a Flutter a través del canal FlutterBridge
  // ============================================================
  const OriginalNotification = window.Notification;

  window.Notification = function(title, options) {
    // Enviar a Flutter
    if (window.FlutterBridge) {
      const body = (options && options.body) ? options.body : '';
      window.FlutterBridge.postMessage('notification:' + title + '|' + body);
    }
    // También crear la notificación nativa del navegador (por si funciona)
    try {
      return new OriginalNotification(title, options);
    } catch(e) {
      return { close: function() {} };
    }
  };

  // Copiar propiedades estáticas
  window.Notification.requestPermission = function() {
    return Promise.resolve('granted');
  };
  window.Notification.permission = 'granted';

  // ============================================================
  // 2. SOLICITAR PERMISOS DE CÁMARA/MICRÓFONO
  //    Interceptamos getUserMedia para pedir permisos a Flutter
  //    antes de que el navegador lo haga
  // ============================================================
  const originalGetUserMedia = navigator.mediaDevices
    ? navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices)
    : null;

  if (navigator.mediaDevices && originalGetUserMedia) {
    navigator.mediaDevices.getUserMedia = async function(constraints) {
      // Notificar a Flutter que se necesitan permisos
      if (window.FlutterBridge) {
        window.FlutterBridge.postMessage('request_camera');
      }
      // Pequeña espera para que Flutter procese los permisos
      await new Promise(resolve => setTimeout(resolve, 500));
      return originalGetUserMedia(constraints);
    };
  }

  // ============================================================
  // 3. NAVEGACIÓN ENTRE PANEL Y CHAT (modo móvil)
  //    Cuando se abre un chat, ocultar la lista lateral
  //    Cuando se cierra, volver a mostrarla
  // ============================================================
  function handleMobileNav() {
    const paneMain = document.getElementById('main');
    const paneSide = document.getElementById('pane-side');

    if (!paneMain || !paneSide) return;

    // Observar cambios en el DOM para detectar apertura de chat
    const observer = new MutationObserver(function() {
      const hasActiveChat = paneMain &&
        paneMain.querySelector('[data-testid="conversation-panel-wrapper"]');

      if (window.innerWidth <= 768) {
        if (hasActiveChat) {
          paneSide.style.display = 'none';
          paneMain.style.width = '100%';
          paneMain.style.position = 'relative';
        } else {
          paneSide.style.display = 'flex';
          paneSide.style.width = '100%';
          paneMain.style.display = 'none';
        }
      } else {
        // En pantallas grandes, restablecer comportamiento normal
        paneSide.style.display = '';
        paneMain.style.display = '';
        paneMain.style.width = '';
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  // ============================================================
  // 4. BOTÓN DE REGRESO EN EL CHAT (mobile)
  //    Agrega un botón nativo de regreso dentro del header del chat
  // ============================================================
  function addBackButton() {
    if (window.innerWidth > 768) return;

    const header = document.querySelector(
      '[data-testid="conversation-header"]'
    );
    if (!header || header.querySelector('#flutter-back-btn')) return;

    const backBtn = document.createElement('button');
    backBtn.id = 'flutter-back-btn';
    backBtn.innerHTML = '&#8592;'; // ←
    backBtn.style.cssText = `
      background: none;
      border: none;
      color: inherit;
      font-size: 22px;
      padding: 8px;
      cursor: pointer;
      min-width: 40px;
      min-height: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
    `;
    backBtn.addEventListener('click', function() {
      const paneSide = document.getElementById('pane-side');
      const paneMain = document.getElementById('main');
      if (paneSide) paneSide.style.display = 'flex';
      if (paneMain) paneMain.style.display = 'none';
    });

    header.insertBefore(backBtn, header.firstChild);
  }

  // ============================================================
  // 5. OCULTAR EL BANNER "DESCARGA LA APP MÓVIL"
  // ============================================================
  function hideMobileAppBanner() {
    const selectors = [
      '[data-testid="app-download-banner"]',
      '._ajv7',
      '.app-wrapper-web [role="banner"]',
    ];
    selectors.forEach(sel => {
      document.querySelectorAll(sel).forEach(el => {
        el.style.display = 'none';
      });
    });
  }

  // ============================================================
  // 6. OBSERVADOR GENERAL DEL DOM
  //    Reaplicar mejoras cuando WhatsApp actualice el DOM dinámicamente
  // ============================================================
  const domObserver = new MutationObserver(function(mutations) {
    for (const mutation of mutations) {
      if (mutation.addedNodes.length > 0) {
        hideMobileAppBanner();
        addBackButton();
      }
    }
  });

  domObserver.observe(document.body, {
    childList: true,
    subtree: true,
  });

  // ============================================================
  // 7. HANDLE RESIZE — ajustar layout al rotar pantalla
  // ============================================================
  window.addEventListener('resize', function() {
    handleMobileNav();
  });

  // ============================================================
  // 8. EJECUCIÓN INICIAL
  // ============================================================
  // Esperar a que WhatsApp Web termine de renderizar sus componentes
  setTimeout(function() {
    hideMobileAppBanner();
    handleMobileNav();
    addBackButton();
  }, 2000);

  // Un segundo intento más tarde por si la app tarda más
  setTimeout(function() {
    hideMobileAppBanner();
    addBackButton();
  }, 5000);

  console.log('[WA Client] JS bridge listo');
})();
''';
  }
}
