# 협업 체크리스트 앱

갤럭시용 협업 작업 관리 체크리스트 애플리케이션입니다.

## 주요 기능

### 1. 사용자 인증
- 회원가입 (이름, 전화번호, 생년월일, 비밀번호)
- 로그인 (JWT 토큰 기반)
- 관리자 계정 지원

### 2. 작업 관리
- 작업 등록 (작업명, 설명, 우선순위, 마감일, 작업자 선택)
- 작업 목록 보기 (전체/진행중/완료)
- 작업 상세 보기
- 작업 완료 처리
- 작업 수정/삭제

### 3. 협업 기능
- 다중 작업자 선택
- 작업자에게 전화하기
- 작업자 독촉하기
- 실시간 알림

### 4. 알림 기능
- 작업 할당 시 알림
- 작업 완료 시 알림
- 마감일 알림 (D-5, D-3, D-1)
- WorkManager를 통한 백그라운드 알림

## 기술 스택

### 백엔드 (Node.js)
- Express.js
- SQLite (better-sqlite3)
- JWT 인증
- bcryptjs (비밀번호 암호화)

### 안드로이드 앱
- Kotlin
- MVVM 아키텍처
- Retrofit (REST API 통신)
- Room (로컬 데이터베이스)
- WorkManager (백그라운드 작업)
- Material Design 3

## 설치 및 실행 방법

### 1. 백엔드 서버 실행

```bash
# 백엔드 디렉토리로 이동
cd backend

# 의존성 설치
npm install

# 서버 실행
npm start
```

서버는 `http://localhost:5000`에서 실행됩니다.

### 2. 안드로이드 앱 빌드

#### 필요 환경
- Android Studio Arctic Fox 이상
- JDK 17
- Android SDK (API 34)

#### 빌드 방법

1. Android Studio에서 `android-app` 폴더를 엽니다
2. Gradle 동기화를 실행합니다
3. 빌드 메뉴에서 `Build > Build Bundle(s) / APK(s) > Build APK(s)` 선택
4. 빌드 완료 후 APK 파일은 `app/build/outputs/apk/debug/` 에 생성됩니다

#### APK 설치
생성된 APK 파일을 갤럭시 폰으로 전송하여 설치합니다.

### 3. 네트워크 설정

#### PC와 안드로이드 기기가 같은 Wi-Fi에 연결되어 있어야 합니다.

1. PC의 IP 주소를 확인합니다
   - Windows: `ipconfig` 명령어
   - Mac/Linux: `ifconfig` 명령어

2. 안드로이드 앱의 서버 URL 수정
   - `RetrofitClient.kt` 파일에서 `BASE_URL`을 수정
   - 에뮬레이터: `http://10.0.2.2:5000/`
   - 실제 기기: `http://[PC의 IP주소]:5000/`

예시:
```kotlin
private const val BASE_URL = "http://192.168.0.10:5000/"
```

## API 엔드포인트

### 인증
- `POST /api/register` - 회원가입
- `POST /api/login` - 로그인

### 사용자
- `GET /api/users` - 사용자 목록 조회
- `GET /api/users/:id` - 특정 사용자 조회

### 작업
- `GET /api/tasks?status=all|in_progress|completed` - 작업 목록 조회
- `GET /api/tasks/:id` - 작업 상세 조회
- `POST /api/tasks` - 작업 생성
- `PUT /api/tasks/:id` - 작업 수정
- `PUT /api/tasks/:id/complete` - 작업 완료
- `DELETE /api/tasks/:id` - 작업 삭제

### 알림
- `GET /api/notifications` - 알림 목록 조회
- `PUT /api/notifications/:id/read` - 알림 읽음 처리
- `POST /api/tasks/:id/nudge` - 독촉 알림 전송

## 데이터베이스 스키마

### users 테이블
- id (INTEGER, PK)
- name (TEXT)
- phone (TEXT, UNIQUE)
- birthdate (TEXT)
- password (TEXT)
- is_admin (INTEGER)
- created_at (TEXT)

### tasks 테이블
- id (INTEGER, PK)
- title (TEXT)
- description (TEXT)
- priority (TEXT: high|medium|low)
- status (TEXT: in_progress|completed)
- creator_id (INTEGER, FK)
- completer_id (INTEGER, FK)
- created_date (TEXT)
- deadline_date (TEXT)
- completed_date (TEXT)

### task_workers 테이블
- id (INTEGER, PK)
- task_id (INTEGER, FK)
- worker_id (INTEGER, FK)

### notifications 테이블
- id (INTEGER, PK)
- user_id (INTEGER, FK)
- task_id (INTEGER, FK)
- type (TEXT)
- message (TEXT)
- is_read (INTEGER)
- created_at (TEXT)

## 관리자 계정 추가

관리자 계정은 데이터베이스에 직접 추가해야 합니다:

```javascript
// backend 디렉토리에서 Node.js로 실행
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const db = new Database('checklist.db');

const password = await bcrypt.hash('admin123', 10);
db.prepare(`
  INSERT INTO users (name, phone, birthdate, password, is_admin)
  VALUES ('관리자', '01012345678', '1990-01-01', ?, 1)
`).run(password);
```

## 사용 시나리오

### 1. 회원가입 및 로그인
1. 앱을 실행하고 "회원가입" 클릭
2. 이름, 전화번호, 생년월일, 비밀번호 입력
3. 가입 완료 후 로그인

### 2. 작업 등록
1. 메인 화면에서 '+' 버튼 클릭
2. 작업 정보 입력 (제목, 설명, 우선순위, 마감일)
3. 작업자 선택 (다중 선택 가능)
4. "작업 등록" 버튼 클릭

### 3. 작업 관리
1. 메인 화면에서 작업 목록 확인
2. 필터 선택 (전체/진행중/완료)
3. 작업 클릭하여 상세 화면 보기
4. 작업자 클릭하여 "전화하기" 또는 "독촉하기" 선택

### 4. 작업 완료
1. 작업 상세 화면에서 "완료 처리" 버튼 클릭
2. 완료 시 모든 작업자에게 알림 전송

## 트러블슈팅

### 서버 연결 안됨
- PC와 스마트폰이 같은 Wi-Fi에 연결되어 있는지 확인
- 방화벽에서 5000 포트를 허용했는지 확인
- 서버 URL이 올바른지 확인

### 알림이 오지 않음
- 앱 설정에서 알림 권한을 허용했는지 확인
- 배터리 최적화에서 앱을 제외했는지 확인

### APK 설치 안됨
- 설정 > 보안 > 출처를 알 수 없는 앱 허용

## 라이선스
MIT License

## 개발자
ProHobby Checklist Team
