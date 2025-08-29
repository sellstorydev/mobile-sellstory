import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/firebase_auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _showPasswordFields = false;
  
  User? _currentUser;
  File? _selectedImageFile;
  String? _currentPhotoURL;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _displayNameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
      _currentPhotoURL = _currentUser!.photoURL;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

      // Update email if changed
      if (_emailController.text.trim() != currentUser.email) {
        await currentUser.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      // Update password if provided
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception('Passwords do not match');
        }
        await currentUser.updatePassword(_passwordController.text);
      }

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

      // Clear password fields
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _showPasswordFields = false;
      });

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
                          
                          // Display Name
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
                          
                          const SizedBox(height: 16),
                          
                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'อีเมล',
                              hintText: 'example@email.com',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณาใส่อีเมล';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'กรุณาใส่อีเมลที่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Password Section
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
                              const Text(
                                'เปลี่ยนรหัสผ่าน',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                                                             Switch(
                                 value: _showPasswordFields,
                                 onChanged: (value) {
                                   setState(() {
                                     _showPasswordFields = value;
                                     if (!value) {
                                       _passwordController.clear();
                                       _confirmPasswordController.clear();
                                     }
                                   });
                                 },
                                //  activeThumbColor: AppTheme.primaryOrange,
                               ),
                            ],
                          ),
                          
                          if (_showPasswordFields) ...[
                            const SizedBox(height: 16),
                            
                            // New Password
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่านใหม่',
                                hintText: 'ใส่รหัสผ่านใหม่',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (_showPasswordFields && (value == null || value.isEmpty)) {
                                  return 'กรุณาใส่รหัสผ่านใหม่';
                                }
                                if (value != null && value.isNotEmpty && value.length < 6) {
                                  return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'ยืนยันรหัสผ่านใหม่',
                                hintText: 'ใส่รหัสผ่านใหม่อีกครั้ง',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isConfirmPasswordVisible,
                              validator: (value) {
                                if (_showPasswordFields && (value == null || value.isEmpty)) {
                                  return 'กรุณายืนยันรหัสผ่านใหม่';
                                }
                                if (_showPasswordFields && value != _passwordController.text) {
                                  return 'รหัสผ่านไม่ตรงกัน';
                                }
                                return null;
                              },
                            ),
                          ],
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
