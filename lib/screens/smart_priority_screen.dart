import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_mode_grid.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_main_console.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_disabled_state.dart';

class SmartPriorityScreen extends StatefulWidget {
  const SmartPriorityScreen({super.key});

  @override
  State<SmartPriorityScreen> createState() => _SmartPriorityScreenState();
}

class _SmartPriorityScreenState extends State<SmartPriorityScreen>
    with TickerProviderStateMixin {
  final PersistenceService _storage = getIt<PersistenceService>();
  SmartPriorityMode _mode = SmartPriorityMode.smartPriority;
  bool _mainSwitch = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<AppEntryData> _swList = [
    AppEntryData(
      name: 'Color Director 5',
      icon: Icons.color_lens,
      color: const Color(0xFFEB1D24),
    ),
    AppEntryData(
      name: 'Audio Director 7',
      icon: Icons.music_note,
      color: const Color(0xFF3B82F6),
    ),
    AppEntryData(
      name: 'Photo Director 10',
      icon: Icons.photo_camera,
      color: const Color(0xFF22C55E),
    ),
    AppEntryData(
      name: 'Power Director 17',
      icon: Icons.movie,
      color: const Color(0xFFEB1D24),
    ),
    AppEntryData(
      name: 'DaVinci Resolve',
      icon: Icons.video_settings,
      color: const Color(0xFF3B82F6),
    ),
    AppEntryData(
      name: 'Blender',
      icon: Icons.view_in_ar,
      color: const Color(0xFFF59E0B),
    ),
    AppEntryData(
      name: 'Adobe Premiere Pro',
      icon: Icons.theaters,
      color: const Color(0xFF3B82F6),
    ),
    AppEntryData(
      name: 'Photoshop',
      icon: Icons.brush,
      color: const Color(0xFF22C55E),
    ),
  ];

  List<AppEntryData> get _filteredSwList => _swList
      .where(
        (a) =>
            !a.inPriorityList &&
            a.name.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  List<AppEntryData> get _priorityList =>
      _swList.where((a) => a.inPriorityList).toList();

  @override
  void initState() {
    super.initState();
    final savedMode = _storage.loadSmartPriorityMode();
    _mode = SmartPriorityMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => SmartPriorityMode.smartPriority,
    );
    _mainSwitch = _storage.loadSmartPriorityEnabled();
    final savedNames = _storage.loadSmartPriorityList();
    for (final app in _swList) {
      if (savedNames.contains(app.name)) {
        app.inPriorityList = true;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _savePriorityState() {
    _storage.saveSmartPriority(
      mode: _mode.name,
      enabled: _mainSwitch,
      priorityAppNames: _swList
          .where((a) => a.inPriorityList)
          .map((a) => a.name)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Smart Priority',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxxl,
          AppSpacing.md,
          AppSpacing.xxxl,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.performance,
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Creator Intelligence',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _mainSwitch,
                  activeThumbColor: colors.performance,
                  onChanged: (v) {
                    setState(() => _mainSwitch = v);
                    _savePriorityState();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Intelligent resource allocation for professional creator software.',
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Mode Selector
            SmartPriorityModeGrid(
              currentMode: _mode,
              onModeSelected: (mode) {
                if (_mode == mode) return;
                setState(() => _mode = mode);
                _savePriorityState();
              },
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.xxxl),

            if (_mainSwitch)
              SmartPriorityMainConsole(
                mode: _mode,
                searchController: _searchController,
                filteredApps: _filteredSwList,
                priorityApps: _priorityList,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                onAddToPriority: (app) {
                  setState(() => app.inPriorityList = true);
                  _savePriorityState();
                },
                onRemoveFromPriority: (app) {
                  setState(() => app.inPriorityList = false);
                  _savePriorityState();
                },
                onReorderPriority: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _priorityList.removeAt(oldIndex);
                    _priorityList.insert(newIndex, item);
                  });
                  _savePriorityState();
                },
                onApply: () async {
                  final repo = getIt<MsiRepository>();
                  final apps = _swList
                      .where((a) => a.inPriorityList)
                      .map((a) => a.name)
                      .toList();
                  final success = await repo.setSmartPriority(apps);

                  if (success) {
                    getIt<ToastService>().showSuccess(
                      'HARDWARE RESOURCE ALLOCATION SYNCED',
                    );
                  } else {
                    getIt<ToastService>().showError('SYNC FAILED: VERIFY MSI DRIVER');
                  }
                },
                colors: colors,
              )
            else
              SmartPriorityDisabledState(colors: colors),
          ],
        ),
      ),
    );
  }
}
