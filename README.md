# App Bank - Control de Gastos Personales 🚀

Aplicación móvil desarrollada con **Flutter** y **Firebase** para la gestión inteligente de finanzas personales.

## 📋 Características actuales
- **Onboarding Interactivo**: Introducción de 5 ventanas deslizables con diseño moderno.
- **Autenticación Robusta**: 
  - Registro con validación de doble contraseña y visibilidad opcional.
  - Inicio de sesión con Email/Password.
  - Integración con **Google Sign-In**.
- **Base de Datos en Tiempo Real**: Sincronización automática con Cloud Firestore.
- **Dashboard Base**: Estructura principal con navegación inferior y botón de acción central.

---

## 🛠️ Pasos para Iniciar el Proyecto

Sigue estos pasos para configurar y ejecutar la aplicación en tu entorno local.

### 1. Requisitos Previos
- Tener instalado [Flutter](https://docs.flutter.dev/get-started/install) (versión 3.27 o superior recomendada).
- Tener instalado [Android Studio](https://developer.android.com/studio) o VS Code con el plugin de Flutter.
- Un dispositivo físico (Android) o emulador configurado.

### 2. Clonar y Preparar
```bash
# Descargar dependencias
flutter pub get
```

### 3. Configuración de Firebase (CRÍTICO)
Para que la aplicación se conecte correctamente a la base de datos, debes configurar tu propio proyecto en Firebase:

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Agrega una **App de Android** con el nombre de paquete: `com.example.app_bank`.
3. **Huellas Digitales (SHA)**:
   - Ejecuta en la terminal: `cd android && ./gradlew signingReport`.
   - Copia el código **SHA-1** y **SHA-256**.
   - Pégalos en la configuración de tu app en Firebase.
4. **Archivo de Configuración**:
   - Descarga `google-services.json` desde Firebase.
   - Colócalo en la carpeta: `android/app/`.
5. **Habilitar Servicios**:
   - En Firebase, activa **Authentication** (Email y Google).
   - Crea la base de datos **Firestore** y publica las reglas de acceso.

### 4. Ejecución
Para evitar advertencias de versiones de Gradle en versiones recientes de Flutter, usa el siguiente comando:

```bash
# Limpiar caché previa
flutter clean

# Ejecutar en el dispositivo
flutter run --android-skip-build-dependency-validation
```

---

## 🎨 Paleta de Colores
- **Fondo**: `#0B0E11` (Negro profundo)
- **Superficie**: `#151921` (Gris azulado)
- **Principal**: `#007AFF` (Azul vibrante)

---

## 🚀 Próximos Pasos
- [ ] Implementar Formulario de Gasto Real.
- [ ] Vincular Gráficos (`fl_chart`) con datos de Firestore.
- [ ] Crear Pantalla de Perfil y Configuración.
