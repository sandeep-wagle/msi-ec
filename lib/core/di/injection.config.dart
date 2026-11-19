// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'package:msi_controller/data/repositories/msi_repository_impl.dart'
    as _i416;
import 'package:msi_controller/domain/repositories/msi_repository.dart'
    as _i119;
import 'package:msi_controller/logic/blocs/audio/audio_bloc.dart' as _i17;
import 'package:msi_controller/services/persistence_service.dart' as _i207;
import 'package:msi_controller/services/toast_service.dart' as _i589;
import 'package:msi_controller/core/theme/theme_provider.dart' as _i416;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i207.PersistenceService>(
      () => _i207.PersistenceService(),
    );
    gh.lazySingleton<_i589.ToastService>(() => _i589.ToastService());
    gh.lazySingleton<_i119.MsiRepository>(() => _i416.MsiRepositoryImpl());
    gh.lazySingleton<_i416.ThemeProvider>(
      () => _i416.ThemeProvider(gh<_i207.PersistenceService>()),
    );
    gh.factory<_i17.AudioBloc>(() => _i17.AudioBloc(gh<_i119.MsiRepository>()));
    return this;
  }
}
