import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/repositories/specialist_repository_impl.dart';
import 'data/services/settings_service.dart';
import 'presentation/providers/specialist_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/app_settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/providers/app_localizations.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/discovery_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize repository
  final repository = SpecialistRepositoryImpl();
  await repository.initialize();

  // Initialize settings service
  final settingsService = SettingsService();
  final isFirstLaunch = await settingsService.isFirstLaunch();

  runApp(MyApp(
    repository: repository,
    settingsService: settingsService,
    isFirstLaunch: isFirstLaunch,
  ));
}

class MyApp extends StatelessWidget {
  final SpecialistRepositoryImpl repository;
  final SettingsService settingsService;
  final bool isFirstLaunch;

  const MyApp({
    super.key,
    required this.repository,
    required this.settingsService,
    required this.isFirstLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final lightTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    final darkTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SpecialistProvider(
            repository: repository,
            settingsService: settingsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider(settingsService),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, appSettings, _) {
          return MaterialApp(
            title: 'SkillsMatch',
            debugShowCheckedModeBanner: false,
            locale: appSettings.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ru', ''),
              Locale('uz', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: appSettings.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(appSettings.fontSizeMultiplier),
                ),
                child: child!,
              );
            },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            primary: const Color(0xFFE53935),
            secondary: const Color(0xFF1E293B),
            tertiary: const Color(0xFFFF6B6B),
            surface: Colors.white,
            surfaceTint: Colors.transparent,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F2F5),
          useMaterial3: true,
          textTheme: lightTextTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF1A1D1E),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Color(0xFF1A1D1E)),
            titleTextStyle: GoogleFonts.inter(
              color: const Color(0xFF1A1D1E),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.zero,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFE53935).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
            ),
            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFFE53935),
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: const Color(0xFFE53935),
            inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: const Color(0xFFE53935),
            overlayColor: const Color(0xFFE53935).withValues(alpha: 0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFF1F5F9),
            thickness: 1,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          textTheme: darkTextTheme,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            brightness: Brightness.dark,
            primary: const Color(0xFFE53935),
            secondary: const Color(0xFF94A3B8),
            tertiary: const Color(0xFFFF6B6B),
            surface: const Color(0xFF1E293B),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardTheme: CardThemeData(
            elevation: 0,
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.zero,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF334155),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
            ),
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
            labelStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFF334155),
            thickness: 1,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
        home: _buildHome(),
      );
    }),
    );
  }

  Widget _buildHome() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show onboarding on first launch
        if (isFirstLaunch) {
          return const OnboardingScreen();
        }
        
        // Show loading while checking auth
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Show login if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }
        
        // Show discovery if authenticated
        return const DiscoveryScreen();
      },
    );
  }
}
