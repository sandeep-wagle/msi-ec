import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/persistence_service.dart';
import 'screens/main_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'domain/repositories/msi_repository.dart';
import 'logic/blocs/sound/sound_bloc.dart';
import 'logic/blocs/settings/settings_bloc.dart';
import 'logic/blocs/settings/settings_state.dart';
import 'logic/blocs/sound/sound_state.dart';
import 'logic/blocs/audio/audio_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  await getIt<PersistenceService>().ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final initialSettings = SettingsState.fromPrefs(prefs);
  final initialSound = SoundState.fromPrefs(prefs);

  runApp(
    MsiControllerApp(
      initialSettings: initialSettings,
      initialSound: initialSound,
    ),
  );
}

class MsiControllerApp extends StatelessWidget {
  final SettingsState initialSettings;
  final SoundState initialSound;

  const MsiControllerApp({
    super.key,
    required this.initialSettings,
    required this.initialSound,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = getIt<ThemeProvider>();
    final repository = getIt<MsiRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              SoundBloc(repository, initialSound)..applyInitialSettings(),
        ),
        BlocProvider(
          create: (_) =>
              SettingsBloc(repository, initialSettings)..applyInitialSettings(),
        ),
        BlocProvider(create: (_) => getIt<AudioBloc>()),
      ],
      child: ListenableBuilder(
        listenable: themeProvider,
        builder: (context, _) {
          return MaterialApp(
            title: 'MSI Center',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorKey: navigatorKey,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
