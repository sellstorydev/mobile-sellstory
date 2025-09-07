import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/thai_location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/widgets/assignees_input_field.dart';
import '../../../core/widgets/company_picker.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/services/id_generation_service.dart';

import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/widgets/permission_guard.dart';

class AddEditCustomerPage extends StatefulWidget {
  final Customer? customer; // null for add, not null for edit
  final List<String> customerSources; // Dynamic customer sources from database

  const AddEditCustomerPage({
    super.key,
    this.customer,
    required this.customerSources,
  });

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prefixController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _customIdController = TextEditingController();
  
  // Hashtag related
  final HashtagService _hashtagService = HashtagService();
  final IdGenerationService _idGenerationService = Get.find<IdGenerationService>();
  final WorkspaceMembersService _workspaceMembersService = Get.find<WorkspaceMembersService>();
  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtags = [];
  bool _isLoadingHashtags = true;
  
  // Assignees related
  List<WorkspaceMember> _availableMembers = [];
  List<String> _selectedAssignees = [];
  bool _isLoadingMembers = true;
  
  // Company related
  List<Company> _selectedCompanies = [];
  
  String _selectedGender = 'Male';
  String _selectedCustomerType = 'Customer';
  String _selectedSource = 'FB';
  
  // Thai Location dropdowns
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subdistricts = [];
  List<String> _postalCodes = [];

  String? _selectedProvinceId;
  String? _selectedDistrictId;
  String? _selectedSubdistrictId;
  String? _selectedPostalCode;

  bool _isLoadingLocations = false;

  // Location text controllers (kept for backward compatibility)
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _subdistrictController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  // Multiple emails and phones
  List<Map<String, String>> _emails = [];
  List<Map<String, String>> _phones = [];
  
