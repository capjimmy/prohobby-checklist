# 🔔 푸시 알림 기능 구현 가이드

독촉하기 버튼을 누르면 담당자에게 실시간으로 알림이 가도록 설정하는 방법입니다.

## 📋 구현 개요

1. **Flutter 앱**: FCM 토큰 받기 & 알림 수신
2. **Firestore**: 사용자 FCM 토큰 저장
3. **Cloud Functions**: 독촉 시 알림 전송

---

## 1️⃣ Flutter 앱 설정

### 패키지 설치
이미 `pubspec.yaml`에 추가했습니다:
```yaml
firebase_messaging: ^15.1.3
flutter_local_notifications: ^18.0.1
```

```bash
flutter pub get
```

### Android 설정 (android/app/src/main/AndroidManifest.xml)

`<application>` 태그 안에 추가:
```xml
<!-- FCM -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />

<!-- 알림 아이콘 -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_launcher" />
```

### iOS 설정 (Runner/AppDelegate.swift)

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // 알림 권한 요청
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

---

## 2️⃣ Flutter 알림 서비스 생성

`lib/services/notification_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 백그라운드 메시지 핸들러 (top-level 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // 알림 권한 요청
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 알림 권한 승인됨');
    }

    // 로컬 알림 초기화 (Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 로컬 알림 초기화 (iOS)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Android 알림 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: '중요한 알림을 위한 채널',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드 메시지 수신: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 알림 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('알림 클릭: ${message.notification?.title}');
      // TODO: 특정 화면으로 이동
    });
  }

  // FCM 토큰 가져오기 및 저장
  Future<void> saveFcmToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcm_token': token,
          'fcm_token_updated_at': FieldValue.serverTimestamp(),
        });
        print('✅ FCM 토큰 저장: $token');
      }
    } catch (e) {
      print('❌ FCM 토큰 저장 실패: $e');
    }

    // 토큰 갱신 리스너
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(userId).update({
        'fcm_token': newToken,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: '중요한 알림을 위한 채널',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
```

---

## 3️⃣ main.dart에서 알림 초기화

```dart
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}
```

---

## 4️⃣ AuthProvider에서 FCM 토큰 저장

로그인 성공 시 FCM 토큰 저장:

```dart
// login 함수 안에 추가
if (success) {
  final notificationService = NotificationService();
  await notificationService.saveFcmToken(_user!.id!);
}
```

---

## 5️⃣ Cloud Functions 설정

Firebase Console에서 Cloud Functions 활성화 후, 프로젝트 루트에 `functions` 폴더 생성:

```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

`functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// 독촉 시 알림 전송
exports.sendNudgeNotification = functions.firestore
  .document('nudges/{nudgeId}')
  .onCreate(async (snap, context) => {
    const nudge = snap.data();

    // 담당자의 FCM 토큰 가져오기
    const workerDoc = await admin.firestore()
      .collection('users')
      .doc(nudge.to_user_id)
      .get();

    if (!workerDoc.exists) {
      console.log('사용자를 찾을 수 없습니다');
      return;
    }

    const fcmToken = workerDoc.data().fcm_token;

    if (!fcmToken) {
      console.log('FCM 토큰이 없습니다');
      return;
    }

    // 알림 메시지 구성
    const message = {
      notification: {
        title: '🔔 독촉 알림!',
        body: `${nudge.from_user_name}님이 작업 완료를 독촉하고 있습니다!`,
      },
      data: {
        task_id: nudge.task_id,
        from_user_id: nudge.from_user_id,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // 알림 전송
    try {
      await admin.messaging().send(message);
      console.log('✅ 알림 전송 성공:', nudge.to_user_name);
    } catch (error) {
      console.error('❌ 알림 전송 실패:', error);
    }
  });
```

Cloud Functions 배포:
```bash
cd functions
firebase deploy --only functions
```

---

## 6️⃣ 테스트

1. 앱 실행 후 로그인
2. FCM 토큰이 Firestore `users` 컬렉션에 저장되는지 확인
3. 독촉하기 버튼 클릭
4. `nudges` 컬렉션에 기록 생성 → Cloud Function 트리거 → 알림 전송!

---

## 🎯 결과

- **독촉하기!** 버튼 클릭 시
- 담당자 휴대폰에 **진동 + 알림음**과 함께
- **"🔔 독촉 알림! OOO님이 작업 완료를 독촉하고 있습니다!"** 메시지 표시

---

## 📝 주의사항

1. **iOS**: Apple Developer 계정 필요 (APNs 인증서)
2. **Android**: google-services.json 파일 필요 (이미 있음)
3. **Cloud Functions**: Firebase Blaze 플랜 필요 (소규모는 무료)
4. **테스트**: 실제 기기에서만 가능 (시뮬레이터는 제한적)

---

## 💰 비용

- **Firestore**: 무료 티어 충분
- **Cloud Functions**: 무료 티어 월 200만 호출 (충분함)
- **FCM**: 완전 무료!

총 비용: **$0** (소규모 사용 시)
