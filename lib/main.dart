import 'package:flutter/material.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/main_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'domain/repositories/msi_repository.dart';
import 'logic/blocs/sound/sound_bloc.dart';
import 'logic/blocs/sound/sound_event.dart';
import 'logic/blocs/settings/settings_bloc.dart';
import 'logic/blocs/settings/settings_event.dart';
import 'logic/blocs/audio/audio_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MsiControllerApp());
}

class MsiControllerApp extends StatelessWidget {
  const MsiControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = getIt<ThemeProvider>();
    final repository = getIt<MsiRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SoundBloc(repository)..add(LoadSoundSettings()),
        ),
        BlocProvider(
          create: (_) => SettingsBloc(repository)..add(LoadSettings()),
        ),
        BlocProvider(
          create: (_) => getIt<AudioBloc>(),
        ),
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
