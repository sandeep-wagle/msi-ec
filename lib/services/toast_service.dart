import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:msi_controller/widgets/custom_toast.dart';
import 'package:msi_controller/main.dart';

@lazySingleton
class ToastService {
  final List<OverlayEntry> _activeToasts = [];
  final Queue<ToastItem> _toastQueue = Queue();
  bool _isProcessingQueue = false;

  static const int _maxConcurrentToasts = 3;

  void showSuccess(String message, {Duration? duration}) {
    _showToast(message, ToastType.success, duration: duration);
  }

  void showError(String message, {Duration? duration}) {
    _showToast(message, ToastType.error, duration: duration);
  }

  void showWarning(String message, {Duration? duration}) {
    _showToast(message, ToastType.warning, duration: duration);
  }

  void showInfo(String message, {Duration? duration}) {
    _showToast(message, ToastType.info, duration: duration);
  }

  Future<void> _showToast(
    String message,
    ToastType type, {
    Duration? duration,
  }) async {
    final toastItem = ToastItem(
      message: message,
      type: type,
      duration: duration ?? const Duration(seconds: 4),
    );

    _toastQueue.add(toastItem);
    _processQueue();
  }

  void _processQueue() {
    if (_isProcessingQueue || _toastQueue.isEmpty) return;
    if (_activeToasts.length >= _maxConcurrentToasts) return;

    _isProcessingQueue = true;

    final item = _toastQueue.removeFirst();
    final overlayEntry = _createOverlayEntry(item);

    final navigator = navigatorKey.currentState?.overlay;
    if (navigator != null) {
      navigator.insert(overlayEntry);
      _activeToasts.add(overlayEntry);
    }

    _isProcessingQueue = false;

    if (_toastQueue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 200), _processQueue);
    }
  }

  OverlayEntry _createOverlayEntry(ToastItem item) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 20 + (_activeToasts.length * 80.0),
        right: 20,
        left: MediaQuery.of(context).size.width > 600 ? null : 20,
        child: CustomToast(
          message: item.message,
          type: item.type,
          duration: item.duration,
          onDismiss: () {
            final entry = _activeToasts.firstWhere(
              (e) => e.builder == _createOverlayEntry(item).builder,
              orElse: () => OverlayEntry(builder: (_) => const SizedBox()),
            );
            if (_activeToasts.contains(entry)) {
              entry.remove();
              _activeToasts.remove(entry);
              _updateToastPositions();
            }
          },
        ),
      ),
    );
  }

  void _updateToastPositions() {
    for (int i = 0; i < _activeToasts.length; i++) {
      _activeToasts[i].remove();
      final newEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 20 + (i * 80.0),
          right: 20,
          left: MediaQuery.of(context).size.width > 600 ? null : 20,
          child: (_activeToasts[i].builder(context) as Positioned).child,
        ),
      );
      navigatorKey.currentState?.overlay?.insert(newEntry);
      _activeToasts[i] = newEntry;
    }
  }

  void dismissAll() {
    for (final entry in _activeToasts) {
      entry.remove();
    }
    _activeToasts.clear();
    _toastQueue.clear();
  }
}

class ToastItem {
  final String message;
  final ToastType type;
  final Duration duration;

  ToastItem({
    required this.message,
    required this.type,
    required this.duration,
  });
}
