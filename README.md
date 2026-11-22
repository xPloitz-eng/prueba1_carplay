# Golf Widgets GRATIS — Windows + iPhone + CarPlay (experimental)

Esta edición evita **la cuota anual del Apple Developer Program**, no usa App Groups y permite compilar una IPA sin firmar en un **Mac de GitHub Actions**. Después Sideloadly puede intentar firmarla e instalarla desde Windows con el Apple ID gratuito.

**Limitación importante:** la instalación con firma gratuita caduca a los **7 días**. Los widgets y las extensiones en instalaciones de terceros pueden fallar por la firma o no aparecer en CarPlay; no se garantiza que funcionen hasta probarlo en el iPhone y el coche. La IPA **no está compilada** aquí, porque este entorno no tiene Xcode.

## A. Personalizar en Windows

1. Descomprime el ZIP.
2. En PowerShell dentro de la carpeta: `py -3 preview.py`.
3. Abre `http://127.0.0.1:8765`.
4. Cambia los diseños **Deportivo** y **Personalizado** y pulsa guardar. Se actualiza `config.json`.
5. Cierra el servidor con Ctrl+C.

Los ajustes se integran **en la compilación**. Por eso son gratuitos y no necesitan App Groups: para cambiarlos en CarPlay más adelante, modifica `config.json`, recompila y reinstala la IPA. La app instalada en iPhone sirve para visualizar los presets, no para modificarlos en tiempo real.

## B. Crear la IPA gratis en GitHub

1. Crea una cuenta en https://github.com/ si aún no tienes.
2. Crea un repositorio **público** vacío, por ejemplo `golf-widgets` (evita subir datos privados; en repos públicos GitHub Actions con runners estándar es gratis).
3. **Sube el CONTENIDO de esta carpeta** a la raíz del repositorio, incluyendo `.github/workflows/`. En Windows usa Git para incluir los archivos ocultos. Puedes hacerlo desde PowerShell en esta carpeta:

    ```powershell
    git init
    git add .
    git commit -m "Golf Widgets gratis"
    git branch -M main
    git remote add origin https://github.com/TU_USUARIO/golf-widgets.git
    git push -u origin main
    ```

    Sustituye `TU_USUARIO` por tu usuario de GitHub. Git puede pedir autenticación. Si el repositorio tenía un README inicial, crea otro vacío para simplificar el primer push.
4. En la web de GitHub abre **Actions** > **Compilar IPA iPhone gratis (sin firmar)** > **Run workflow**. El workflow también se lanza automáticamente con cada `git push`.
5. Cuando finalice, en la ejecución abre **Artifacts** y descarga **GolfWidgetsGratis-IPA**. Descomprime el artefacto para obtener `GolfWidgetsGratis.ipa`.

El workflow instala XcodeGen, genera los presets Swift, crea el proyecto Xcode, compila la app+extensión WidgetKit **para iPhone** y empaqueta una **IPA sin firmar**. Si GitHub muestra errores, revisa los logs antes de instalar.

## C. Instalar desde Windows con cuenta gratis

1. Descarga **Sideloadly** desde https://sideloadly.io/ (página oficial).
2. Instala los componentes de Apple que solicite Sideloadly en Windows y conecta el iPhone por USB.
3. Abre Sideloadly y carga `GolfWidgetsGratis.ipa`.
4. Selecciona tu iPhone e inicia sesión con tu Apple ID en Sideloadly (si lo deseas usa una cuenta secundaria). Deja **activas las extensiones**; si las eliminas, los widgets desaparecerán.
5. Instala la IPA; en el iPhone activa **Modo desarrollador** en Ajustes > Privacidad y seguridad si aparece y confía en el perfil de la aplicación cuando iOS lo pida.
6. Comprueba primero que salen los dos widgets en la galería de widgets del iPhone. Si aparecen, conecta CarPlay: Ajustes > General > CarPlay > Golf > Widgets. Necesitas iOS 26 o posterior.
7. Usa el refresco automático de Sideloadly o reinstala/firma al menos cada siete días.

No compres certificados de terceros, no desactives controles de seguridad del iPhone y no uses sitios de IPA desconocidos.

## D. Límites reales

- Sin Apple Developer Program no hay TestFlight ni distribución convencional por App Store.
- Cuenta Apple gratuita: provisiones de 7 días y límite de apps de prueba; el proyecto tiene app principal + extensión de widgets.
- **No se usa App Group**, para evitar la dependencia de una capacidad que puede dar problemas con sideloading. Si quieres editar desde la app del iPhone y reflejarlo inmediatamente en el widget, habría que investigar una ruta de firma con App Groups que funcione en tu dispositivo.
- El código de esta versión es un **prototipo sin compilación real verificada**. La compilación y compatibilidad de las extensiones dependen de Xcode/GitHub/Sideloadly e iOS.
- No usa datos reales del motor. Un widget no sirve para ver telemetría de seguridad en tiempo real.

Fuentes:
- https://developer.apple.com/help/account/basics/about-your-developer-account/
- https://developer.apple.com/download/files/CarPlay-Developer-Guide.pdf
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run
- https://sideloadly.io/
