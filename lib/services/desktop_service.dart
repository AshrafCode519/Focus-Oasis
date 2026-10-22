import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class DesktopService with WindowListener {
  static final DesktopService _instance = DesktopService._internal();
  factory DesktopService() => _instance;
  DesktopService._internal();

  bool _isDesktop = false;
  bool _isMiniMode = false;
  VoidCallback? onTogglePlayPause;

  bool get isDesktop => _isDesktop;
  bool get isMiniMode => _isMiniMode;

  Future<void> init({
    VoidCallback? onPlayPause,
  }) async {
    onTogglePlayPause = onPlayPause;
    if (kIsWeb) return;
    _isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (!_isDesktop) return;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      const windowOptions = WindowOptions(
        size: Size(1100, 720),
        minimumSize: Size(320, 240),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'واحة التركيز • Focus Oasis',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('DesktopService init error: $e');
    }
  }

  // Switch to Always-on-Top Floating Mini Widget
  Future<void> switchToMiniMode() async {
    if (!_isDesktop) return;
    _isMiniMode = true;
    try {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(const Size(320, 360));
      await windowManager.setResizable(false);
    } catch (e) {
      debugPrint('Error switching to mini mode: $e');
    }
  }

  // Restore to standard Full-Size Workspace
  Future<void> switchToFullMode() async {
    if (!_isDesktop) return;
    _isMiniMode = false;
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setResizable(true);
      await windowManager.setSize(const Size(1100, 720));
      await windowManager.center();
    } catch (e) {
      debugPrint('Error switching to full mode: $e');
    }
  }

  // Minimize window
  Future<void> minimizeWindow() async {
    if (!_isDesktop) return;
    try {
      await windowManager.minimize();
    } catch (e) {
      debugPrint('Error minimizing window: $e');
    }
  }

  @override
  void onWindowClose() async {
    if (_isDesktop) {
      exit(0);
    }
  }

  void dispose() {
    windowManager.removeListener(this);
  }
}
