import 'dart:async';
import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';

class SystemDiagnosisScreen extends StatefulWidget {
  const SystemDiagnosisScreen({super.key});

  @override
  State<SystemDiagnosisScreen> createState() => _SystemDiagnosisScreenState();
}

class _SystemDiagnosisScreenState extends State<SystemDiagnosisScreen>
    with AutomaticKeepAliveClientMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  SystemInfo? _systemInfo;
  StreamSubscription? _sub;
  bool _isCelsius = true;
  bool _isLoadingMemory = false;
  bool _isLoadingDisk = false;

  DateTime _lastSystemUpdate = DateTime.now();
  static const _minUpdateInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _sub = _repository.systemInfoStream.listen((info) {
      final now = DateTime.now();
      if (now.difference(_lastSystemUpdate) < _minUpdateInterval) return;
      _lastSystemUpdate = now;
      if (mounted) setState(() => _systemInfo = info);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_systemInfo == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Diagnosis',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System Diagnosis allows you to easily check the usage of your storage devices.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Checker Column
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('System Checker'),
                    const SizedBox(height: 24),
                    _buildCheckerItem(
                      label: 'Disk',
                      percent: _systemInfo!.diskUsage,
                      onPressed: () async {
                        setState(() => _isLoadingDisk = true);
                        await _repository.cleanUpDisk();
                        setState(() => _isLoadingDisk = false);
                      },
                      buttonLabel: 'Clean Up Disk',
                      isLoading: _isLoadingDisk,
                    ),
                    const SizedBox(height: 32),
                    _buildCheckerItem(
                      label: 'Memory',
                      percent:
                          (_systemInfo!.ramUsage ?? 0) /
                          (_systemInfo!.ramTotal ?? 100),
                      onPressed: () async {
                        setState(() => _isLoadingMemory = true);
                        await _repository.freeUpMemory();
                        setState(() => _isLoadingMemory = false);
                      },
                      buttonLabel: 'Free Up Memory',
                      isLoading: _isLoadingMemory,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Storage Status Column
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Storage Status'),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStorageCard(theme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildCheckerItem({
    required String label,
    required double percent,
    required VoidCallback onPressed,
    required String buttonLabel,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  color: label == 'Memory' ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    '${(percent * 100).toInt()} %',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'NVMe SSD (System)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '/dev/nvme0n1p2',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Healthy (51%~100%)',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              // Circular Usage
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: _systemInfo!.diskUsage,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            color: Colors.blue,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_systemInfo!.diskUsage * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Used',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total: 512 GB',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.blue, 'Used', '281 GB'),
                        _buildLegendItem(Colors.grey, 'Free', '231 GB'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 80,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              // Circular Temp
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: _systemInfo!.ssdTemp / 100,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.1,
                              ),
                              color: Colors.pinkAccent,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_isCelsius ? _systemInfo!.ssdTemp.toInt() : (_systemInfo!.ssdTemp * 9 / 5 + 32).toInt()}°',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTempToggle(
                            'Celsius',
                            _isCelsius,
                            () => setState(() => _isCelsius = true),
                          ),
                          const SizedBox(height: 8),
                          _buildTempToggle(
                            'Fahrenheit',
                            !_isCelsius,
                            () => setState(() => _isCelsius = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Icon(Icons.square, size: 10, color: color),
        const SizedBox(width: 8),
        Text(
          '$label ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTempToggle(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Colors.redAccent : Colors.grey,
                width: 2,
              ),
            ),
            child: active
                ? const CircleAvatar(
                    radius: 4,
                    backgroundColor: Colors.redAccent,
                  )
                : const SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
