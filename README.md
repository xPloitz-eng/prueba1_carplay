# Golf Performance 2.1 · ESCALA 6.000 RPM + ELM327 BLE + iPhone + CarPlay (experimental)

## Novedades de la versión 2.1 (23/11/2026)

- **Nuevo cuadro deportivo nativo SwiftUI**, inspirado en la demo horizontal: tacómetro semicircular con números **0, 1, 2, 3, 4, 5, 6** (×1.000 RPM), escala que termina en **6.000 RPM** y marcas rojas desde 5.000; velocidad y telemetría.
- **Modo pantalla completa** para el iPhone: pulsa «Ver cuadro deportivo a pantalla completa» y gira el iPhone. La app permite orientación horizontal izquierda/derecha. Las lecturas del panel proceden de OBD, y si no hay datos se muestra «—». La escala de 6.000 no implica que el motor pueda o deba alcanzar esas RPM.
- **Live Activity retocada**: muestra RPM, velocidad, refrigerante, barra con escala 0–6.000 y hora de última muestra. Puede visualizarse en CarPlay Dashboard con iOS 26, sujeto a limitaciones del sistema.
- Tu ELM327 confirmado por captura en Car Scanner: **Bluetooth LE (4.0+)**, nombre **`OBDII`**. Usa «Buscar adaptadores Bluetooth» y toca `OBDII`. Es posible que necesitemos adaptar las UUID si su firmware es distinto.
- El HTML `demo_golf_6000rpm.html` está incluido como **referencia visual**, pero no es parte de la app nativa.

**Qué hace de verdad:** La app iPhone se conecta a un adaptador ELM327 por **Bluetooth Low Energy (BLE)** o **Wi-Fi TCP**, inicializa el intérprete ELM, consulta datos OBD-II modo 01 y muestra RPM, velocidad, temperatura del refrigerante, carga del motor y presión absoluta de admisión (MAP). Las lecturas ausentes se muestran como **—**. Tiene modo DEMO marcado como simulado, y un registro de conexión.

**CarPlay:** Incluye una **Live Activity** de RPM/velocidad/temperatura que iOS 26 puede mostrar en el Dashboard de CarPlay. **No** estamos haciendo una app CarPlay a pantalla completa: ese diseño deportivo completo se ve en el **iPhone**, mientras que CarPlay muestra la **Live Activity reducida**. La app intenta actualizarla en el intervalo elegido (2–15 segundos, por defecto 3), **pero iOS puede limitar o retrasar la actualización y no hay garantía de visualización en CarPlay**. Car Scanner tiene un acceso a CarPlay diferente; una Live Activity **no es una aplicación CarPlay completa** ni reemplaza un cuadro de instrumentos. Los dos widgets estéticos del proyecto anterior permanecen; la telemetría real se transmite por la Live Activity, **no** por esos dos widgets.

**No es un tacómetro de seguridad.** No ajustes tu conducción según cifras retrasadas. No manipules el teléfono mientras conduces. Las funciones OBD enviadas son consultas de solo lectura (sin codificación de ECU, sin borrado de errores). Una conexión BLE puede continuar en segundo plano bajo circunstancias admitidas por iOS; la sesión Wi-Fi probablemente se suspenderá cuando la app quede en segundo plano. **No hace falta un adaptador nuevo si Car Scanner ya detecta el tuyo.**

## 1. Actualizar el repositorio existente desde Windows

Este ZIP **reemplaza el código del proyecto antiguo** y usa los mismos identificadores de app y la misma estructura raíz. Descomprímelo y copia **el contenido** de la carpeta `GolfWidgetsGratis/` dentro de la copia local de tu repositorio, conservando `.github/workflows/`.

