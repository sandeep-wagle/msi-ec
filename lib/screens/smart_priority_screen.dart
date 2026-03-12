import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../services/toast_service.dart';

enum SmartPriorityMode { userPriority, realtime, smartPriority }

class _AppEntry {
  final String name;
  final IconData icon;
  final Color color;
  bool inPriorityList = false;

  _AppEntry({required this.name, required this.icon, required this.color});
}

class SmartPriorityScreen extends StatefulWidget {
  const SmartPriorityScreen({super.key});

  @override
  State<SmartPriorityScreen> createState() => _SmartPriorityScreenState();
}

class _SmartPriorityScreenState extends State<SmartPriorityScreen> {
  SmartPriorityMode _mode = SmartPriorityMode.smartPriority;
  bool _mainSwitch = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<_AppEntry> _swList = [
    _AppEntry(
      name: 'Color Director 5',
      icon: Icons.color_lens,
      color: Colors.purple,
    ),
    _AppEntry(
      name: 'Audio Director 7',
      icon: Icons.music_note,
      color: Colors.blue,
    ),
    _AppEntry(
      name: 'Photo Director 10',
      icon: Icons.photo_camera,
      color: Colors.orange,
    ),
    _AppEntry(name: 'Power Director 17', icon: Icons.movie, color: Colors.red),
    _AppEntry(
      name: 'DaVinci Resolve',
      icon: Icons.video_settings,
      color: Colors.cyan,
    ),
    _AppEntry(name: 'Blender', icon: Icons.view_in_ar, color: Colors.amber),
    _AppEntry(
      name: 'Adobe Premiere Pro',
      icon: Icons.theaters,
      color: Colors.indigo,
    ),
    _AppEntry(name: 'Photoshop', icon: Icons.brush, color: Colors.teal),
  ];

  List<_AppEntry> get _filteredSwList => _swList
      .where(
        (a) =>
            !a.inPriorityList &&
            a.name.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  List<_AppEntry> get _priorityList =>
      _swList.where((a) => a.inPriorityList).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Smart Priority',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Creator Mode',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _mainSwitch,
                  activeThumbColor: Colors.red,
                  onChanged: (v) => setState(() => _mainSwitch = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mode',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Mode selector row
            Row(
              children: [
                _buildModeCard(
                  SmartPriorityMode.userPriority,
                  'User Priority',
                  Icons.person_outline,
                  isDark,
                ),
                const SizedBox(width: 24),
                _buildModeCard(
                  SmartPriorityMode.realtime,
                  'Real-time',
                  Icons.show_chart,
                  isDark,
                ),
                const SizedBox(width: 24),
                _buildModeCard(
                  SmartPriorityMode.smartPriority,
                  'Smart Priority',
                  Icons.auto_awesome,
                  isDark,
                  isAi: true,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 32),

            // Content depending on mode
            Expanded(
              child: _mainSwitch
                  ? _buildMainContent(theme, isDark)
                  : _buildDisabledContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    SmartPriorityMode mode,
    String label,
    IconData icon,
    bool isDark, {
    bool isAi = false,
  }) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.red.shade900.withValues(alpha: 0.2)
                    : Colors.red.shade50)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Colors.red.shade700
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? Colors.red.shade400
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
                if (isAi)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (v) => setState(() => _mode = mode),
                    activeColor: Colors.red,
                    shape: const CircleBorder(),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: AI description
        if (_mode == SmartPriorityMode.smartPriority) ...[
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 64,
                    color: Colors.red.shade300.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Automatically prioritize system resources to your most commonly used programs based on AI calculation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildResourceChip(Icons.memory, 'CPU', Colors.blue),
                      const SizedBox(width: 8),
                      _buildResourceChip(
                        Icons.videogame_asset,
                        'GPU',
                        Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      _buildResourceChip(Icons.storage, 'RAM', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],

        // Right: SW List + Priority List
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'SW List (${_filteredSwList.length + _priorityList.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add button
                  _buildIconBtn(Icons.add, Colors.grey, () {
                    _showAddAppDialog();
                  }),
                  const SizedBox(width: 8),
                  // Search
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App grid
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SW List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredSwList.length,
                              itemBuilder: (_, i) {
                                final app = _filteredSwList[i];
                                return _AppListTile(
                                  app: app,
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() => app.inPriorityList = true);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Divider
                    VerticalDivider(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(width: 16),
                    // Priority List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priority List',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_priorityList.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Drag apps here\nor click →',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ReorderableListView.builder(
                                itemCount: _priorityList.length,
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (newIndex > oldIndex) newIndex--;
                                    final apps = _priorityList;
                                    final item = apps.removeAt(oldIndex);
                                    apps.insert(newIndex, item);
                                  });
                                },
                                itemBuilder: (_, i) {
                                  final app = _priorityList[i];
                                  return _AppListTile(
                                    key: ValueKey(app.name),
                                    app: app,
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => app.inPriorityList = false,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Apply button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _applyPriority,
                  child: const Text('Apply Priority Settings'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledContent(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'Smart Priority is disabled',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Turn on the main switch to enable this feature.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _applyPriority() {
    // In a real implementation, this would use /proc or cgroups to set CPU affinity
    final message = _priorityList.isEmpty
        ? 'No apps in priority list'
        : 'Priority applied to ${_priorityList.map((a) => a.name).join(", ")}';
    if (_priorityList.isEmpty) {
      getIt<ToastService>().showWarning(message);
    } else {
      getIt<ToastService>().showSuccess(message);
    }
  }

  void _showAddAppDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Application'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Application name (e.g. MyApp)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _swList.add(
                    _AppEntry(
                      name: nameController.text.trim(),
                      icon: Icons.apps,
                      color: Colors.grey,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  final _AppEntry app;
  final Widget trailing;

  const _AppListTile({super.key, required this.app, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: app.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(app.icon, size: 16, color: app.color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(app.name, style: const TextStyle(fontSize: 12))),
          trailing,
        ],
      ),
    );
  }
}