  // Available options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _customerTypeOptions = ['Customer', 'Lead'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadHashtags();
    _loadMembers();
    _loadProvinces();
  }

  String _getSafeDropdownValue(String value, List<String> options) {
    if (options.contains(value)) {
      return value;
    }
    return options.isNotEmpty ? options.first : '';
  }

  Future<void> _loadHashtags() async {
    try {
      final controller = Get.find<CustomersController>();
      final workspaceId = controller.currentWorkspaceId.value;
      
      if (workspaceId.isEmpty) {
        print('⚠️ AddEditCustomerPage: No workspace ID available for hashtags');
        setState(() {
          _isLoadingHashtags = false;
        });
        return;
      }
      
      final hashtags = await _hashtagService.getHashtagsByScope(workspaceId, 'customer');
      
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

  Future<void> _loadMembers() async {
    try {
      final controller = Get.find<CustomersController>();
      final workspaceId = controller.currentWorkspaceId.value;
      
      if (workspaceId.isEmpty) {
        print('⚠️ AddEditCustomerPage: No workspace ID available for members');
        setState(() {
          _isLoadingMembers = false;
        });
        return;
      }
      
      final members = await _workspaceMembersService.getAssignableMembers(workspaceId);
      
      setState(() {
        _availableMembers = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      print('Error loading members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final provinces = await ThaiLocationService().getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error loading provinces: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadDistricts(String provinceId) async {
    setState(() {
      _isLoadingLocations = true;
      // Clear dependent selections
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _districts.clear();
      _subdistricts.clear();
    });

    try {
      final districts = await ThaiLocationService().getDistrictsByProvince(provinceId);
      setState(() {
        _districts = districts;
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error loading districts: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadSubdistricts(String districtId) async {
    setState(() {
      _isLoadingLocations = true;
      // Clear dependent selections
      _selectedSubdistrictId = null;
      _subdistricts.clear();
    });

    try {
      final subdistricts = await ThaiLocationService().getSubdistrictsByDistrict(districtId);
      setState(() {
        _subdistricts = subdistricts;
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error loading subdistricts: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  void _initializeForm() {
    if (widget.customer != null) {
      // Edit mode - populate with existing data
      final customer = widget.customer!;
      _nameController.text = customer.name;
      _prefixController.text = customer.prefix;
      _nationalIdController.text = customer.nationalId;
      _addressLine1Controller.text = customer.address;
      _customIdController.text = customer.customId;
      
      // Parse hashtags from object format to IDs
      if (customer.hashtags.isNotEmpty) {
        _selectedHashtags = customer.hashtags.map((hashtagObj) {
          return hashtagObj['id'] as String;
        }).toList();
        
        // Set display text for the controller
        final hashtagTexts = customer.hashtags.map((hashtagObj) {
          return hashtagObj['text'] as String;
        }).toList();
        _hashtagsController.text = hashtagTexts.join(', ');
      }
      
             // Parse assignees
       _selectedAssignees = List<String>.from(customer.assignees);
       
       // Parse companies from object format
       if (customer.companyNames.isNotEmpty) {
         // Convert companyNames to Company objects for display
         _selectedCompanies = customer.companyNames.map((companyNameObj) {
           return Company(
             id: companyNameObj['id'] as String? ?? '',
             companyNames: [companyNameObj],
             customId: '',
             emails: [],
             phones: [],
             taxId: '',
             branch: '',
             addressLine1: '',
             subdistrict: '',
             district: '',
             province: '',
             postalCode: '',
             country: '',
             hashtags: [],
             website: '',
             workspaceId: '',
             createdAt: DateTime.now(),
             updatedAt: DateTime.now(),
             createdBy: '',
             updatedBy: '',
             associatedCustomerIds: [],
           );
         }).toList();
       }
      
      _selectedGender = _getSafeDropdownValue(customer.gender, _genderOptions);
      _selectedCustomerType = _getSafeDropdownValue(customer.customerType, _customerTypeOptions);
      _selectedSource = _getSafeDropdownValue(customer.source, widget.customerSources.isNotEmpty ? widget.customerSources : []);
      
             // Set location fields with fallback to default values if empty
       _districtController.text = '';
       _provinceController.text = '';
       _subdistrictController.text = '';
       _countryController.text = '';
       _postalCodeController.text = '';
      
      // Parse emails and phones from object format
      if (customer.emails.isNotEmpty) {
        _emails = customer.emails.map((emailObj) {
          return {
            'id': emailObj['id'] as String? ?? 'email-initial',
            'label': emailObj['label'] as String? ?? 'Work',
            'value': emailObj['value'] as String? ?? '',
          };
        }).toList();
      }
      
      if (customer.phones.isNotEmpty) {
        _phones = customer.phones.map((phoneObj) {
          return {
            'id': phoneObj['id'] as String? ?? 'phone-initial',
            'label': phoneObj['label'] as String? ?? 'Work',
            'value': phoneObj['value'] as String? ?? '',
          };
        }).toList();
      }
    } else {
      // Add mode - initialize with default values
      _emails = [
        {'id': 'email-initial', 'label': 'Work', 'value': ''}
      ];
      _phones = [
        {'id': 'phone-initial', 'label': 'Work', 'value': ''}
      ];
      _selectedAssignees = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    _nationalIdController.dispose();
    _addressLine1Controller.dispose();
    _hashtagsController.dispose();
    _customIdController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _subdistrictController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(widget.customer != null ? 'แก้ไขลูกค้า' : 'เพิ่มลูกค้า'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final needed = widget.customer != null ? 'customer:edit:all' : 'customer:create';
              guardAction(context, needed, _saveCustomer);
            },
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
              // Assignees
              AssigneesInputField(
                selectedAssignees: _selectedAssignees,
                availableMembers: _availableMembers,
                onAssigneesChanged: (assignees) {
                  setState(() {
                    _selectedAssignees = assignees;
                  });
                },
                isLoading: _isLoadingMembers,
              ),
              const SizedBox(height: 16),
              
              // Customer Type
              _buildDropdownField(
                'ประเภทลูกค้า',
                _selectedCustomerType,
                _customerTypeOptions,
                (value) => setState(() => _selectedCustomerType = value!),
                isRequired: true,
              ),
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
              const SizedBox(height: 16),
              
              // Source
              _buildDropdownField(
                'แหล่งที่มา',
                _selectedSource,
                widget.customerSources.isNotEmpty ? widget.customerSources : [],
                (value) => setState(() => _selectedSource = value!),
              ),
              const SizedBox(height: 16),
              
              // National ID
              _buildTextField(
                'เลขบัตรประชาชน',
                _nationalIdController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Custom ID
              _buildCustomIdField(),
              const SizedBox(height: 16),
              
              // Prefix
              _buildTextField(
                'คำนำหน้า',
                _prefixController,
              ),
              const SizedBox(height: 16),
              
              // Name
              _buildTextField(
                'ชื่อ',
                _nameController,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              // Gender
              _buildDropdownField(
                'เพศ',
                _selectedGender,
                _genderOptions,
                (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 16),
              
              // Emails
              _buildMultipleEmailsSection(),
              const SizedBox(height: 16),
              
              // Phones
              _buildMultiplePhonesSection(),
              const SizedBox(height: 16),
              
              // Address
              _buildTextField(
                'ที่อยู่',
                _addressLine1Controller,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Location Fields
              _buildLocationSection(),
              const SizedBox(height: 16),
              
              // Company
              CompanyPicker(
                selectedCompanies: _selectedCompanies,
                onCompaniesChanged: (companies) {
                  setState(() {
                    _selectedCompanies = companies;
                  });
                },
                label: 'บริษัท',
                hintText: 'เลือกบริษัท',
              ),
            ],
          ),
        ),
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

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged, {
    bool isRequired = false,
  }) {
    // Ensure the value is valid or set to null if it doesn't exist in options
    String? validValue;
    if (value.isNotEmpty && options.contains(value)) {
      validValue = value;
    }

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
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: Text('เลือก$label'),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired ? (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาเลือก $label';
              }
              return null;
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomIdField() {
    final isEditMode = widget.customer != null;
    
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
                'รหัสลูกค้า',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (!isEditMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'อัตโนมัติ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customIdController,
            enabled: isEditMode, // Only editable in edit mode
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: isEditMode ? 'กรอกรหัสลูกค้า' : 'จะถูกสร้างอัตโนมัติ',
              filled: !isEditMode,
              fillColor: !isEditMode ? Colors.grey.shade100 : null,
            ),
            validator: isEditMode ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกรหัสลูกค้า';
              }
              return null;
            } : null,
          ),
        ],
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
        border: Border.all(color: Colors.grey.shade300),
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
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
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
            validator: isRequired ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอก $label';
              }
              return null;
            } : null,
          ),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (value) => email['value'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _emails.length > 1 ? () => _removeEmail(index) : null,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (value) => phone['value'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _phones.length > 1 ? () => _removePhone(index) : null,
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
          const Text(
            'ที่อยู่',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Province
          _buildLocationDropdown(
            'จังหวัด',
            _selectedProvinceId ?? '',
            _provinces,
            (value) {
              setState(() {
                _selectedProvinceId = value;
                if (value != null) {
                  _loadDistricts(value);
                }
              });
            },
          ),

          const SizedBox(height: 16),
          
          // District
          _buildLocationDropdown(
            'อำเภอ/เขต',
            _selectedDistrictId ?? '',
            _districts,
            (value) {
              setState(() {
                _selectedDistrictId = value;
                if (value != null) {
                  _loadSubdistricts(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Subdistrict
          _buildLocationDropdown(
            'ตำบล/แขวง',
            _selectedSubdistrictId ?? '',
            _subdistricts,
            (value) {
              setState(() {
                _selectedSubdistrictId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Postal Code
          _buildTextField(
            'รหัสไปรษณีย์',
            _postalCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Country
          _buildTextField(
            'ประเทศ',
            _countryController,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown(
    String label,
    String selectedId,
    List<Map<String, dynamic>> options,
    Function(String?) onChanged,
  ) {
    // Find the valid selected value or set to null
    String? validValue;
    if (selectedId.isNotEmpty) {
      final exists = options.any((option) => option['id'] == selectedId);
      if (exists) {
        validValue = selectedId;
      }
    }

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
          DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: Text('เลือก$label'),
            items: options
                .where((option) => option['id'] != null && option['name_th'] != null)
                .map((option) {
              return DropdownMenuItem<String>(
                value: option['id'] as String,
                child: Text(option['name_th'] as String),
              );
            }).toList(),
            onChanged: onChanged,
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

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Convert selected hashtags to object format for storage
        final hashtagObjects = _selectedHashtags.map((hashtagId) {
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
        }).toList();
        
        // Convert emails and phones to object format for storage
        final emailsObjects = _emails
            .where((email) => email['value']?.isNotEmpty == true)
            .map((email) => {
              'id': email['id'] as String? ?? 'email-initial',
              'label': email['label'] as String? ?? 'Work',
              'value': email['value'] as String? ?? '',
            })
            .toList();
        
        final phonesObjects = _phones
            .where((phone) => phone['value']?.isNotEmpty == true)
            .map((phone) => {
              'id': phone['id'] as String? ?? 'phone-initial',
              'label': phone['label'] as String? ?? 'Work',
              'value': phone['value'] as String? ?? '',
            })
            .toList();

        // Get workspace ID from controller
        final controller = Get.find<CustomersController>();
        final workspaceId = controller.currentWorkspaceId.value;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
        
        if (workspaceId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถบันทึกข้อมูลได้: ไม่พบ Workspace'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Generate customer ID for new customers or use existing one for edit
        String customerId;
        if (widget.customer != null) {
          // Edit mode - use the custom ID from the field
          customerId = _customIdController.text.trim();
        } else {
          // Add mode - generate new ID
          customerId = await _generateCustomId();
        }
        
        // Create customer object
        final customer = Customer(
          id: widget.customer?.id ?? '', // Empty for new customer
          name: _nameController.text.trim(),
          prefix: _prefixController.text.trim(),
          gender: _selectedGender,
          age: '25', // TODO: Add age field to form
          customerType: _selectedCustomerType,
          emails: emailsObjects,
          phones: phonesObjects,
          companyNames: _selectedCompanies.map((company) => company.companyNames).expand((names) => names).toList(),
          nationalId: _nationalIdController.text.trim(),
          address: _addressLine1Controller.text.trim(),
          source: _selectedSource,
          hashtags: hashtagObjects,
          assignees: _selectedAssignees,
          customId: customerId,
          workspaceId: workspaceId, // Dynamic workspace ID
          createdAt: widget.customer?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.customer?.createdBy ?? userId, // TODO: Get from auth
          updatedBy: userId, // Use customer ID when editing, fallback for new customers
        );

        if (widget.customer != null) {
          // Update existing customer
          await controller.updateCustomer(workspaceId, customer);
        } else {
          // Add new customer
          await controller.addCustomer(workspaceId, customer);
        }

        // Close loading dialog
        Navigator.pop(context);

        // If controller recorded an error (e.g., permission denied), show it and stop
        if (controller.errorMessage.value.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.errorMessage.value),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customer != null 
                ? 'อัปเดตข้อมูลลูกค้าเรียบร้อยแล้ว'
                : 'เพิ่มลูกค้าใหม่เรียบร้อยแล้ว'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Pop with result to trigger refresh in detail page
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

  Future<String> _generateCustomId() async {
    try {
      // Get workspace ID from controller
      final controller = Get.find<CustomersController>();
      final workspaceId = controller.currentWorkspaceId.value;
      
      if (workspaceId.isEmpty) {
        print('⚠️ No workspace ID available for ID generation, using fallback');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return 'CUST$timestamp';
      }
      
      // Generate customer ID using the service
      final customerId = await _idGenerationService.generateCustomerId(workspaceId);
      print('✅ Generated customer ID: $customerId');
      return customerId;
    } catch (e) {
      print('❌ Error generating customer ID: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'CUST$timestamp';
    }
  }
}
