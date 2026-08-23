import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viewer_settings.dart';
import '../providers/settings_provider.dart';

/// Modal dialog for manually adjusting top, bottom, left, right margin crop percentages
class MarginCropDialog extends ConsumerStatefulWidget {
  const MarginCropDialog({super.key});

  @override
  ConsumerState<MarginCropDialog> createState() => _MarginCropDialogState();
}

class _MarginCropDialogState extends ConsumerState<MarginCropDialog> {
  late double _top;
  late double _bottom;
  late double _left;
  late double _right;

  @override
  void initState() {
    super.initState();
    final currentCrop = ref.read(settingsProvider).marginCrop;
    _top = currentCrop.top;
    _bottom = currentCrop.bottom;
    _left = currentCrop.left;
    _right = currentCrop.right;
  }

  void _applyCrop() {
    ref.read(settingsProvider.notifier).updateMarginCrop(
      MarginCrop(
        top: _top,
        bottom: _bottom,
        left: _left,
        right: _right,
      ),
    );
  }

  void _reset() {
    setState(() {
      _top = 0.0;
      _bottom = 0.0;
      _left = 0.0;
      _right = 0.0;
    });
    _applyCrop();
  }

  Widget _buildSliderRow({
    required String label,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 0.35, // Up to 35% margin removal on each side
          divisions: 70,
          label: '${(value * 100).toStringAsFixed(1)}%',
          onChanged: (val) {
            setState(() => onChanged(val));
            _applyCrop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1E2E),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.crop, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text(
                      '여백 수동 제거 설정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '스캔본의 불필요한 고정 여백을 잘라내어 화면에 꽉 차게 표시합니다.',
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildSliderRow(
              label: '상단 여백 (Top)',
              icon: Icons.vertical_align_top,
              value: _top,
              onChanged: (v) => _top = v,
            ),
            _buildSliderRow(
              label: '하단 여백 (Bottom)',
              icon: Icons.vertical_align_bottom,
              value: _bottom,
              onChanged: (v) => _bottom = v,
            ),
            _buildSliderRow(
              label: '좌측 여백 (Left)',
              icon: Icons.format_align_left,
              value: _left,
              onChanged: (v) => _left = v,
            ),
            _buildSliderRow(
              label: '우측 여백 (Right)',
              icon: Icons.format_align_right,
              value: _right,
              onChanged: (v) => _right = v,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('초기화'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('완료'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
