import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'app_name': 'SellStory',
          'identity_hint': 'Email or mobile number',
          'password_hint': 'Password',
          'forgot_password': 'Forgot password',
          'login': 'Login',
          'register_q': "Don't have an account?",
          'register': 'Register',
          'version': 'version 1.6.5',
          'invalid_credentials': 'Invalid credentials',
        },
        'th_TH': {
          'app_name': 'SellStory',
          'identity_hint': 'อีเมลล์หรือเบอร์โทรศัพท์มือถือผู้ใช้',
          'password_hint': 'รหัสผ่าน',
          'forgot_password': 'ลืมรหัสผ่าน',
          'login': 'เข้าสู่ระบบ',
          'register_q': 'ยังไม่เคยมีบัญชี',
          'register': 'ลงทะเบียน',
          'version': 'version 1.6.5',
          'invalid_credentials': 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง',
        }
      };
}
