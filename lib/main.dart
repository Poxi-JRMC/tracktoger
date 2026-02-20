import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_theme.dart';
import 'core/auth_service.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'controllers/control_maquinaria.dart';
import 'controllers/control_mantenimiento.dart';
import 'controllers/control_reportes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'data/services/database_service.dart'; // Importa el servicio de base de datos
import 'services/app_link_service.dart'; // Importa el servicio de app links

void main() async {
  // Asegurar binding antes de operaciones asíncronas de inicialización
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ Archivo .env cargado correctamente");
  } catch (e) {
    print("⚠️ Error cargando .env: $e");
  }

  // Inicializar datos de prueba
  ControlMaquinaria.inicializarDatosPrueba();
  ControlMantenimiento.inicializarDatosPrueba();
  ControlReportes.inicializarDatosPrueba();

  // Inicializar servicio de autenticación
  await AuthService.initialize();

  // Inicializar servicio de app links para manejar deep links
  try {
    await AppLinkService().initialize();
    print("✅ AppLinkService inicializado");
  } catch (e) {
    print("⚠️ Error inicializando AppLinkService: $e");
    // No bloqueamos la app si falla la inicialización de app links
  }

  // Inicializar y conectar singleton de DB. No cerramos la conexión aquí
  // para que la app mantenga la conexión durante la ejecución.
  try {
    await DatabaseService().conectar();
  } catch (e) {
    // Ya se imprimió el error en DatabaseService; aquí solo evitamos que
    // la app se caiga por una excepción no atrapada durante el arranque.
    print('ADVERTENCIA: fallo al conectar con la BD durante el arranque: $e');
  }

  runApp(const GerotrackApp());
}

class GerotrackApp extends StatefulWidget {
  const GerotrackApp({super.key});

  @override
  State<GerotrackApp> createState() => _GerotrackAppState();
}

class _GerotrackAppState extends State<GerotrackApp> with WidgetsBindingObserver {
  bool isAuthenticated = false;
  String appState = "splash";
  String currentScreen = "home";

  @override
  void initState() {
    super.initState();
    // Registrar observer para el ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    // Espera 4 segundos y luego verifica auth
    Future.delayed(const Duration(seconds: 4), checkAuth);
  }

  @override
  void dispose() {
    // Remover observer cuando se destruye el widget
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final dbService = DatabaseService();
    
    switch (state) {
      case AppLifecycleState.resumed:
        // La app volvió al primer plano - verificar y mantener conexión activa
        print('📱 App volvió al primer plano - verificando conexión a BD...');
        // Ejecutar reconexión de forma asíncrona para no bloquear la UI
        _verificarYReconectarBD();
        break;
        
      case AppLifecycleState.paused:
        // La app se fue al segundo plano - NO cerrar conexión, mantener activa
        print('📱 App en segundo plano - manteniendo conexión activa');
        // El keep-alive seguirá funcionando si es posible
        break;
        
      case AppLifecycleState.inactive:
        // La app está inactiva (transición) - mantener conexión
        print('📱 App inactiva (transición) - manteniendo conexión');
        break;
        
      case AppLifecycleState.detached:
        // La app está siendo destruida completamente - solo aquí cerramos conexión
        print('📱 App siendo destruida - cerrando conexión a BD');
        dbService.cerrarConexion();
        break;
        
      case AppLifecycleState.hidden:
        // Estado oculto - mantener conexión activa
        print('📱 App oculta - manteniendo conexión');
        break;
    }
  }

  /// Verifica y reconecta la base de datos cuando la app vuelve al primer plano
  /// Este método se ejecuta de forma asíncrona para no bloquear la UI
  Future<void> _verificarYReconectarBD() async {
    try {
      print('🔍 Iniciando verificación y reconexión de BD...');
      final dbService = DatabaseService();
      
      // Reconectar con retry robusto (máximo 3 intentos)
      await dbService.reconectarSiEsNecesario(maxIntentos: 3);
      
      // Asegurar que el keep-alive esté activo después de reconectar
      dbService.asegurarKeepAliveActivo();
      
      print('✅ Verificación y reconexión de BD completada');
    } catch (e) {
      print('❌ Error al verificar/reconectar BD: $e');
      // No lanzamos el error para no interrumpir la experiencia del usuario
      // La app intentará reconectar en la próxima operación de BD o en el próximo keep-alive
    }
  }

  void checkAuth() {
    setState(() {
      isAuthenticated = false; // Cambiar cuando haya auth real
      appState = isAuthenticated ? "app" : "login";
    });
  }

  void handleLogin() {
    setState(() {
      isAuthenticated = true;
      appState = "app";
      currentScreen = "home";
    });
  }

  void handleLogout() {
    setState(() {
      isAuthenticated = false;
      appState = "login";
      currentScreen = "home";
    });
  }

  void handleNavigate(String screen) {
    setState(() {
      currentScreen = screen;
    });
  }

  void showRegister() {
    setState(() {
      appState = "register";
    });
  }

  void showLogin() {
    setState(() {
      appState = "login";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tracktoger',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: const Locale('es', 'MX'), // Español latinoamericano
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'), // Español México
        Locale('es', 'ES'), // Español España
        Locale('en', 'US'), // Inglés (fallback)
      ],
      home: buildCurrentScreen(),
    );
  }

  Widget buildCurrentScreen() {
    switch (appState) {
      case "splash":
        return SplashScreen(onComplete: checkAuth);
      case "login":
        return LoginScreen(onLogin: handleLogin, onShowRegister: showRegister);
      case "register":
        return RegisterScreen(onRegister: handleLogin, onShowLogin: showLogin);
      case "app":
      default:
        return HomeScreen(
          currentTab: currentScreen,
          onNavigate: handleNavigate,
          onLogout: handleLogout,
        );
    }
  }
}
