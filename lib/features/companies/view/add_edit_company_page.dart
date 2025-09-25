import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/company.dart';
import '../controller/companies_controller.dart';
import '../../../core/services/thai_location_service.dart';
import '../../../core/widgets/permission_guard.dart';

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
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  late final CompaniesController _controller; // was direct Get.find, now late + safe init
  final ThaiLocationService _locationService = ThaiLocationService();


  // Thai Location dropdowns
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subdistricts = [];

  String? _selectedProvinceId;
  String? _selectedDistrictId;
  String? _selectedSubdistrictId;

  // Remove unused loading flag and add submitting state
  bool _isSubmitting = false;

  // Multiple emails and phones
  List<Map<String, String>> _emails = [];
  List<Map<String, String>> _phones = [];

  bool get _isEditMode => widget.company != null;

  @override
  void initState() {
    super.initState();
    // Safe controller acquisition
    if (Get.isRegistered<CompaniesController>()) {
      _controller = Get.find<CompaniesController>();
    } else {
      _controller = Get.put(CompaniesController());
    }
    _loadProvinces();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final company = widget.company!;
      _nameController.text = company.name;
      _taxIdController.text = company.taxId;
      _branchController.text = company.branch;
      _addressLine1Controller.text = company.addressLine1;
      _websiteController.text = company.website;
      _postalCodeController.text = company.postalCode;
      _countryController.text = company.country;

      // Initialize emails and phones
      _emails = company.emails.map((e) => {
        'label': e['label']?.toString() ?? '',
        'value': e['value']?.toString() ?? '',
      }).toList();

      _phones = company.phones.map((p) => {
        'label': p['label']?.toString() ?? '',
        'value': p['value']?.toString() ?? '',
      }).toList();

      // Attempt preselect after provinces are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preselectLocationFromCompany();
      });
    } else {
      // Initialize with default empty entries
      _emails = [{'label': 'main_label'.tr, 'value': ''}];
      _phones = [{'label': 'main_label'.tr, 'value': ''}];
      _countryController.text = 'thailand'.tr;
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await _locationService.getProvinces();
      setState(() {
        _provinces = provinces;
      });
      // If editing, try to preselect once provinces are available
      if (_isEditMode) {
        await _preselectLocationFromCompany();
      }
    } catch (_) {}
  }

  // NEW: preselect province/district/subdistrict by matching names from existing company
  Future<void> _preselectLocationFromCompany() async {
    if (!_isEditMode || _provinces.isEmpty) return;
    final c = widget.company!;
    try {
      // Province by name
      if (c.province.isNotEmpty) {
        final prov = _provinces.firstWhere(
          (p) => (p['name_th']?.toString() ?? '') == c.province,
          orElse: () => {},
        );
        if (prov.isNotEmpty) {
          final provId = prov['id']?.toString();
          if (provId != null && provId.isNotEmpty) {
            setState(() => _selectedProvinceId = provId);
            final districts = await _locationService.getDistrictsByProvince(provId);
            if (!mounted) return;
            setState(() => _districts = districts);
          }
        }
      }
      // District by name
      if (c.district.isNotEmpty && _districts.isNotEmpty) {
        final dist = _districts.firstWhere(
          (d) => (d['name_th']?.toString() ?? '') == c.district,
          orElse: () => {},
        );
        if (dist.isNotEmpty) {
          final distId = dist['id']?.toString();
          if (distId != null && distId.isNotEmpty) {
            setState(() => _selectedDistrictId = distId);
            final subs = await _locationService.getSubdistrictsByDistrict(distId);
            if (!mounted) return;
            setState(() => _subdistricts = subs);
          }
        }
      }
      // Subdistrict by name
      if (c.subdistrict.isNotEmpty && _subdistricts.isNotEmpty) {
        final sub = _subdistricts.firstWhere(
          (s) => (s['name_th']?.toString() ?? '') == c.subdistrict,
          orElse: () => {},
        );
        if (sub.isNotEmpty) {
          final subId = sub['id']?.toString();
          if (subId != null && subId.isNotEmpty) {
            setState(() => _selectedSubdistrictId = subId);
            // Auto-fill postal code if empty
            if (_postalCodeController.text.trim().isEmpty) {
              final zip = await _locationService.getPostalCodeBySubdistrict(subId);
              if (zip != null && mounted) {
                setState(() => _postalCodeController.text = zip);
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadDistricts(String provinceId) async {
    try {
      final districts = await _locationService.getDistrictsByProvince(provinceId);
      setState(() {
        _districts = districts;
        _subdistricts = [];
        _selectedDistrictId = null;
        _selectedSubdistrictId = null;
      });
    } catch (_) {}
  }

  Future<void> _loadSubdistricts(String districtId) async {
    try {
      final subdistricts = await _locationService.getSubdistrictsByDistrict(districtId);
      setState(() {
        _subdistricts = subdistricts;
        _selectedSubdistrictId = null;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _isEditMode ? 'edit_company'.tr : 'add_company'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    final needed = _isEditMode ? 'company:edit:all' : 'company:create';
                    guardAction(context, needed, _submitForm);
                  },
            child: Text(
              _isEditMode ? 'save_company'.tr : 'add_company_button'.tr,
              style: TextStyle(
                color: _isSubmitting ? Colors.grey : AppTheme.primaryOrange,
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
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildContactSection(),
              const SizedBox(height: 16),
              _buildAddressSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'ข้อมูลพื้นฐาน',
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'ชื่อบริษัท *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกชื่อบริษัท';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _branchController,
          label: 'สาขา',
          hint: 'เช่น สำนักงานใหญ่, สาขาบางนา',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _taxIdController,
          label: 'เลขประจำตัวผู้เสียภาษี',
          hint: 'เช่น 0123456789012',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _websiteController,
          label: 'เว็บไซต์',
          hint: 'เช่น www.company.com',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'ข้อมูลติดต่อ',
      children: [
        _buildMultipleContactFields(
          title: 'อีเมล',
          contacts: _emails,
          onAdd: () => setState(() => _emails.add({'label': '', 'value': ''})),
          onRemove: (index) => setState(() => _emails.removeAt(index)),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildMultipleContactFields(
          title: 'เบอร์โทร',
          contacts: _phones,
          onAdd: () => setState(() => _phones.add({'label': '', 'value': ''})),
          onRemove: (index) => setState(() => _phones.removeAt(index)),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _buildSection(
      title: 'ที่อยู่',
      children: [
        _buildTextField(
          controller: _addressLine1Controller,
          label: 'ที่อยู่',
          hint: 'เลขที่, หมู่, ซอย, ถนน',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildLocationDropdowns(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _postalCodeController,
                label: 'รหัสไปรษณีย์',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _countryController,
                label: 'ประเทศ',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryOrange),
        ),
      ),
    );
  }

  Widget _buildMultipleContactFields({
    required String title,
    required List<Map<String, String>> contacts,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
              tooltip: 'เพิ่ม$title',
            ),
          ],
        ),
        ...contacts.asMap().entries.map((entry) {
          final index = entry.key;
          final contact = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: contact['label'],
                    onChanged: (value) => contact['label'] = value,
                    decoration: InputDecoration(
                      labelText: 'ป้ายกำกับ',
                      hintText: 'เช่น หลัก, ติดต่อ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: contact['value'],
                    onChanged: (value) => contact['value'] = value,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      labelText: title,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: contacts.length > 1 ? () => onRemove(index) : null,
                  icon: Icon(
                    Icons.remove_circle,
                    color: contacts.length > 1 ? Colors.red : Colors.grey,
                  ),
                  tooltip: 'ลบ',
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLocationDropdowns() {
    return Column(
      children: [
        // Province dropdown
        DropdownButtonFormField<String>(
          value: _selectedProvinceId,
          decoration: InputDecoration(
            labelText: 'จังหวัด',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _provinces.map((province) {
            return DropdownMenuItem<String>(
              value: province['id'],
              child: Text(province['name_th']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvinceId = value;
            });
            if (value != null) {
              _loadDistricts(value);
            }
          },
        ),
        const SizedBox(height: 16),
        // District dropdown
        DropdownButtonFormField<String>(
          value: _selectedDistrictId,
          decoration: InputDecoration(
            labelText: 'อำเภอ/เขต',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _districts.map((district) {
            return DropdownMenuItem<String>(
              value: district['id'],
              child: Text(district['name_th']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDistrictId = value;
            });
            if (value != null) {
              _loadSubdistricts(value);
            }
          },
        ),
        const SizedBox(height: 16),
        // Subdistrict dropdown
        DropdownButtonFormField<String>(
          value: _selectedSubdistrictId,
          decoration: InputDecoration(
            labelText: 'ตำบล/แขวง',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _subdistricts.map((subdistrict) {
            return DropdownMenuItem<String>(
              value: subdistrict['id'],
              child: Text(subdistrict['name_th']),
            );
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedSubdistrictId = value;
            });
            if (value != null) {
              final zip = await _locationService.getPostalCodeBySubdistrict(value);
              if (zip != null && mounted) {
                setState(() {
                  _postalCodeController.text = zip;
                });
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get province, district, subdistrict names
      String provinceName = '';
      String districtName = '';
      String subdistrictName = '';

      if (_selectedProvinceId != null) {
        final province = _provinces.firstWhere(
          (p) => p['id'] == _selectedProvinceId,
          orElse: () => {},
        );
        provinceName = province['name_th'] ?? '';
      }

      if (_selectedDistrictId != null) {
        final district = _districts.firstWhere(
          (d) => d['id'] == _selectedDistrictId,
          orElse: () => {},
        );
        districtName = district['name_th'] ?? '';
      }

      if (_selectedSubdistrictId != null) {
        final subdistrict = _subdistricts.firstWhere(
          (s) => s['id'] == _selectedSubdistrictId,
          orElse: () => {},
        );
        subdistrictName = subdistrict['name_th'] ?? '';
      }

      // Preserve existing names on edit when no new selection
      if (_isEditMode) {
        final prev = widget.company!;
        if (provinceName.isEmpty) provinceName = prev.province;
        if (districtName.isEmpty) districtName = prev.district;
        if (subdistrictName.isEmpty) subdistrictName = prev.subdistrict;
      }

      // Filter out empty contacts
      final validEmails = _emails
          .where((e) => e['value']?.isNotEmpty == true)
          .map((e) => {
                'label': e['label'] ?? '',
                'value': e['value'] ?? '',
              })
          .toList();

      final validPhones = _phones
          .where((p) => p['value']?.isNotEmpty == true)
          .map((p) => {
                'label': p['label'] ?? '',
                'value': p['value'] ?? '',
              })
          .toList();

      final company = Company(
        id: _isEditMode ? widget.company!.id : '',
        name: _nameController.text.trim(),
        branch: _branchController.text.trim(),
        taxId: _taxIdController.text.trim(),
        emails: validEmails,
        phones: validPhones,
        website: _websiteController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        province: provinceName,
        district: districtName,
        subdistrict: subdistrictName,
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        workspaceId: _controller.currentWorkspaceId.value,
        customId: _isEditMode ? widget.company!.customId : '',
        createdAt: _isEditMode ? widget.company!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: _isEditMode ? widget.company!.createdBy : '',
        updatedBy: '',
        associatedCustomerIds: _isEditMode ? widget.company!.associatedCustomerIds : [],
      );

      bool success;
      if (_isEditMode) {
        success = await _controller.updateCompany(company);
      } else {
        success = await _controller.createCompany(company);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage.value),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _branchController.dispose();
    _addressLine1Controller.dispose();
    _websiteController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
