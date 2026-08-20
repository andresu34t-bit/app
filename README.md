# WA Client — Flutter WebView

> ⚠️ **Solo para uso educativo y personal.** Esta app no está afiliada con Meta Platforms, Inc.
> El uso puede violar los Términos de Servicio de WhatsApp. Úsala bajo tu propio riesgo.

## Cómo funciona

Carga `web.whatsapp.com` en un WebView con:
- **User-Agent de Chrome escritorio** → WhatsApp muestra la interfaz completa
- **CSS inyectado** → adapta la UI al tamaño de pantalla móvil
- **JS inyectado** → intercepta notificaciones, maneja permisos y navegación móvil
- **Permisos nativos** → cámara, micrófono, notificaciones y almacenamiento

---

## Requisitos

- Flutter SDK ≥ 3.0
- Android: minSdk 21 (Android 5.0+)
- iOS: iOS 12+
- Conexión a internet activa

---

## Setup rápido

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar en Android
flutter run

# 3. Ejecutar en iOS (requiere macOS + Xcode)
cd ios && pod install && cd ..
flutter run
```

---

## Estructura del proyecto

```
lib/
├── main.dart                   # Entry point, permisos iniciales
├── screens/
│   ├── splash_screen.dart      # Pantalla de carga + verificación de red
│   └── webview_screen.dart     # WebView principal con toda la lógica
├── utils/
│   ├── user_agent.dart         # User-Agent strings de escritorio
│   ├── injected_css.dart       # CSS de adaptación móvil
│   └── injected_js.dart        # JS bridge: notificaciones, permisos, nav
└── services/
    └── notification_service.dart  # Notificaciones locales nativas
```

---

## Permisos solicitados

| Permiso | Motivo |
|---|---|
| Cámara | Videollamadas y enviar fotos |
| Micrófono | Llamadas de voz y notas de voz |
| Almacenamiento | Enviar y descargar archivos |
| Notificaciones | Avisar mensajes recibidos |

---

## Limitaciones conocidas

| Funcionalidad | Estado |
|---|---|
| Mensajes de texto | ✅ Funciona |
| Imágenes y archivos | ✅ Funciona |
| Notas de voz | ✅ Funciona |
| Notificaciones | ✅ Con bridge JS→Flutter |
| Llamadas de voz | ⚠️ Depende del soporte WebRTC del WebView |
| Videollamadas | ⚠️ Limitado — WebRTC en WebView no es full estable |
| Stickers | ✅ Funciona |
| Grupos | ✅ Funciona |

---

## Solución de problemas

**WhatsApp muestra "Usa WhatsApp en tu teléfono"**
→ El User-Agent de escritorio debería prevenirlo. Si ocurre, recarga la página.

**Las llamadas no funcionan**
→ Es la limitación más conocida del enfoque WebView. En Android, el WebView
  de sistema puede no tener acceso completo a WebRTC. Intenta actualizar
  el Android System WebView desde la Play Store.

**Notificaciones no aparecen**
→ Verifica que los permisos de notificación estén habilitados en
  Ajustes del sistema → Aplicaciones → WA Client.

**La sesión se cierra sola**
→ WhatsApp Web detecta inactividad o el WebView fue terminado por el SO
  para liberar RAM. Es normal en dispositivos con poca memoria.
