import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<QuerySnapshot>? _jobSubscription;

  // ✅ Initialize once (e.g. in main.dart)
  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // your app icon

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle what happens when a user taps on the notification
        print('Notification tapped: ${response.payload}');
        // You can add navigation logic here
      },
    );
  }

  // ✅ Show a simple notification for attendance (already in use)
  static Future<void> showReminder(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'attendance_channel', // channel id
          'Attendance Notifications', // channel name
          channelDescription: 'Reminders for attendance check-in/check-out',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0, // notification id
      title,
      body,
      platformDetails,
    );
  }

  // ✅ Show a notification for job assignments or updates
  static Future<void> showJobNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'job_notifications_channel', // channel id
          'Job Notifications', // channel name
          channelDescription:
              'Notifications related to job assignments and updates.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      1, // notification id (could be dynamic if needed)
      title,
      body,
      platformDetails,
    );
  }

  // ✅ Handle background notifications
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Background message received: ${message.notification?.title}');
    // You can add logic here to show notifications or handle the message
    showJobNotification(
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
    );
  }

  // ✅ Handle foreground notifications
  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.notification?.title}');
    showJobNotification(
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
    );
  }

  static void startJobListener() {
    if (_jobSubscription != null) {
      _jobSubscription!.cancel();
    }

    _jobSubscription = FirebaseFirestore.instance
        .collection('jobs')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final jobData = change.doc.data();
              if (jobData != null) {
                final oldData =
                    change.oldIndex != -1
                        ? snapshot.docs[change.oldIndex].data()
                        : null;
                if (oldData != null && oldData['status'] != jobData['status']) {
                  NotificationService.showReminder(
                    'Job Status Updated',
                    'Job status for "${jobData['vehiclePlate']}" changed to: ${jobData['status']}',
                  );
                }
              }
            }
          }
        });
  }

  // A new method to stop the job listener
  static void stopJobListener() {
    if (_jobSubscription != null) {
      _jobSubscription!.cancel();
      _jobSubscription = null;
    }
  }
}
