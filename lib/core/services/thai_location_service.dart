import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ThaiLocationService extends GetxService {
  static ThaiLocationService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for better performance
  final Map<String, List<Map<String, dynamic>>> _provinceCache = {};
  final Map<String, List<Map<String, dynamic>>> _districtCache = {};
  final Map<String, List<Map<String, dynamic>>> _subdistrictCache = {};

  // Get all provinces
  Future<List<Map<String, dynamic>>> getProvinces() async {
    if (_provinceCache.containsKey('all')) {
      return _provinceCache['all']!;
    }

    try {
      final snapshot = await _firestore
          .collection('thai_locations')
          .doc('data')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final provinces = List<Map<String, dynamic>>.from(data['provinces'] ?? []);

        // Sort provinces alphabetically
        provinces.sort((a, b) => (a['name_th'] as String).compareTo(b['name_th'] as String));

        _provinceCache['all'] = provinces;
        return provinces;
      }

      // Fallback to hardcoded data if Firestore is not available
      return _getHardcodedProvinces();
    } catch (e) {
      print('Error fetching provinces: $e');
      return _getHardcodedProvinces();
    }
  }

  // Get districts by province ID
  Future<List<Map<String, dynamic>>> getDistrictsByProvince(String provinceId) async {
    if (_districtCache.containsKey(provinceId)) {
      return _districtCache[provinceId]!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('thai_locations')
          .doc('data')
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final districts = List<Map<String, dynamic>>.from(data['districts'] ?? [])
            .where((district) => district['province_id'] == provinceId)
            .toList();
        
        // Sort districts alphabetically
        districts.sort((a, b) => (a['name_th'] as String).compareTo(b['name_th'] as String));
        
        _districtCache[provinceId] = districts;
        return districts;
      }

      return [];
    } catch (e) {
      print('Error fetching districts: $e');
      return [];
    }
  }
  
  // Get subdistricts by district ID
  Future<List<Map<String, dynamic>>> getSubdistrictsByDistrict(String districtId) async {
    if (_subdistrictCache.containsKey(districtId)) {
      return _subdistrictCache[districtId]!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('thai_locations')
          .doc('data')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final subdistricts = List<Map<String, dynamic>>.from(data['subdistricts'] ?? [])
            .where((subdistrict) => subdistrict['district_id'] == districtId)
            .toList();

        // Sort subdistricts alphabetically
        subdistricts.sort((a, b) => (a['name_th'] as String).compareTo(b['name_th'] as String));

        _subdistrictCache[districtId] = subdistricts;
        return subdistricts;
      }

      return [];
    } catch (e) {
      print('Error fetching subdistricts: $e');
      return [];
    }
  }

  // Get postal code by subdistrict ID
  Future<String?> getPostalCodeBySubdistrict(String subdistrictId) async {
    try {
      final snapshot = await _firestore
          .collection('thai_locations')
          .doc('data')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final subdistricts = List<Map<String, dynamic>>.from(data['subdistricts'] ?? []);
        final subdistrict = subdistricts.firstWhere(
          (s) => s['id'] == subdistrictId,
          orElse: () => {},
        );

        if (subdistrict.isNotEmpty && subdistrict['zip_code'] != null) {
          return subdistrict['zip_code'].toString();
        }
      }

      return null;
    } catch (e) {
      print('Error fetching postal code: $e');
      return null;
    }
  }

  // Get location names by IDs for display
  Future<Map<String, String>> getLocationNames({
    String? provinceId,
    String? districtId,
    String? subdistrictId,
  }) async {
    final Map<String, String> names = {};

    try {
      final snapshot = await _firestore
          .collection('thai_locations')
          .doc('data')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (provinceId != null) {
          final provinces = List<Map<String, dynamic>>.from(data['provinces'] ?? []);
          final province = provinces.firstWhere(
            (p) => p['id'] == provinceId,
            orElse: () => {},
          );
          if (province.isNotEmpty) {
            names['province'] = province['name_th'];
          }
        }

        if (districtId != null) {
          final districts = List<Map<String, dynamic>>.from(data['districts'] ?? []);
          final district = districts.firstWhere(
            (d) => d['id'] == districtId,
            orElse: () => {},
          );
          if (district.isNotEmpty) {
            names['district'] = district['name_th'];
          }
        }

        if (subdistrictId != null) {
          final subdistricts = List<Map<String, dynamic>>.from(data['subdistricts'] ?? []);
          final subdistrict = subdistricts.firstWhere(
            (s) => s['id'] == subdistrictId,
            orElse: () => {},
          );
          if (subdistrict.isNotEmpty) {
            names['subdistrict'] = subdistrict['name_th'];
          }
        }
      }
    } catch (e) {
      print('Error fetching location names: $e');
    }

    return names;
  }

  // Clear cache
  void clearCache() {
    _provinceCache.clear();
    _districtCache.clear();
    _subdistrictCache.clear();
  }

  // Hardcoded fallback data for major provinces
  List<Map<String, dynamic>> _getHardcodedProvinces() {
    return [
      {'id': '10', 'name_th': 'กรุงเทพมหานคร', 'name_en': 'Bangkok'},
      {'id': '11', 'name_th': 'สมุทรปราการ', 'name_en': 'Samut Prakan'},
      {'id': '12', 'name_th': 'นนทบุรี', 'name_en': 'Nonthaburi'},
      {'id': '13', 'name_th': 'ปทุมธานี', 'name_en': 'Pathum Thani'},
      {'id': '14', 'name_th': 'พระนครศรีอยุธยา', 'name_en': 'Phra Nakhon Si Ayutthaya'},
      {'id': '15', 'name_th': 'อ่างทอง', 'name_en': 'Ang Thong'},
      {'id': '16', 'name_th': 'ลพบุรี', 'name_en': 'Lopburi'},
      {'id': '17', 'name_th': 'สิงห์บุรี', 'name_en': 'Sing Buri'},
      {'id': '18', 'name_th': 'ชัยนาท', 'name_en': 'Chai Nat'},
      {'id': '19', 'name_th': 'สระบุรี', 'name_en': 'Saraburi'},
      {'id': '20', 'name_th': 'ชลบุรี', 'name_en': 'Chonburi'},
      {'id': '21', 'name_th': 'ระยอง', 'name_en': 'Rayong'},
      {'id': '22', 'name_th': 'จันทบุรี', 'name_en': 'Chanthaburi'},
      {'id': '23', 'name_th': 'ตราด', 'name_en': 'Trat'},
      {'id': '24', 'name_th': 'ฉะเชิงเทรา', 'name_en': 'Chachoengsao'},
      {'id': '25', 'name_th': 'ปราจีนบุรี', 'name_en': 'Prachinburi'},
      {'id': '26', 'name_th': 'นครนายก', 'name_en': 'Nakhon Nayok'},
      {'id': '27', 'name_th': 'สระแก้ว', 'name_en': 'Sa Kaeo'},
      {'id': '30', 'name_th': 'นครราชสีมา', 'name_en': 'Nakhon Ratchasima'},
      {'id': '31', 'name_th': 'บุรีรัมย์', 'name_en': 'Buriram'},
      {'id': '32', 'name_th': 'สุรินทร์', 'name_en': 'Surin'},
      {'id': '33', 'name_th': 'ศรีสะเกษ', 'name_en': 'Sisaket'},
      {'id': '34', 'name_th': 'อุบลราชธานี', 'name_en': 'Ubon Ratchathani'},
      {'id': '35', 'name_th': 'ยโสธร', 'name_en': 'Yasothon'},
      {'id': '36', 'name_th': 'ชัยภูมิ', 'name_en': 'Chaiyaphum'},
      {'id': '37', 'name_th': 'อำนาจเจริญ', 'name_en': 'Amnat Charoen'},
      {'id': '38', 'name_th': 'หนองบัวลำภู', 'name_en': 'Nong Bua Lamphu'},
      {'id': '39', 'name_th': 'ขอนแก่น', 'name_en': 'Khon Kaen'},
      {'id': '40', 'name_th': 'อุดรธานี', 'name_en': 'Udon Thani'},
      {'id': '41', 'name_th': 'เลย', 'name_en': 'Loei'},
      {'id': '42', 'name_th': 'หนองคาย', 'name_en': 'Nong Khai'},
      {'id': '43', 'name_th': 'มหาสารคาม', 'name_en': 'Maha Sarakham'},
      {'id': '44', 'name_th': 'ร้อยเอ็ด', 'name_en': 'Roi Et'},
      {'id': '45', 'name_th': 'กาฬสินธุ์', 'name_en': 'Kalasin'},
      {'id': '46', 'name_th': 'สกลนคร', 'name_en': 'Sakon Nakhon'},
      {'id': '47', 'name_th': 'นครพนม', 'name_en': 'Nakhon Phanom'},
      {'id': '48', 'name_th': 'มุกดาหาร', 'name_en': 'Mukdahan'},
      {'id': '49', 'name_th': 'เชียงใหม่', 'name_en': 'Chiang Mai'},
      {'id': '50', 'name_th': 'ลำหลื่อง', 'name_en': 'Lamphun'},
      {'id': '51', 'name_th': 'ลำปาง', 'name_en': 'Lampang'},
      {'id': '52', 'name_th': 'อุตรดิตถ์', 'name_en': 'Uttaradit'},
      {'id': '53', 'name_th': 'แพร่', 'name_en': 'Phrae'},
      {'id': '54', 'name_th': 'น่าน', 'name_en': 'Nan'},
      {'id': '55', 'name_th': 'พะเยา', 'name_en': 'Phayao'},
      {'id': '56', 'name_th': 'เชียงราย', 'name_en': 'Chiang Rai'},
      {'id': '57', 'name_th': 'แม่ฮ่องสอน', 'name_en': 'Mae Hong Son'},
      {'id': '58', 'name_th': 'นครสวรรค์', 'name_en': 'Nakhon Sawan'},
      {'id': '60', 'name_th': 'กำแพงเพชร', 'name_en': 'Kamphaeng Phet'},
      {'id': '61', 'name_th': 'ตาก', 'name_en': 'Tak'},
      {'id': '62', 'name_th': 'สุโขทัย', 'name_en': 'Sukhothai'},
      {'id': '63', 'name_th': 'พิษณุโลก', 'name_en': 'Phitsanulok'},
      {'id': '64', 'name_th': 'พิจิตร', 'name_en': 'Phichit'},
      {'id': '65', 'name_th': 'เพชรบูรณ์', 'name_en': 'Phetchabun'},
      {'id': '66', 'name_th': 'ราชบุรี', 'name_en': 'Ratchaburi'},
      {'id': '67', 'name_th': 'กาญจนบุรี', 'name_en': 'Kanchanaburi'},
      {'id': '68', 'name_th': 'สุพรรณบุรี', 'name_en': 'Suphan Buri'},
      {'id': '70', 'name_th': 'นครปฐม', 'name_en': 'Nakhon Pathom'},
      {'id': '71', 'name_th': 'สมุทรสาคร', 'name_en': 'Samut Sakhon'},
      {'id': '72', 'name_th': 'สมุทรสงคราม', 'name_en': 'Samut Songkhram'},
      {'id': '73', 'name_th': 'เพชรบุรี', 'name_en': 'Phetchaburi'},
      {'id': '74', 'name_th': 'ประจวบคีรีขันธ์', 'name_en': 'Prachuap Khiri Khan'},
      {'id': '75', 'name_th': 'นครศรีธรรมราช', 'name_en': 'Nakhon Si Thammarat'},
      {'id': '76', 'name_th': 'กระบี่', 'name_en': 'Krabi'},
      {'id': '77', 'name_th': 'พังงา', 'name_en': 'Phang Nga'},
      {'id': '78', 'name_th': 'ภูเก็ต', 'name_en': 'Phuket'},
      {'id': '79', 'name_th': 'สุราษฎร์ธานี', 'name_en': 'Surat Thani'},
      {'id': '80', 'name_th': 'ระนอง', 'name_en': 'Ranong'},
      {'id': '81', 'name_th': 'ชุมพร', 'name_en': 'Chumphon'},
      {'id': '82', 'name_th': 'สงขลา', 'name_en': 'Songkhla'},
      {'id': '83', 'name_th': 'สตูล', 'name_en': 'Satun'},
      {'id': '84', 'name_th': 'ตรัง', 'name_en': 'Trang'},
      {'id': '85', 'name_th': 'พัทลุง', 'name_en': 'Phatthalung'},
      {'id': '86', 'name_th': 'ปัตตานี', 'name_en': 'Pattani'},
      {'id': '87', 'name_th': 'ยะลา', 'name_en': 'Yala'},
      {'id': '88', 'name_th': 'นราธิวาส', 'name_en': 'Narathiwat'},
      {'id': '89', 'name_th': 'บึงกาฬ', 'name_en': 'Bueng Kan'},
    ];
  }
}
