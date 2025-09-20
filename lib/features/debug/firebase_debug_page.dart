import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/utils/firebase_test.dart';

class FirebaseDebugPage extends StatefulWidget {
  const FirebaseDebugPage({super.key});

  @override
  State<FirebaseDebugPage> createState() => _FirebaseDebugPageState();
}

class _FirebaseDebugPageState extends State<FirebaseDebugPage> {
  bool _isLoading = false;
  Map<String, dynamic> _firestoreInfo = {};
  bool _connectionStatus = false;

  @override
  void initState() {
    super.initState();
    _loadFirestoreInfo();
  }

  Future<void> _loadFirestoreInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await FirebaseTest.getFirestoreInfo();
      final connectionStatus = await FirebaseTest.testFirestoreConnection();

      setState(() {
        _firestoreInfo = info;
        _connectionStatus = connectionStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _firestoreInfo = {'error': e.toString()};
        _connectionStatus = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Firebase Debug',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: AppTheme.fontSize18,
            fontFamily: AppFont.family,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.figmaOrange),
            onPressed: _loadFirestoreInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.figmaOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: AppTheme.spacing4,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _connectionStatus
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: _connectionStatus
                                  ? AppTheme.figmaGreen
                                  : AppTheme.figmaRed,
                              size: AppTheme.iconSize24,
                            ),
                            Container(width: AppTheme.spacing12),
                            const Text(
                              'สถานะการเชื่อมต่อ',
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontSize: AppTheme.fontSize18,
                                fontFamily: AppFont.family,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(height: AppTheme.spacing12),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacing12),
                          decoration: BoxDecoration(
                            color: _connectionStatus
                                ? AppTheme.figmaGreen.withOpacity(0.1)
                                : AppTheme.figmaRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _connectionStatus
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _connectionStatus
                                    ? AppTheme.figmaGreen
                                    : AppTheme.figmaRed,
                                size: AppTheme.iconSize20,
                              ),
                              Container(width: AppTheme.spacing8),
                              Expanded(
                                child: Text(
                                  _connectionStatus
                                      ? 'เชื่อมต่อ Firestore สำเร็จ'
                                      : 'เชื่อมต่อ Firestore ล้มเหลว',
                                  style: TextStyle(
                                    color: _connectionStatus
                                        ? AppTheme.figmaGreen
                                        : AppTheme.figmaRed,
                                    fontSize: AppTheme.fontSize14,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: AppTheme.spacing20),

                  // Firestore Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: AppTheme.spacing4,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.figmaOrange,
                              size: AppTheme.iconSize24,
                            ),
                            Container(width: AppTheme.spacing12),
                            const Text(
                              'ข้อมูล Firestore',
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontSize: AppTheme.fontSize18,
                                fontFamily: AppFont.family,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(height: AppTheme.spacing16),
                        ..._firestoreInfo.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacing8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${entry.key}:',
                                    style: const TextStyle(
                                      color: AppTheme.textMedium,
                                      fontSize: AppTheme.fontSize14,
                                      fontFamily: AppFont.family,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      color: AppTheme.textDark,
                                      fontSize: AppTheme.fontSize14,
                                      fontFamily: AppFont.family,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: AppTheme.spacing20),

                  // Test Buttons
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: AppTheme.spacing4,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ทดสอบการเชื่อมต่อ',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: AppTheme.fontSize18,
                            fontFamily: AppFont.family,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(height: AppTheme.spacing16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result =
                                  await FirebaseTest.testFirestoreConnection();
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result
                                          ? '��� ทดสอบการเชื่อ���ต่อสำเร็จ!'
                                          : '❌ ทดสอบการเชื่อมต่อล้มเหลว',
                                    ),
                                    backgroundColor: result
                                        ? AppTheme.figmaGreen
                                        : AppTheme.figmaRed,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.figmaOrange,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius8,
                                ),
                              ),
                            ),
                            child: const Text(
                              'ทดสอบการเชื่อมต่อ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppTheme.fontSize16,
                                fontFamily: AppFont.family,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
