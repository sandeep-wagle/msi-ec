import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/core/widgets/app_button.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/screens/personal_space/widgets/tab_selector.dart';
import 'package:msi_controller/screens/personal_space/widgets/fab_action.dart';
enum VaultItemType { note, password, file }

class VaultItem {
  final String id;
  final VaultItemType type;
  final String title;
  final String description;
  final String? username;
  final String? secret; // Password or Path
  final DateTime timestamp;

  VaultItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.username,
    this.secret,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'title': title,
    'description': description,
    'username': username,
    'secret': secret,
    'timestamp': timestamp.toIso8601String(),
  };

  factory VaultItem.fromJson(Map<String, dynamic> json) => VaultItem(
    id: json['id'],
    type: VaultItemType.values[json['type']],
    title: json['title'],
    description: json['description'],
    username: json['username'],
    secret: json['secret'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class PersonalSpaceScreen extends StatefulWidget {
  const PersonalSpaceScreen({super.key});

  @override
  State<PersonalSpaceScreen> createState() => _PersonalSpaceScreenState();
}

class _PersonalSpaceScreenState extends State<PersonalSpaceScreen>
    with TickerProviderStateMixin {
  final PersistenceService _storage = getIt<PersistenceService>();
  final MsiRepository _repository = getIt<MsiRepository>();

  String _activeTab = 'All';
  final List<String> _tabs = ['All', 'Notes', 'Passwords', 'Files'];

  List<VaultItem> _items = [];
  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  final Set<String> _revealedPasswords = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final rawItems = _storage.loadVaultItems();
    setState(() {
      _items = rawItems.map((n) => VaultItem.fromJson(jsonDecode(n))).toList();
    });
  }

  void _saveItems() {
    final encoded = _items.map((n) => jsonEncode(n.toJson())).toList();
    _storage.saveVaultItems(encoded);
  }

  Future<void> _triggerAuth() async {
    setState(() => _isAuthenticating = true);
    HapticFeedback.vibrate();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _isUnlocked = true;
      });
      getIt<ToastService>().showSuccess('VAULT_AUTHENTICATED');
    }
  }

  void _showAddItemDialog(VaultItemType type) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final userController = TextEditingController();
    final secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return AlertDialog(
          backgroundColor: const Color(0xFF050510),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(
              color: colors.superBattery.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          title: Text(
            'ALLOCATE_${type.name.toUpperCase()}_NODE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2.0,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'NODE_LABEL'),
                const SizedBox(height: 12),
                if (type == VaultItemType.password) ...[
                  _buildTextField(userController, 'USERNAME'),
                  const SizedBox(height: 12),
                  _buildTextField(secretController, 'PASSWORD', isSecret: true),
                  const SizedBox(height: 12),
                ],
                if (type == VaultItemType.file) ...[
                  _buildTextField(secretController, 'ABSOLUTE_FILE_PATH'),
                  const SizedBox(height: 12),
                ],
                _buildTextField(
                  descController,
                  type == VaultItemType.note
                      ? 'CONTENT'
                      : 'METADATA_DESCRIPTION',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            AppButton(
              text: 'ABORT',
              onPressed: () => Navigator.pop(context),
              isElevated: false,
              isPrimary: false,
              foregroundColor: Colors.white24,
            ),
            AppButton(
              text: 'INITIALIZE',
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _items.insert(
                      0,
                      VaultItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        type: type,
                        title: titleController.text.toUpperCase(),
                        description: descController.text,
                        username: userController.text,
                        secret: secretController.text,
                        timestamp: DateTime.now(),
                      ),
                    );
                  });
                  _saveItems();
                  Navigator.pop(context);
                }
              },
              backgroundColor: colors.superBattery,
              foregroundColor: Colors.black,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isSecret = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: isSecret,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'PERSONAL_VAULT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          if (_isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_reset_rounded, color: Colors.white24),
              onPressed: () => setState(() => _isUnlocked = false),
            ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              TabSelector(
                tabs: _tabs,
                activeTab: _activeTab,
                colors: colors,
                onTabChanged: (tab) => setState(() => _activeTab = tab),
              ),
              Expanded(
                child: _isUnlocked
                    ? _buildVaultGrid(colors)
                    : _buildAuthWall(colors),
              ),
            ],
          ),
          if (_isUnlocked) _buildFloatingActionMenu(colors),
        ],
      ),
    );
  }

  Widget _buildAuthWall(AppColors colors) {
    return Center(
      child: GlassCard(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulseIcon(
              icon: _isAuthenticating
                  ? Icons.sync_rounded
                  : Icons.fingerprint_rounded,
              color: _isAuthenticating
                  ? colors.performance
                  : colors.superBattery,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              _isAuthenticating ? 'VERIFYING_IDENT...' : 'SECURE_VAULT_LOCKED',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'BIOMETRIC_HANDSHAKE_REQUIRED',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: _TactileButton(
                onPressed: _isAuthenticating ? null : _triggerAuth,
                color: colors.superBattery,
                child: _isAuthenticating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                    : const Text(
                        'ACCESS_VAULT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 2.0,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultGrid(AppColors colors) {
    final filteredItems = _activeTab == 'All'
        ? _items
        : _items
              .where(
                (i) =>
                    i.type.name.toLowerCase() ==
                    _activeTab
                        .toLowerCase()
                        .substring(0, _activeTab.length - 1)
                        .replaceAll('ie', 'y'),
              )
              .toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            const Text(
              'VAULT_EMPTY',
              style: TextStyle(
                color: Colors.white10,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.xl,
        mainAxisSpacing: AppSpacing.xl,
        childAspectRatio: 1.4,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, i) {
        final item = filteredItems[i];
        return _buildVaultCard(item, colors);
      },
    );
  }

  Widget _buildVaultCard(VaultItem item, AppColors colors) {
    final isPassword = item.type == VaultItemType.password;
    final isFile = item.type == VaultItemType.file;
    final isRevealed = _revealedPasswords.contains(item.id);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPassword
                    ? Icons.key_rounded
                    : (isFile
                          ? Icons.description_rounded
                          : Icons.notes_rounded),
                size: 14,
                color: colors.superBattery,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white10,
                ),
                onPressed: () {
                  setState(() => _items.removeWhere((it) => it.id == item.id));
                  _saveItems();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPassword) ...[
            Text(
              item.username ?? 'USER_NULL',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white24,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRevealed ? (item.secret ?? '****') : '••••••••',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: isRevealed ? Colors.greenAccent : Colors.white24,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isRevealed) {
                        _revealedPasswords.remove(item.id);
                      } else {
                        _revealedPasswords.add(item.id);
                      }
                    });
                  },
                  child: Icon(
                    isRevealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 14,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          ],
          if (isFile) ...[
            Text(
              item.secret?.split('/').last ?? 'FILE_NULL',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _TactileButton(
              onPressed: () => _repository.openFile(item.secret ?? ''),
              color: Colors.white.withValues(alpha: 0.05),
              borderColor: Colors.white.withValues(alpha: 0.1),
              child: const Center(
                child: Text(
                  'EXECUTE_OPEN',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
          if (item.type == VaultItemType.note) ...[
            Expanded(
              child: Text(
                item.description,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (!isFile) const Spacer(),
          Text(
            'LOG: ${item.timestamp.day}/${item.timestamp.month} ${item.timestamp.hour}:${item.timestamp.minute}',
            style: const TextStyle(
              fontSize: 7,
              color: Colors.white10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionMenu(AppColors colors) {
    return Positioned(
      bottom: AppSpacing.xxxl,
      right: AppSpacing.xxxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FabAction(
            icon: Icons.key_rounded,
            label: 'PASS',
            onTap: () => _showAddItemDialog(VaultItemType.password),
            colors: colors,
          ),
          const SizedBox(height: 12),
          FabAction(
            icon: Icons.file_present_rounded,
            label: 'FILE',
            onTap: () => _showAddItemDialog(VaultItemType.file),
            colors: colors,
          ),
          const SizedBox(height: 12),
          FabAction(
            icon: Icons.note_add_rounded,
            label: 'NOTE',
            onTap: () => _showAddItemDialog(VaultItemType.note),
            colors: colors,
            primary: true,
          ),
        ],
      ),
    );
  }

}

class _TactileButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? borderColor;

  const _TactileButton({
    this.onPressed,
    required this.child,
    required this.color,
    this.borderColor,
  });

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isPressed = true),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.color.withValues(alpha: 0.8)
                : widget.color,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: widget.borderColor ?? Colors.transparent),
            boxShadow: [
              if (_isPressed)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 15,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulseIcon({required this.icon, required this.color});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
            width: 80 + (_controller.value * 80),
            height: 80 + (_controller.value * 80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(
                  alpha: (1.0 - _controller.value) * 0.4,
                ),
                width: 2,
              ),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(widget.icon, color: widget.color, size: 40),
        ),
      ],
    );
  }
}
