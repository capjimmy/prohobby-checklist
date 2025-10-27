# 협업 체크리스트 - Flutter 앱

Android/iOS 크로스 플랫폼 협업 체크리스트 앱입니다.

## 주요 기능

- ✅ 사용자 인증 (로그인/회원가입)
- ✅ 작업 생성 및 관리
- ✅ 작업자 할당
- ✅ 우선순위 설정 (높음/중간/낮음)
- ✅ 마감일 설정
- ✅ 작업 완료 처리
- ✅ 진행 중/완료된 작업 분류

## 기술 스택

- **Flutter**: UI 프레임워크
- **Dart**: 프로그래밍 언어
- **Provider**: 상태 관리
- **Dio**: HTTP 클라이언트
- **SharedPreferences**: 로컬 저장소

## 백엔드 서버

- Node.js + Express
- Railway에 배포: `https://prohobbychecklist-production.up.railway.app`

## 설치 및 실행

### 필요 조건
- Flutter SDK 3.8.1 이상
- Android Studio (Android) 또는 Xcode (iOS)

### 1. 의존성 설치
```bash
cd flutter_checklist_app
flutter pub get
```

### 2. 코드 생성 (JSON 직렬화)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 앱 실행
```bash
# Android 에뮬레이터 또는 실제 기기에서 실행
flutter run

# iOS 시뮬레이터 또는 실제 기기에서 실행 (macOS만 가능)
flutter run -d ios
```

### 4. 릴리스 빌드
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play Store용)
flutter build appbundle --release

# iOS (macOS만 가능)
flutter build ios --release
```

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점
├── models/                # 데이터 모델
│   ├── user.dart
│   └── task.dart
├── services/              # 서비스 레이어
│   ├── api_service.dart   # API 통신
│   └── storage_service.dart # 로컬 저장소
├── providers/             # 상태 관리
│   ├── auth_provider.dart
│   └── task_provider.dart
└── screens/               # UI 화면
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart
    └── create_task_screen.dart
```

## API 엔드포인트

### 인증
- `POST /api/register` - 회원가입
- `POST /api/login` - 로그인

### 작업
- `GET /api/tasks` - 작업 목록 조회
- `POST /api/tasks` - 작업 생성
- `PUT /api/tasks/:id` - 작업 수정
- `PUT /api/tasks/:id/complete` - 작업 완료
- `DELETE /api/tasks/:id` - 작업 삭제

### 사용자
- `GET /api/users` - 사용자 목록 조회

## 기존 Android 앱과의 차이점

### 장점
1. **크로스 플랫폼**: Android와 iOS 모두 지원
2. **빠른 개발**: Hot Reload로 즉시 변경사항 확인
3. **Gradle 문제 없음**: Java/Kotlin의 복잡한 빌드 시스템 불필요
4. **간결한 코드**: Dart의 간결한 문법
5. **풍부한 위젯**: Material Design과 Cupertino 위젯 기본 제공

### 개발 경험
- ✅ Gradle 캐시 문제 없음
- ✅ jlink.exe 에러 없음
- ✅ 빌드 시간 단축
- ✅ 더 나은 디버깅 경험

## 라이선스

MIT

## 개발자

Pro Hobby Team
