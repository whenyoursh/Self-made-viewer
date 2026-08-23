import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viewer_settings.dart';
import 'storage_provider.dart';

class SettingsNotifier extends StateNotifier<ViewerSettings> {
  final Ref _ref;

  SettingsNotifier(this._ref, ViewerSettings initialSettings) : super(initialSettings);

  void updateSettings(ViewerSettings newSettings) {
    state = newSettings;
    _ref.read(storageServiceProvider).saveSettings(newSettings);
  }

  void toggleViewMode() {
    final nextMode = state.viewMode == ViewMode.single ? ViewMode.dual : ViewMode.single;
    updateSettings(state.copyWith(viewMode: nextMode));
  }

  void toggleReadingDirection() {
    final nextDirection = state.readingDirection == ReadingDirection.leftToRight
        ? ReadingDirection.rightToLeft
        : ReadingDirection.leftToRight;
    updateSettings(state.copyWith(readingDirection: nextDirection));
  }

  void updateMarginCrop(MarginCrop crop) {
    updateSettings(state.copyWith(marginCrop: crop));
  }

  void updateTouchActions({TouchAction? leftAction, TouchAction? rightAction}) {
    updateSettings(state.copyWith(
      leftTouchAction: leftAction ?? state.leftTouchAction,
      rightTouchAction: rightAction ?? state.rightTouchAction,
    ));
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, ViewerSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final initial = storage.getSettings();
  return SettingsNotifier(ref, initial);
});
