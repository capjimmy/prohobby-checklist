# 빠른 시작 가이드

## 1. 백엔드 서버 실행 (필수)

```bash
# 1. backend 폴더로 이동
cd backend

# 2. 의존성 설치
npm install

# 3. 서버 실행
npm start
```

서버가 `http://localhost:5000`에서 실행됩니다.

## 2. Android 앱 빌드 및 설치

### 방법 1: Android Studio 사용 (권장)

1. Android Studio를 실행합니다
2. "Open" 클릭 → `android-app` 폴더 선택
3. Gradle 동기화 대기
4. 상단 메뉴: `Build > Build Bundle(s) / APK(s) > Build APK(s)`
5. 빌드 완료 후 `app/build/outputs/apk/debug/app-debug.apk` 생성됨
6. APK를 갤럭시 폰으로 전송하여 설치

### 방법 2: 명령줄 사용

```bash
# android-app 폴더로 이동
cd android-app

# Windows
gradlew.bat assembleDebug

# Mac/Linux
./gradlew assembleDebug
```

## 3. 네트워크 설정

### 에뮬레이터 사용 시
- 기본 설정 그대로 사용 (http://10.0.2.2:5000)

### 실제 갤럭시 폰 사용 시

1. **PC와 폰을 같은 Wi-Fi에 연결**

2. **PC의 IP 주소 확인**
   ```bash
   # Windows
   ipconfig

   # Mac/Linux
   ifconfig
   ```
   예: `192.168.0.10`

3. **앱의 서버 URL 수정**
   - 파일: `android-app/app/src/main/java/com/prohobby/checklist/data/api/RetrofitClient.kt`
   - 수정:
   ```kotlin
   private const val BASE_URL = "http://192.168.0.10:5000/"
   ```

4. **방화벽 설정 (Windows)**
   - Windows Defender 방화벽 → 고급 설정
   - 인바운드 규칙 → 새 규칙
   - 포트 5000 허용

## 4. 첫 사용자 등록

1. 앱 실행
2. "회원가입" 클릭
3. 정보 입력:
   - 이름: 홍길동
   - 전화번호: 01012345678
   - 생년월일: 1990-01-01
   - 비밀번호: 1234
4. 가입 후 로그인

## 5. 작업 등록 테스트

1. 메인 화면에서 '+' 버튼 클릭
2. 작업 정보 입력
3. 작업자 선택 (여러 명 선택 가능)
4. "작업 등록" 클릭

## 문제 해결

### "서버에 연결할 수 없습니다"
- 백엔드 서버가 실행 중인지 확인
- PC와 폰이 같은 Wi-Fi에 연결되어 있는지 확인
- 방화벽 설정 확인

### APK 설치 시 "보안상의 이유로 차단됨"
- 설정 → 보안 → 출처를 알 수 없는 앱 설치 허용

### 알림이 오지 않음
- 설정 → 앱 → 협업 체크리스트 → 알림 허용
- 배터리 최적화에서 앱 제외

## 기능 테스트 체크리스트

- [ ] 회원가입
- [ ] 로그인
- [ ] 작업 등록
- [ ] 작업 목록 보기
- [ ] 작업 필터링 (전체/진행중/완료)
- [ ] 작업 상세 보기
- [ ] 작업 완료 처리
- [ ] 작업자에게 전화하기
- [ ] 독촉 알림 보내기
- [ ] 로그아웃

## 추가 정보

- 자세한 API 문서는 `README.md` 참조
- 관리자 계정 추가 방법은 `README.md` 참조
