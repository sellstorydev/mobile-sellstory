import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../board/controller/board_controller.dart';
import '../../../data/repositories/firestore_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _documentDisplayNameController = TextEditingController();
  final _documentPhoneNumberController = TextEditingController();
  
  // final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  
  User? _currentUser;
  File? _selectedImageFile;
  String? _currentPhotoURL;
  
  // Workspace info
  String? _currentWorkspaceName;
  String? _currentWorkspaceRole;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _loadWorkspaceInfo();
  }

  void _initializeUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _displayNameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
      _currentPhotoURL = _currentUser!.photoURL;
    }
  }

  Future<void> _loadWorkspaceInfo() async {
    try {
      final boardController = Get.find<BoardController>();
      final firestoreRepo = Get.find<FirestoreRepository>();
      
      // Get current workspace name from BoardController
      if (boardController.currentWorkspaceId.value.isNotEmpty) {
        _currentWorkspaceName = boardController.currentWorkspaceName.value;
        
        // Get user role from Firestore
        final userId = _currentUser?.uid;
        if (userId != null) {
          final userData = await firestoreRepo.getUserById(userId);
          if (userData != null) {
            final workspaces = userData['workspaces'] as List<dynamic>?;
            
            if (workspaces != null) {
              for (final workspace in workspaces) {
                if (workspace['id'] == boardController.currentWorkspaceId.value) {
                  _currentWorkspaceRole = workspace['role'];
                  break;
                }
              }
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading workspace info: $e');
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _documentDisplayNameController.dispose();
    _documentPhoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  Future<void> _showImagePickerDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เลือกรูปโปรไฟล์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update display name
      if (_displayNameController.text.trim() != currentUser.displayName) {
        await currentUser.updateDisplayName(_displayNameController.text.trim());
      }

      // Note: Email is disabled and cannot be updated

      // Update photo URL if image selected
      if (_selectedImageFile != null) {
        // TODO: Implement image upload to Firebase Storage
        // For now, we'll just show a success message
        Get.snackbar(
          'Success',
          'Profile updated successfully! Note: Photo upload feature coming soon.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Success',
          'Profile updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      // Navigate back
      Get.back();
    } catch (e) {
      _showError('Failed to update profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'บันทึก',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Photo Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Profile Photo
                          GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.primaryOrange,
                                  backgroundImage: _selectedImageFile != null
                                      ? FileImage(_selectedImageFile!)
                                      : (_currentPhotoURL != null
                                          ? NetworkImage(_currentPhotoURL!)
                                          : null) as ImageProvider?,
                                  child: (_selectedImageFile == null && _currentPhotoURL == null)
                                      ? Text(
                                          _displayNameController.text.isNotEmpty
                                              ? _displayNameController.text[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'แตะเพื่อเปลี่ยนรูปโปรไฟล์',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Profile Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลส่วนตัว',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Email (disabled and moved to top)
                          TextFormField(
                            controller: _emailController,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'อีเมล',
                              hintText: 'example@email.com',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Display Name
                          Column(
                            children: [
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อที่แสดง',
                                  hintText: 'ใส่ชื่อที่ต้องการแสดง',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'กรุณาใส่ชื่อที่แสดง';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              TextFormField(
                                controller: _phoneNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'เบอร์โทรศัพท์',
                                  hintText: 'ใส่เบอร์โทรศัพท์',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                                      return 'กรุณาใส่เบอร์โทรที่ถูกต้อง';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Document Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, color: AppTheme.primaryOrange),
                              const SizedBox(width: 8),
                              const Text(
                                'ข้อมูลสำหรับเอกสาร',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ข้อมูลที่จะแสดงในเอกสารและรายงาน',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Document Display Name and Phone Number
                          Column(
                            children: [
                              TextFormField(
                                controller: _documentDisplayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อที่แสดงในเอกสาร',
                                  hintText: 'เช่น นาย สมชาย ใจดี (แผนกขาย)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  // Optional field
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              TextFormField(
                                controller: _documentPhoneNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'เบอร์โทรในเอกสาร',
                                  hintText: 'เช่น 081-234-5678',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_in_talk_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                                      return 'กรุณาใส่เบอร์โทรที่ถูกต้อง';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account Info Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลบัญชี',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // User ID
                          ListTile(
                            leading: const Icon(Icons.badge_outlined, color: AppTheme.textSecondary),
                            title: const Text('User ID'),
                            subtitle: Text(
                              _currentUser?.uid ?? 'N/A',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          // Account Created
                          ListTile(
                            leading: const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary),
                            title: const Text('สร้างบัญชีเมื่อ'),
                            subtitle: Text(
                              _currentUser?.metadata.creationTime != null
                                  ? '${_currentUser!.metadata.creationTime!.day}/${_currentUser!.metadata.creationTime!.month}/${_currentUser!.metadata.creationTime!.year}'
                                  : 'N/A',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          // Last Sign In
                          ListTile(
                            leading: const Icon(Icons.access_time_outlined, color: AppTheme.textSecondary),
                            title: const Text('เข้าสู่ระบบล่าสุด'),
                            subtitle: Text(
                              _currentUser?.metadata.lastSignInTime != null
                                  ? '${_currentUser!.metadata.lastSignInTime!.day}/${_currentUser!.metadata.lastSignInTime!.month}/${_currentUser!.metadata.lastSignInTime!.year}'
                                  : 'N/A',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          // Current Workspace
                          if (_currentWorkspaceName != null) ...[
                            ListTile(
                              leading: const Icon(Icons.business_outlined, color: AppTheme.textSecondary),
                              title: const Text('เวิร์กสเปซปัจจุบัน'),
                              subtitle: Text(_currentWorkspaceName!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                          
                          // User Role in Workspace
                          if (_currentWorkspaceRole != null) ...[
                            ListTile(
                              leading: Icon(
                                _getRoleIcon(_currentWorkspaceRole!),
                                color: _getRoleColor(_currentWorkspaceRole!),
                              ),
                              title: const Text('role'),
                              subtitle: Text(
                                _getRoleDisplayName(_currentWorkspaceRole!),
                                style: TextStyle(
                                  color: _getRoleColor(_currentWorkspaceRole!),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper methods for role display
  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.star_outline;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'member':
        return Icons.person_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.amber;
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'owner';
      case 'admin':
        return 'admin';
      case 'member':
        return 'member';
      default:
        return role;
    }
  }
}
