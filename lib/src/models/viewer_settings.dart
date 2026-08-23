import 'dart:convert';

/// Viewing modes: Single page or Dual page
enum ViewMode {
  single,
  dual,
}

/// Reading direction: LTR (Korean/Western) or RTL (Japanese Manga)
enum ReadingDirection {
  leftToRight, // 한국/서양 만화: 왼쪽 -> 오른쪽
  rightToLeft, // 일본 만화: 오른쪽 -> 왼쪽
}

/// Touch Action when tapping screen zones
enum TouchAction {
  nextPage,
  prevPage,
  toggleControls,
  none,
}

/// Margin cropping values (percentages from 0.0 to 0.40)
class MarginCrop {
  final double top;
  final double bottom;
  final double left;
  final double right;

  const MarginCrop({
    this.top = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
    this.right = 0.0,
  });

  bool get hasCrop => top > 0 || bottom > 0 || left > 0 || right > 0;

  MarginCrop copyWith({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return MarginCrop(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  Map<String, dynamic> toJson() => {
    'top': top,
    'bottom': bottom,
    'left': left,
    'right': right,
  };

  factory MarginCrop.fromJson(Map<String, dynamic> json) => MarginCrop(
    top: (json['top'] as num?)?.toDouble() ?? 0.0,
    bottom: (json['bottom'] as num?)?.toDouble() ?? 0.0,
    left: (json['left'] as num?)?.toDouble() ?? 0.0,
    right: (json['right'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Full Viewer Configuration Settings
class ViewerSettings {
  final ViewMode viewMode;
  final ReadingDirection readingDirection;
  final TouchAction leftTouchAction;
  final TouchAction rightTouchAction;
  final MarginCrop marginCrop;
  final bool keepScreenOn;
  final bool showPageNumber;

  const ViewerSettings({
    this.viewMode = ViewMode.single,
    this.readingDirection = ReadingDirection.rightToLeft, // 만화책 기본값 (RTL 일본식 권장 또는 LTR)
    this.leftTouchAction = TouchAction.prevPage,
    this.rightTouchAction = TouchAction.nextPage,
    this.marginCrop = const MarginCrop(),
    this.keepScreenOn = true,
    this.showPageNumber = true,
  });

  ViewerSettings copyWith({
    ViewMode? viewMode,
    ReadingDirection? readingDirection,
    TouchAction? leftTouchAction,
    TouchAction? rightTouchAction,
    MarginCrop? marginCrop,
    bool? keepScreenOn,
    bool? showPageNumber,
  }) {
    return ViewerSettings(
      viewMode: viewMode ?? this.viewMode,
      readingDirection: readingDirection ?? this.readingDirection,
      leftTouchAction: leftTouchAction ?? this.leftTouchAction,
      rightTouchAction: rightTouchAction ?? this.rightTouchAction,
      marginCrop: marginCrop ?? this.marginCrop,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      showPageNumber: showPageNumber ?? this.showPageNumber,
    );
  }

  Map<String, dynamic> toMap() => {
    'viewMode': viewMode.index,
    'readingDirection': readingDirection.index,
    'leftTouchAction': leftTouchAction.index,
    'rightTouchAction': rightTouchAction.index,
    'marginCrop': marginCrop.toJson(),
    'keepScreenOn': keepScreenOn,
    'showPageNumber': showPageNumber,
  };

  String toJson() => jsonEncode(toMap());

  factory ViewerSettings.fromMap(Map<String, dynamic> map) {
    return ViewerSettings(
      viewMode: ViewMode.values[map['viewMode'] ?? 0],
      readingDirection: ReadingDirection.values[map['readingDirection'] ?? 1],
      leftTouchAction: TouchAction.values[map['leftTouchAction'] ?? 1],
      rightTouchAction: TouchAction.values[map['rightTouchAction'] ?? 0],
      marginCrop: map['marginCrop'] != null
          ? MarginCrop.fromJson(Map<String, dynamic>.from(map['marginCrop']))
          : const MarginCrop(),
      keepScreenOn: map['keepScreenOn'] ?? true,
      showPageNumber: map['showPageNumber'] ?? true,
    );
  }

  factory ViewerSettings.fromJson(String source) =>
      ViewerSettings.fromMap(jsonDecode(source));
}
