# Railway.app 배포 가이드 (5분 완성)

## 🚀 1단계: Railway 회원가입 및 로그인

1. https://railway.app/ 접속
2. **Login** 클릭
3. **GitHub 계정으로 로그인** (추천) 또는 이메일로 가입

---

## 📦 2단계: 새 프로젝트 생성

### 옵션 A: GitHub 연동 (추천)

1. Railway 대시보드에서 **New Project** 클릭
2. **Deploy from GitHub repo** 선택
3. GitHub 연동 허용
4. 리포지토리 선택 (프로젝트를 GitHub에 먼저 업로드해야 함)

### 옵션 B: 직접 업로드 (더 빠름!) ⭐

1. Railway 대시보드에서 **New Project** 클릭
2. **Empty Project** 선택
3. **+ New** 클릭 → **GitHub Repo** 또는 **Empty Service** 선택
4. 프로젝트 이름: `checklist-backend`

---

## 🔧 3단계: 백엔드 폴더 배포

Railway CLI를 사용하거나 GitHub을 통해 배포합니다.

### 방법 1: Railway CLI 사용 (가장 쉬움)

1. **Railway CLI 설치**:
   ```powershell
   # PowerShell에서
   npm install -g @railway/cli
   ```

2. **로그인**:
   ```powershell
   railway login
   ```

3. **백엔드 폴더로 이동**:
   ```powershell
   cd c:\Users\parkm\prohobby_checklist\backend
   ```

4. **Railway 프로젝트 연결**:
   ```powershell
   railway link
   ```
   → 리스트에서 방금 만든 프로젝트 선택

5. **배포**:
   ```powershell
   railway up
   ```

6. **완료!** 🎉

---

### 방법 2: GitHub 사용

#### A. GitHub에 코드 업로드

1. GitHub에서 새 리포지토리 생성
2. 로컬에서 Git 초기화 및 푸시:
   ```powershell
   cd c:\Users\parkm\prohobby_checklist
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin [YOUR_GITHUB_REPO_URL]
   git push -u origin main
   ```

#### B. Railway에서 GitHub 리포지토리 연결

1. Railway 대시보드
2. **New Project** → **Deploy from GitHub repo**
3. 리포지토리 선택
4. **Root Directory**: `backend` 입력 (중요!)
5. **Deploy** 클릭

---

## 🌐 4단계: 환경 변수 설정

Railway 프로젝트 대시보드에서:

1. **Variables** 탭 클릭
2. 다음 변수 추가:
   ```
   PORT=5000
   JWT_SECRET=your_secret_key_change_this_in_production_12345
   NODE_ENV=production
   ```

---

## 📍 5단계: 배포 URL 확인

1. Railway 프로젝트 대시보드
2. **Settings** 탭 → **Domains** 섹션
3. **Generate Domain** 클릭
4. URL 복사 (예: `https://checklist-backend-production-xxxx.up.railway.app`)

---

## 📱 6단계: Android 앱 URL 변경

1. `RetrofitClient.kt` 파일 열기:
   ```
   android-app\app\src\main\java\com\prohobby\checklist\data\api\RetrofitClient.kt
   ```

2. BASE_URL 변경:
   ```kotlin
   private const val BASE_URL = "https://checklist-backend-production-xxxx.up.railway.app/"
   ```

3. 앱 재빌드:
   ```powershell
   cd c:\Users\parkm\prohobby_checklist\android-app
   .\gradlew.bat assembleDebug
   ```

---

## ✅ 7단계: 테스트

1. 브라우저에서 Railway URL 접속:
   ```
   https://your-app.up.railway.app/
   ```

2. API 응답 확인:
   ```json
   {
     "message": "협업 체크리스트 API 서버",
     "version": "1.0.0"
   }
   ```

3. Android 앱에서 회원가입/로그인 테스트

---

## 💡 Railway 무료 플랜

- **월 $5 크레딧** 제공
- **500시간 실행 시간**
- 소규모 프로젝트에 충분!

---

## 🔄 업데이트 방법

코드 수정 후:

### CLI 사용:
```powershell
cd backend
railway up
```

### GitHub 사용:
```powershell
git add .
git commit -m "Update"
git push
```
→ Railway가 자동으로 재배포

---

## 🎯 간단 요약

1. Railway.app 가입
2. CLI 설치: `npm install -g @railway/cli`
3. 로그인: `railway login`
4. 배포: `cd backend && railway up`
5. URL 복사 → Android 앱에 적용
6. 앱 재빌드 → 완료! 🎉

---

문제 발생 시 Railway 로그를 확인하세요:
```powershell
railway logs
```
