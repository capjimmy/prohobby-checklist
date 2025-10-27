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
