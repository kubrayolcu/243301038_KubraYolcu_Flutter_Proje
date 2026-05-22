import 'package:cloud_firestore/cloud_firestore.dart';

class LogService {
  static Future<void> logYaz({
    required String email,
    required String adSoyad,
    required String islem,
    required String detay,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('logs').add({
        'userEmail': email,
        'userFullName': adSoyad,
        'action': islem,
        'details': detay,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Log başarıyla kaydedildi: $islem");
    } catch (e) {
      print("Log kaydedilirken hata oluştu: $e");
    }
  }
}
