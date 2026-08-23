import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viewer_settings.dart';
import '../providers/comic_session_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/settings_screen.dart';
import 'margin_crop_dialog.dart';

/// Top and bottom overlay bars displayed when user taps center zone
class ViewerControlsOverlay extends ConsumerWidget {
  const ViewerControlsOverlay({super.key});

  void _showPageJumpDialog(BuildContext context, WidgetRef ref, int current, int total) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('페이지 직접 이동', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: '1 ~ $total',
            hintStyle: const TextStyle(color: Colors.white38),
            suffixText: '/ $total',
            suffixStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: const Color(0xFF2E2E3E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              final target = int.tryParse(controller.text);
              if (target != null && target >= 1 && target <= total) {
                ref.read(comicSessionProvider.notifier).jumpToPage(target - 1);
                Navigator.pop(ctx);
              }
            },
            child: const Text('이동', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(comicSessionProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(comicSessionProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final title = session.book?.title ?? '';
    final current = session.displayCurrentPage;
    final total = session.totalPages;
    final isDual = settings.viewMode == ViewMode.dual;
    final isRTL = settings.readingDirection == ReadingDirection.rightToLeft;

    return Stack(
      children: [
        // ==================== TOP APP BAR ====================
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 8,
              left: 12,
              right: 12,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xEE12121E), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 1-page / 2-page View Mode Toggle
                IconButton(
                  tooltip: isDual ? '1장 보기로 전환' : '2장 보기로 전환',
                  icon: Icon(
                    isDual ? Icons.menu_book : Icons.auto_stories,
                    color: isDual ? Colors.blueAccent : Colors.white,
                  ),
                  onPressed: () => settingsNotifier.toggleViewMode(),
                ),
                // RTL / LTR Reading Direction Toggle
                IconButton(
                  tooltip: isRTL ? '일본식 (우->좌)' : '한국/서양식 (좌->우)',
                  icon: Icon(
                    isRTL ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r,
                    color: isRTL ? Colors.amberAccent : Colors.greenAccent,
                  ),
                  onPressed: () => settingsNotifier.toggleReadingDirection(),
                ),
                // Margin Crop Dialog
                IconButton(
                  tooltip: '여백 수동 제거',
                  icon: Icon(
                    Icons.crop,
                    color: settings.marginCrop.hasCrop ? Colors.cyanAccent : Colors.white,
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => const MarginCropDialog(),
                  ),
                ),
                // Viewer Settings
                IconButton(
                  tooltip: '뷰어 상세 설정',
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==================== BOTTOM CONTROLS & SEEK BAR ====================
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              top: 12,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xEE12121E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mode indicators
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDual ? '2장 보기' : '1장 보기',
                            style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isRTL ? Colors.amberAccent : Colors.greenAccent).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRTL ? '일본 만화 (우→좌)' : '한국 만화 (좌→우)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isRTL ? Colors.amberAccent : Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Clickable Page Number Indicator
                    InkWell(
                      onTap: () => _showPageJumpDialog(context, ref, current, total),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E3E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$current / $total',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 14, color: Colors.white60),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Slider Seekbar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: () => notifier.prevPage(),
                    ),
                    Expanded(
                      child: Slider(
                        value: current.toDouble().clamp(1.0, total > 0 ? total.toDouble() : 1.0),
                        min: 1.0,
                        max: total > 0 ? total.toDouble() : 1.0,
                        divisions: total > 1 ? total - 1 : 1,
                        activeColor: Colors.blueAccent,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          notifier.jumpToPage(val.toInt() - 1);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () => notifier.nextPage(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