Lo más fácil: instala [GitHub Desktop](https://desktop.github.com/), clona tu repositorio actual, copia encima los archivos nuevos y pulsa **Commit to main** y **Push origin**. Si usas Git:

```powershell
cd RUTA_A_TU_REPOSITORIO
# Copia aquí el contenido descomprimido de GolfWidgetsGratis (incluidas carpetas ios, scripts, tests)
git add -A
git commit -m "Golf Performance 2.0 ELM + Live Activity"
git push
```

No subas el ZIP como único archivo al repositorio; los `.swift` y `project.yml` deben quedar en la raíz esperada. La carpeta `.github` puede permanecer tal como la creaste la vez anterior: **el workflow original sigue funcionando**. Si usas una cuenta pública de GitHub, el código de este repositorio también será público.

## 2. Generar la IPA

En **Actions > Compilar IPA iPhone gratis (sin firmar)** ejecuta `Run workflow` en `main` (o espera al push automático); cuando acabe en verde, descarga `GolfWidgetsGratis-IPA` desde **Artifacts**, extrae `GolfWidgetsGratis.ipa` e instálalo con Sideloadly, como hiciste con la versión anterior.

La compilación necesita un runner macOS con Xcode 26. **Este proyecto no ha sido compilado con Xcode aquí**: he comprobado la sintaxis Swift con `swiftc -frontend -parse`, las pruebas del parser OBD en Linux y el Info.plist, pero la compilación final, firma y funcionamiento físico deben verificarse desde tu GitHub Actions/iPhone. Si GitHub Actions falla, copia la primera línea roja del error.

**Firma gratuita:** normalmente se renueva cada 7 días. Las extensiones de widgets y Live Activities pueden exigir capacidades que Sideloadly no consiga firmar correctamente; si falla, recopila el error antes de retirar ninguna extensión.

## 3. Cómo conectar tu ELM

1. Con el coche estacionado y el contacto dado, abre **Car Scanner > Ajustes > Adaptador OBDII ELM327** y apunta **tipo de conexión** (Bluetooth LE o Wi-Fi) y **modelo/nombre**. En Wi-Fi, apunta IP y puerto TCP. Car Scanner para iOS admite BLE, Wi-Fi y ciertos dispositivos MFi; no Bluetooth clásico genérico.
2. Cierra o desconecta **Car Scanner** antes de conectar la app nueva: un adaptador BLE normalmente no se puede manejar simultáneamente desde dos apps.
3. Abre **Golf Performance** y permite el uso de Bluetooth o red local.
4. En **Bluetooth LE**, pulsa «Buscar adaptadores Bluetooth» y selecciona **`OBDII`**. Si no sale, comprueba si el dispositivo BLE está encendido y desconectado de Car Scanner.
5. En **Wi-Fi**, conecta primero el iPhone a la red del ELM en Ajustes > Wi-Fi. Introduce la IP y el puerto que use Car Scanner (el valor `192.168.0.10:35000` del editor es un **ejemplo editable**, no un dato detectado).
6. El cuadro pasará de «—» a **valores reales** cuando el ELM devuelva respuestas. Si no, abre «Diagnóstico y conexión» y mira el error.
7. Pulsa **«Ver cuadro deportivo a pantalla completa»** en el iPhone para ver el tacómetro 0–6.000 en horizontal. Con valores reales visibles, pulsa **Iniciar en CarPlay**, permite las Actividades en directo y abre CarPlay Dashboard. Comprueba que en el iPhone está habilitado el permiso de Live Activities para esta app.
8. Selecciona el intervalo experimental de actualizaciones (2–15 s). **No garantiza el mismo refresco que Car Scanner**; el sistema elige cuándo dibujar la información. Bluetooth BLE tiene mejores opciones en segundo plano que un ELM Wi-Fi.

Si tu adaptador tiene un perfil BLE GATT diferente, dime la marca/modelo y la UUID de las características (captura desde alguna app de inspección BLE); el código intenta los perfiles habituales 18F0/2AF0/2AF1, Nordic UART, FFE0/FFE1, y un fallback genérico. La compatibilidad concreta del dispositivo `OBDII` no está verificada en este proyecto.

## 4. Comprobaciones locales

La lógica de respuestas ELM se prueba sin ECU ni hardware:

```bash
swiftc ios/Shared/ELMParser.swift tests/ELMParserTests.swift -o elmtest
./elmtest
```

El parser ha pasado estas pruebas en Linux: `410C1AF8` = **1726 rpm**, `410D64` = **100 km/h**, `41057B` = **83 °C**, `410480` = **50,2 % carga**, `410B65` = **101 kPa**, y respuestas `NO DATA` o solo eco no se convierten en datos falsos.

## 5. Limitaciones técnicas que debemos respetar

- Los **widgets WidgetKit** normales no permiten actualizarse cada fracción de segundo. Por eso probamos **Live Activity**, que Apple permite mostrar en CarPlay con iOS 26, pero tampoco es una pantalla 100 % libre ni de refresco garantizado.
- Una **app CarPlay completa** con panel persistente suele requerir una **capacidad/entitlement CarPlay** autorizada por Apple. No se consigue automáticamente al instalar un `.ipa` sin firmar o con Sideloadly. No hemos implementado una app CarPlay con entitlement.
- OBD-II estándar puede no ofrecer todos los sensores: RPM (010C), velocidad (010D), refrigerante (0105), carga (0104), presión MAP (010B), admisión (010F) y presión barométrica (0133) dependen de la ECU. MAP **no equivale directamente a presión del turbo**. Consumo real y PIDs específicos VW no están implementados todavía.
- La BLE en segundo plano no garantiza muestreo constante; la Wi-Fi en segundo plano es todavía más limitada. Si iOS suspende la app, la actividad puede quedar con datos antiguos.
- El proyecto sigue siendo **experimental** y no se ha probado físicamente en el Golf ni en el iPhone del usuario.

## Fuentes técnicas

- Apple CarPlay: https://developer.apple.com/carplay/
- WWDC 2025 CarPlay + Live Activities: https://developer.apple.com/videos/play/wwdc2025/216/
- Apple Core Bluetooth background: https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html
- Car Scanner conectividad: https://www.carscanner.info/faq/ y https://www.carscanner.info/choosing-obdii-adapter/
