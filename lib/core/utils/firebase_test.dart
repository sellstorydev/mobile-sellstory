import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/logger_service.dart';

class FirebaseTest {
  static Future<bool> testFirestoreConnection() async {
    try {
      // ทดสอบการเชื่อมต่อ Firestore
      final firestore = FirebaseFirestore.instance;
      
      // ทดสอบการอ่านข้อมูลจาก collection
      final testDoc = await firestore.collection('test').doc('connection_test').get();
      
      // ทดสอบการเขียนข้อมูล
      await firestore.collection('test').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'connected',
        'test': true,
      });
      
      LoggerService.to.firebase('Connection test successful');
      return true;
    } catch (e) {
      LoggerService.to.failure('Firestore connection test failed', e);
      return false;
    }
  }

  static Future<void> showConnectionStatus(BuildContext context) async {
    final isConnected = await testFirestoreConnection();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected 
              ? '✅ เชื่อมต่อ Firestore สำเร็จ!' 
              : '❌ เชื่อมต่อ Firestore ล้มเหลว',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> getFirestoreInfo() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      LoggerService.to.firebase('Getting Firestore info');
      
      // ตรวจสอบข้อมูลการตั้งค่า
      return {
        'projectId': firestore.app.options.projectId,
        'isConnected': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggerService.to.error('Failed to get Firestore info', e);
      return {
        'error': e.toString(),
        'isConnected': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
