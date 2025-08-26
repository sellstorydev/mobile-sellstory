import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/company_picker.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/services/company_service.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/services/id_generation_service.dart';
import '../../../data/repositories/firestore_repository.dart';

class AddEditCompanyPage extends StatefulWidget {
  final Company? company; // null for add, not null for edit

  const AddEditCompanyPage({super.key, this.company});

  @override
  State<AddEditCompanyPage> createState() => _AddEditCompanyPageState();
}

class _AddEditCompanyPageState extends State<AddEditCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _branchController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _websiteController = TextEditingController();

  // Location fields
  final _subdistrictController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  // Multiple emails and phones
  List<Map<String, String>> _emails = [];
  List<Map<String, String>> _phones = [];

  // Hashtag related
  final HashtagService _hashtagService = HashtagService();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final IdGenerationService _idGenerationService = Get.find<IdGenerationService>();
  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtags = [];
  bool _isLoadingHashtags = true;
  
  // User and workspace related
  String _currentUserId = '';
  String _currentWorkspaceId = '';

  @override
  void initState() {
    super.initState();
    _initializeUserAndWorkspace();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      _currentUserId = currentUser.uid;
      print('👤 Initializing company page with user: $_currentUserId');
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(_currentUserId);
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        _currentWorkspaceId = firstWorkspace['id'] as String;
        
        print('✅ Company page initialized with workspace: ${firstWorkspace['name']}');
        
        // Initialize form and load hashtags
        _initializeForm();
        await _loadHashtags();
      } else {
        print('⚠️ No workspaces found for user: $_currentUserId');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    }
  }

  Future<void> _loadHashtags() async {
    try {
      if (_currentWorkspaceId.isEmpty) {
        print('⚠️ AddEditCompanyPage: No workspace ID available for hashtags');
        setState(() {
          _isLoadingHashtags = false;
        });
        return;
      }
      
      final hashtags = await _hashtagService.getHashtagsByScope(_currentWorkspaceId, 'company');
      
      setState(() {
        _availableHashtags = hashtags;
        _isLoadingHashtags = false;
      });
    } catch (e) {
      print('Error loading hashtags: $e');
      setState(() {
        _isLoadingHashtags = false;
      });
    }
  }

  void _initializeForm() {
    if (widget.company != null) {
      // Edit mode - populate with existing data
      final company = widget.company!;
      _nameController.text = company.displayName;
      _taxIdController.text = company.taxId;
      _branchController.text = company.branch;
      _addressLine1Controller.text = company.addressLine1;
      _websiteController.text = company.website;
      _subdistrictController.text = company.subdistrict;
      _districtController.text = company.district;
      _provinceController.text = company.province;
      _postalCodeController.text = company.postalCode;
      _countryController.text = company.country;

      // Parse emails and phones from object format
      if (company.emails.isNotEmpty) {
        _emails = company.emails.map((emailObj) {
          return {
            'id': emailObj['id'] as String? ?? 'email-initial',
            'label': emailObj['label'] as String? ?? 'Work',
            'value': emailObj['value'] as String? ?? '',
          };
        }).toList();
      }

      if (company.phones.isNotEmpty) {
        _phones = company.phones.map((phoneObj) {
          return {
            'id': phoneObj['id'] as String? ?? 'phone-initial',
            'label': phoneObj['label'] as String? ?? 'Work',
            'value': phoneObj['value'] as String? ?? '',
          };
        }).toList();
      }

      // Parse hashtags from object format to IDs
      if (company.hashtags.isNotEmpty) {
        _selectedHashtags = company.hashtags.map((hashtagObj) {
          return hashtagObj['id'] as String;
        }).toList();
      }
    } else {
      // Add mode - initialize with default values
      _emails = [
        {'id': 'email-initial', 'label': 'Work', 'value': ''},
      ];
      _phones = [
        {'id': 'phone-initial', 'label': 'Work', 'value': ''},
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _branchController.dispose();
    _addressLine1Controller.dispose();
    _websiteController.dispose();
    _subdistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(widget.company != null ? 'แก้ไขบริษัท' : 'เพิ่มบริษัท'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveCompany,
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Name
              _buildTextField('ชื่อบริษัท', _nameController, isRequired: true),
              const SizedBox(height: 16),

              // Tax ID
              _buildTextField('เลขประจำตัวผู้เสียภาษี', _taxIdController),
              const SizedBox(height: 16),

              // Branch
              _buildTextField('สาขา', _branchController),
              const SizedBox(height: 16),

              // Website
              _buildTextField(
                'เว็บไซต์',
                _websiteController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Location Fields
              _buildLocationSection(),
              const SizedBox(height: 16),

              // Emails
              _buildMultipleEmailsSection(),
              const SizedBox(height: 16),

              // Phones
              _buildMultiplePhonesSection(),
              const SizedBox(height: 16),

              // Hashtags
              if (_isLoadingHashtags)
                const Center(child: CircularProgressIndicator())
              else
                HashtagInputField(
                  selectedHashtags: _selectedHashtags,
                  availableHashtags: _availableHashtags,
                  onHashtagsChanged: (hashtags) {
                    setState(() {
                      _selectedHashtags = hashtags;
                    });
                  },
                  label: 'แฮชแท็ก',
                  hintText: 'เลือกแฮชแท็ก',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอก $label';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('ที่อยู่', _addressLine1Controller, maxLines: 3),
          const SizedBox(height: 16),

          // Subdistrict
          _buildTextField('ตำบล/แขวง', _subdistrictController),
          const SizedBox(height: 16),

          // District
          _buildTextField('อำเภอ/เขต', _districtController),
          const SizedBox(height: 16),

          // Province
          _buildTextField('จังหวัด', _provinceController),
          const SizedBox(height: 16),

          // Postal Code
          _buildTextField(
            'รหัสไปรษณีย์',
            _postalCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Country
          _buildTextField('ประเทศ', _countryController),
        ],
      ),
    );
  }

  Widget _buildMultipleEmailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'อีเมล',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _addEmail,
                icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
                tooltip: 'เพิ่มอีเมล',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._emails.asMap().entries.map((entry) {
            final index = entry.key;
            final email = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: email['label'],
                      decoration: const InputDecoration(
                        labelText: 'ประเภท',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => email['label'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: email['value'],
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => email['value'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _emails.length > 1
                        ? () => _removeEmail(index)
                        : null,
                    icon: Icon(
                      Icons.delete,
                      color: _emails.length > 1 ? Colors.red : Colors.grey,
                    ),
                    tooltip: 'ลบอีเมล',
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMultiplePhonesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'เบอร์โทรศัพท์',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _addPhone,
                icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
                tooltip: 'เพิ่มเบอร์โทร',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._phones.asMap().entries.map((entry) {
            final index = entry.key;
            final phone = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: phone['label'],
                      decoration: const InputDecoration(
                        labelText: 'ประเภท',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => phone['label'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: phone['value'],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทร',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => phone['value'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _phones.length > 1
                        ? () => _removePhone(index)
                        : null,
                    icon: Icon(
                      Icons.delete,
                      color: _phones.length > 1 ? Colors.red : Colors.grey,
                    ),
                    tooltip: 'ลบเบอร์โทร',
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildComingSoonField(String label, String fieldName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.construction,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addEmail() {
    setState(() {
      _emails.add({
        'id': 'email-${DateTime.now().millisecondsSinceEpoch}',
        'label': 'Work',
        'value': '',
      });
    });
  }

  void _removeEmail(int index) {
    setState(() {
      _emails.removeAt(index);
    });
  }

  void _addPhone() {
    setState(() {
      _phones.add({
        'id': 'phone-${DateTime.now().millisecondsSinceEpoch}',
        'label': 'Work',
        'value': '',
      });
    });
  }

  void _removePhone(int index) {
    setState(() {
      _phones.removeAt(index);
    });
  }

  Future<String> _generateCustomId() async {
    try {
      if (_currentWorkspaceId.isEmpty) {
        print('⚠️ AddEditCompanyPage: No workspace ID available for ID generation');
        return 'COM-${DateTime.now().millisecondsSinceEpoch}';
      }
      
      return await _idGenerationService.generateCompanyId(_currentWorkspaceId);
    } catch (e) {
      print('Error generating company ID: $e');
      return 'COM-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _saveCompany() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Convert emails and phones to object format for storage
        final emailsObjects = _emails
            .where((email) => email['value']?.isNotEmpty == true)
            .map(
              (email) => {
                'id': email['id'] as String? ?? 'email-initial',
                'label': email['label'] as String? ?? 'Work',
                'value': email['value'] as String? ?? '',
              },
            )
            .toList();

        final phonesObjects = _phones
            .where((phone) => phone['value']?.isNotEmpty == true)
            .map(
              (phone) => {
                'id': phone['id'] as String? ?? 'phone-initial',
                'label': phone['label'] as String? ?? 'Work',
                'value': phone['value'] as String? ?? '',
              },
            )
            .toList();

        // Get workspace ID and user ID
        final workspaceId = _currentWorkspaceId;
        final userId = _currentUserId;

        // Generate custom ID for new companies
        final customId = widget.company?.customId ?? await _generateCustomId();

        // Create company object
        final company = Company(
          id: widget.company?.id ?? '',
          companyNames: [
            {
              'id': widget.company?.id ?? '',
              'label': 'Main',
              'value': _nameController.text.trim(),
            }
          ],
          customId: customId,
          emails: emailsObjects,
          phones: phonesObjects,
          taxId: _taxIdController.text.trim(),
          branch: _branchController.text.trim(),
          addressLine1: _addressLine1Controller.text.trim(),
          subdistrict: _subdistrictController.text.trim(),
          district: _districtController.text.trim(),
          province: _provinceController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          hashtags: _selectedHashtags.map((hashtagId) {
            final hashtag = _availableHashtags.firstWhere(
              (h) => h.id == hashtagId,
              orElse: () => HashtagOption(
                id: hashtagId,
                name: hashtagId,
                color: '#ef4444',
                totalUsage: 0,
                enabled: true,
                scopes: {},
              ),
            );
            return {
              'color': hashtag.color,
              'id': hashtag.id,
              'text': hashtag.name,
            };
          }).toList(),
          website: _websiteController.text.trim(),
          workspaceId: workspaceId,
          createdAt: widget.company?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.company?.createdBy ?? userId,
          updatedBy: userId,
          associatedCustomerIds: widget.company?.associatedCustomerIds ?? [],
        );

        final companyService = CompanyService();

        if (widget.company != null) {
          // Update existing company
          await companyService.updateCompany(workspaceId, company);
        } else {
          // Add new company
          await companyService.addCompany(workspaceId, company);
        }

        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.company != null
                  ? 'อัปเดตข้อมูลบริษัทเรียบร้อยแล้ว'
                  : 'เพิ่มบริษัทใหม่เรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Pop with result to trigger refresh
        Navigator.pop(context, true);
      } catch (e) {
        // Close loading dialog
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
