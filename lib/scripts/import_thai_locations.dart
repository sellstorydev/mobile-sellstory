import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to fetch Thai location data from GitHub and upload to Firestore
class ThaiLocationDataImporter {
  static const String dataUrl = 'https://raw.githubusercontent.com/kongvut/thai-province-data/master/api_province_with_amphure_tambon.json';


  static Future<void> importData() async {
    try {
      print('🔄 Fetching Thai location data from GitHub...');

      // Fetch data from URL
      final response = await http.get(Uri.parse(dataUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }

      print('✅ Data fetched successfully');

      // Parse JSON data
      final rawData = json.decode(response.body) as List<dynamic>;
      print('📊 Processing ${rawData.length} provinces...');

      // Transform data structure
      final processedData = _processThaiLocationData(rawData);

      // Initialize Firebase (you'll need to configure this)
      await Firebase.initializeApp();

      // Upload to Firestore
      await _uploadToFirestore(processedData);

      print('🎉 Import completed successfully!');

    } catch (e) {
      print('❌ Error importing data: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _processThaiLocationData(List<dynamic> rawData) {
    final List<Map<String, dynamic>> provinces = [];
    final List<Map<String, dynamic>> districts = [];
    final List<Map<String, dynamic>> subdistricts = [];

    for (final provinceData in rawData) {
      final province = provinceData as Map<String, dynamic>;

      // Add province
      provinces.add({
        'id': province['id'].toString(),
        'name_th': province['name_th'],
        'name_en': province['name_en'],
        'geography_id': province['geography_id'],
      });

      // Process amphures (districts)
      final amphures = province['amphure'] as List<dynamic>? ?? [];
      for (final amphureData in amphures) {
        final amphure = amphureData as Map<String, dynamic>;

        districts.add({
          'id': amphure['id'].toString(),
          'name_th': amphure['name_th'],
          'name_en': amphure['name_en'],
          'province_id': province['id'].toString(),
        });

        // Process tambons (subdistricts)
        final tambons = amphure['tambon'] as List<dynamic>? ?? [];
        for (final tambonData in tambons) {
          final tambon = tambonData as Map<String, dynamic>;

          subdistricts.add({
            'id': tambon['id'].toString(),
            'name_th': tambon['name_th'],
            'name_en': tambon['name_en'],
            'district_id': amphure['id'].toString(),
            'zip_code': tambon['zip_code'],
          });
        }
      }
    }

    print('📈 Processed data:');
    print('  - ${provinces.length} provinces');
    print('  - ${districts.length} districts');
    print('  - ${subdistricts.length} subdistricts');

    return {
      'provinces': provinces,
      'districts': districts,
      'subdistricts': subdistricts,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> _uploadToFirestore(Map<String, dynamic> data) async {
    try {
      print('🔄 Uploading to Firestore...');

      final firestore = FirebaseFirestore.instance;

      // Upload to thai_locations/data document
      await firestore
          .collection('thai_locations')
          .doc('data')
          .set(data);

      print('✅ Data uploaded to Firestore successfully');

    } catch (e) {
      print('❌ Error uploading to Firestore: $e');
      rethrow;
    }
  }

  /// Save data to local JSON file for backup/testing
  static Future<void> saveToLocalFile(Map<String, dynamic> data) async {
    try {
      final file = File('thai_locations_data.json');
      await file.writeAsString(json.encode(data));
      print('💾 Data saved to local file: ${file.path}');
    } catch (e) {
      print('❌ Error saving to local file: $e');
    }
  }
}
