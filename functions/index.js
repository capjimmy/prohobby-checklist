const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// 독촉 시 알림 전송
exports.sendNudgeNotification = functions.firestore
  .document('nudges/{nudgeId}')
  .onCreate(async (snap, context) => {
    const nudge = snap.data();

    console.log('독촉 알림 트리거:', nudge);

    try {
      // 담당자의 FCM 토큰 가져오기
      const workerDoc = await admin.firestore()
        .collection('users')
        .doc(nudge.to_user_id)
        .get();

      if (!workerDoc.exists) {
        console.log('사용자를 찾을 수 없습니다:', nudge.to_user_id);
        return null;
      }

      const workerData = workerDoc.data();
      const fcmToken = workerData.fcm_token;

      if (!fcmToken) {
        console.log('FCM 토큰이 없습니다:', nudge.to_user_name);
        return null;
      }

      // 알림 메시지 구성 (커스텀 메시지 지원)
      const isCustomMessage = nudge.custom_message && nudge.custom_message.trim() !== '';
      const notificationBody = isCustomMessage
        ? `${nudge.from_user_name}: ${nudge.custom_message}`
        : `${nudge.from_user_name}님이 "${nudge.task_title}" 작업 완료를 독촉하고 있습니다!`;

      const message = {
        notification: {
          title: '🔔 독촉 알림!',
          body: notificationBody,
        },
        data: {
          task_id: nudge.task_id,
          task_title: nudge.task_title || '',
          from_user_id: nudge.from_user_id,
          custom_message: nudge.custom_message || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'nudge',
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: '🔔 독촉 알림!',
                body: `${nudge.from_user_name}님이 작업 완료를 독촉하고 있습니다!`,
              },
            },
          },
        },
      };

      // 알림 전송
      const response = await admin.messaging().send(message);
      console.log('✅ 알림 전송 성공:', nudge.to_user_name, response);

      return response;
    } catch (error) {
      console.error('❌ 알림 전송 실패:', error);
      return null;
    }
  });

// 작업 생성 시 알림 전송 (선택사항)
exports.sendTaskAssignedNotification = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const workerIds = task.worker_ids || [];

    if (workerIds.length === 0) {
      return null;
    }

    console.log('작업 생성 알림 트리거:', task.title);

    const promises = workerIds.map(async (workerId) => {
      try {
        const workerDoc = await admin.firestore()
          .collection('users')
          .doc(workerId)
          .get();

        if (!workerDoc.exists) {
          console.log('사용자를 찾을 수 없습니다:', workerId);
          return null;
        }

        const workerData = workerDoc.data();
        const fcmToken = workerData.fcm_token;

        if (!fcmToken) {
          console.log('FCM 토큰이 없습니다:', workerData.name);
          return null;
        }

        const message = {
          notification: {
            title: '📋 새 작업이 배정되었습니다',
            body: `"${task.title}" 작업이 배정되었습니다`,
          },
          data: {
            task_id: context.params.taskId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            type: 'task_assigned',
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

        const response = await admin.messaging().send(message);
        console.log('✅ 작업 배정 알림 전송 성공:', workerData.name);
        return response;
      } catch (error) {
        console.error('❌ 작업 배정 알림 전송 실패:', error);
        return null;
      }
    });

    await Promise.all(promises);
    return null;
  });

// 댓글 작성 시 알림 전송
exports.sendCommentNotification = functions.firestore
  .document('comment_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();

    console.log('댓글 알림 트리거:', notification);

    try {
      // 수신자의 FCM 토큰 가져오기
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.to_user_id)
        .get();

      if (!userDoc.exists) {
        console.log('사용자를 찾을 수 없습니다:', notification.to_user_id);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcm_token;

      if (!fcmToken) {
        console.log('FCM 토큰이 없습니다:', notification.to_user_name);
        return null;
      }

      // 댓글 내용이 길면 잘라서 표시
      const commentPreview = notification.comment_content.length > 50
        ? notification.comment_content.substring(0, 50) + '...'
        : notification.comment_content;

      const message = {
        notification: {
          title: `💬 "${notification.task_title}" 작업에 새 댓글`,
          body: `${notification.from_user_name}: ${commentPreview}`,
        },
        data: {
          task_id: notification.task_id,
          task_title: notification.task_title,
          comment_id: notification.comment_id,
          from_user_id: notification.from_user_id,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'comment',
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: `💬 "${notification.task_title}" 작업에 새 댓글`,
                body: `${notification.from_user_name}: ${commentPreview}`,
              },
            },
          },
        },
      };

      // 알림 전송
      const response = await admin.messaging().send(message);
      console.log('✅ 댓글 알림 전송 성공:', notification.to_user_name, response);

      return response;
    } catch (error) {
      console.error('❌ 댓글 알림 전송 실패:', error);
      return null;
    }
  });
