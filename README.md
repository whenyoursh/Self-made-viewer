# FoldComic - 갤럭시 Z 폴드 최적화 만화책 뷰어

갤럭시 Z 폴드(커버 화면 및 메인 펼친 대화면) 환경에 완벽하게 대응하는 Flutter 기반 고성능 만화 뷰어 애플리케이션입니다.

---

## ✨ 주요 기능

1. **1장 보기 & 2장 보기 지원**:
   - 커버 화면에서는 1장 보기로 편안하게 감상
   - 메인 대화면을 펼쳤을 때는 2장 보기 모드로 실제 출판 만화책을 펼쳐보듯 감상 가능
2. **읽기 순서 (방향) 설정**:
   - **일본 만화식 (우 $\rightarrow$ 좌)**: 오른쪽 페이지가 앞 장, 왼쪽 페이지가 다음 장
   - **한국/서양식 (좌 $\rightarrow$ 우)**: 왼쪽 페이지가 앞 장, 오른쪽 페이지가 다음 장
3. **고정 여백 수동 제거 (Manual Margin Cropping)**:
   - 스캔본 원본의 상/하/좌/우 고정 여백을 슬라이더(0% ~ 35%)로 실시간 조절하여 잘라내고 화면에 꽉 차게 확대
4. **터치 영역별 넘김 방식 커스텀**:
   - 화면을 좌측(35%), 중앙(30%), 우측(35%) 3개 영역으로 구분
   - 좌측 탭 및 우측 탭 시 수행할 동작(다음 페이지 / 이전 페이지 / 메뉴 표시 / 없음)을 자유롭게 지정
   - 중앙 탭 시 상·하단 툴바 메뉴 표시/숨김
5. **페이지 탐색 및 이어보기**:
   - 현재 페이지 / 전체 페이지 수 표시
   - 하단 슬라이더 바 및 직접 페이지 번호 입력 이동 지원
   - 최근 열람한 위치 자동 저장 및 앱 재실행 시 이어보기
6. **홈 화면 최근 기록 관리**:
   - **상단**: 최근 열람한 만화 파일 5개 (표지 썸네일, 읽은 진행률, 파일명)
   - **하단**: 최근 접근했던 내장 폴더 목록 (탭하여 바로 폴더 탐색기로 이동)
7. **포맷 지원**:
   - 압축 파일: `.zip`, `.cbz` (인메모리 스트리밍 및 LRU 캐싱)
   - 이미지 폴더: `.jpg`, `.jpeg`, `.png`, `.webp` 등이 담긴 로컬 디렉토리 직접 열람
8. **갤럭시 폴드 및 화면 회전 대응**:
   - 기기 시스템 자동 회전 설정(세로/가로)에 자연스럽게 반응
   - 핀치 투 줌(Pinch-to-zoom, 최대 4배) 및 팬 제스처 지원

---

## 🚀 실행 및 빌드 방법

### 1. 의존성 설치
```bash
flutter pub get
```

### 2. 앱 실행 (디버그 모드)
```bash
flutter run
```

### 3. 안드로이드 APK 빌드 (갤럭시 기기 설치용)
```bash
flutter build apk --release
```
빌드된 APK 파일은 `build/app/outputs/flutter-apk/app-release.apk` 경로에 생성됩니다.

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                               # 앱 진입점 및 테마, ProviderScope 설정
└── src/
    ├── models/                             # 데이터 모델
    │   ├── comic_book.dart                 # 만화책/페이지 엔티티
    │   ├── history_record.dart             # 최근 5개 파일 및 최근 폴더 기록
    │   └── viewer_settings.dart            # 보기 모드, 읽기 방향, 터치 매핑, 여백 크롭
    ├── services/                           # 서비스 레이어
    │   ├── archive_service.dart            # ZIP/CBZ 파싱 및 인메모리 LRU 캐싱
    │   ├── file_service.dart               # 권한, 파일/폴더 피커, 디렉토리 탐색
    │   └── storage_service.dart            # SharedPreferences 로컬 저장소
    ├── providers/                          # Riverpod 상태 관리
    │   ├── comic_session_provider.dart     # 뷰어 세션, 페이지 이동 제어
    │   ├── history_provider.dart           # 최근 기록 상태 관리
    │   ├── settings_provider.dart          # 뷰어 설정 상태 관리
    │   └── storage_provider.dart           # 서비스 DI
    ├── screens/                            # 화면
    │   ├── home_screen.dart                # 최근 5개 파일 + 최근 폴더 목록
    │   ├── folder_browser_screen.dart      # 내장 폴더 브라우저
    │   ├── viewer_screen.dart              # 핵심 만화 뷰어 화면
    │   └── settings_screen.dart            # 터치 영역 및 뷰어 환경설정
    ├── widgets/                            # 재사용 컴포넌트
    │   ├── cropped_image_widget.dart       # 여백 크롭 Canvas 렌더러
    │   ├── margin_crop_dialog.dart         # 상하좌우 여백 조절 모달
    │   ├── page_view_widget.dart           # 1장/2장 및 LTR/RTL 뷰어 위젯
    │   ├── touch_zone_overlay.dart         # 좌/중앙/우 터치 감지 오버레이
    │   └── viewer_controls_overlay.dart    # 상·하단 툴바 및 탐색 바
    └── utils/
        └── natural_sort.dart               # 자연수 정렬 유틸 (1, 2, 10...)
```
