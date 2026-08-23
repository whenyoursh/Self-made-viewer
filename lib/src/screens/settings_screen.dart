import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viewer_settings.dart';
import '../providers/settings_provider.dart';

/// Screen for configuring touch zones, reading direction, and viewing preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _touchActionLabel(TouchAction action) {
    switch (action) {
      case TouchAction.nextPage:
        return '다음 페이지로 이동';
      case TouchAction.prevPage:
        return '이전 페이지로 이동';
      case TouchAction.toggleControls:
        return '메뉴/컨트롤 표시 및 숨김';
      case TouchAction.none:
        return '동작 없음';
    }
  }

  void _showTouchActionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required TouchAction currentAction,
    required ValueChanged<TouchAction> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TouchAction.values.map((action) {
            final isSelected = action == currentAction;
            return RadioListTile<TouchAction>(
              value: action,
              groupValue: currentAction,
              title: Text(_touchActionLabel(action), style: const TextStyle(color: Colors.white)),
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                if (val != null) {
                  onSelected(val);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('뷰어 및 터치 설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Touch Zone Actions
          _buildSectionHeader('터치 영역 제스처 설정'),
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.arrow_left, color: Colors.blueAccent, size: 30),
                  title: const Text('화면 좌측(35%) 터치 시 동작', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _touchActionLabel(settings.leftTouchAction),
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    _showTouchActionDialog(
                      context: context,
                      ref: ref,
                      title: '좌측 영역 터치 동작 선택',
                      currentAction: settings.leftTouchAction,
                      onSelected: (action) => notifier.updateTouchActions(leftAction: action),
                    );
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.arrow_right, color: Colors.blueAccent, size: 30),
                  title: const Text('화면 우측(35%) 터치 시 동작', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _touchActionLabel(settings.rightTouchAction),
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    _showTouchActionDialog(
                      context: context,
                      ref: ref,
                      title: '우측 영역 터치 동작 선택',
                      currentAction: settings.rightTouchAction,
                      onSelected: (action) => notifier.updateTouchActions(rightAction: action),
                    );
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                const ListTile(
                  leading: Icon(Icons.touch_app, color: Colors.white38),
                  title: Text('화면 중앙(30%) 터치 시', style: TextStyle(color: Colors.white)),
                  subtitle: Text('상·하단 메뉴바 토글 (고정)', style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: View & Reading Direction
          _buildSectionHeader('보기 및 읽기 방향 설정'),
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_stories, color: Colors.amberAccent),
                  title: const Text('기본 보기 모드', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    settings.viewMode == ViewMode.single ? '1장 보기' : '2장 보기 (폴드 펼침/대화면 추천)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: DropdownButton<ViewMode>(
                    value: settings.viewMode,
                    dropdownColor: const Color(0xFF2E2E3E),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ViewMode.single, child: Text('1장 보기', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: ViewMode.dual, child: Text('2장 보기', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.updateSettings(settings.copyWith(viewMode: val));
                    },
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.greenAccent),
                  title: const Text('기본 읽기 순서 (방향)', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    settings.readingDirection == ReadingDirection.rightToLeft
                        ? '일본 만화식 (우 $\\rightarrow$ 좌, 역방향)'
                        : '한국/서양식 (좌 $\\rightarrow$ 우, 정방향)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: DropdownButton<ReadingDirection>(
                    value: settings.readingDirection,
                    dropdownColor: const Color(0xFF2E2E3E),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ReadingDirection.rightToLeft,
                        child: Text('우→좌 (일본)', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: ReadingDirection.leftToRight,
                        child: Text('좌→우 (한국)', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.updateSettings(settings.copyWith(readingDirection: val));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: General Settings
          _buildSectionHeader('화면 및 기타'),
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.pin, color: Colors.cyanAccent),
                  title: const Text('우측 하단 페이지 번호 상시 표시', style: TextStyle(color: Colors.white)),
                  value: settings.showPageNumber,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => notifier.updateSettings(settings.copyWith(showPageNumber: val)),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.stay_current_portrait, color: Colors.purpleAccent),
                  title: const Text('화면 켜짐 유지', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('만화 감상 중 화면이 꺼지지 않도록 방지', style: TextStyle(color: Colors.white38)),
                  value: settings.keepScreenOn,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => notifier.updateSettings(settings.copyWith(keepScreenOn: val)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }
}
