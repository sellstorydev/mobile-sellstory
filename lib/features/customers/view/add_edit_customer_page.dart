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
import '../../../core/widgets/permission_guard.dart';

class AddEditCustomerPage extends StatefulWidget {
  final Customer? customer;
  final List<String> customerSources;

  const AddEditCustomerPage({super.key, this.customer, required this.customerSources});

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prefixController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _customIdController = TextEditingController();

  final HashtagService _hashtagService = HashtagService();
  final WorkspaceMembersService _workspaceMembersService = Get.find<WorkspaceMembersService>();
  final IdGenerationService _idService = Get.find<IdGenerationService>();

  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtags = [];
  bool _isLoadingHashtags = true;

  List<WorkspaceMember> _availableMembers = [];
  List<String> _selectedAssignees = [];
  bool _isLoadingMembers = true;

  List<Company> _selectedCompanies = [];

  String _selectedGender = 'Female';
  String _selectedCustomerType = 'Customer';
  String _selectedSource = '';

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subdistricts = [];
  String? _selectedProvinceId;
  String? _selectedDistrictId;
  String? _selectedSubdistrictId;

  List<Map<String, String>> _emails = [];
  List<Map<String, String>> _phones = [];

  final List<String> _genderOptions = ['Female', 'Male', 'Other'];
  final List<String> _customerTypeOptions = ['Lead', 'Customer'];

  @override
  void initState() {
    super.initState();
    _initForm();
    _loadHashtags();
    _loadMembers();
    _loadProvinces();
  }


  void _initForm() {
    final c = widget.customer;
    if (c != null) {
      _nameController.text = c.name;
      _prefixController.text = c.prefix;
      _nationalIdController.text = c.nationalId;
      _addressController.text = c.address;
      _customIdController.text = c.customId;
      if (_genderOptions.contains(c.gender)) _selectedGender = c.gender;
      if (_customerTypeOptions.contains(c.customerType)) _selectedCustomerType = c.customerType;
      _selectedSource = c.source;
      _selectedAssignees = List<String>.from(c.assignees);
      _selectedHashtags = c.hashtags.map((h) => (h['id'] ?? '').toString()).where((id) => id.isNotEmpty).toList();

      _emails = c.emails
          .map((e) => {
                'id': (e['id'] ?? 'email-initial').toString(),
                'label': (e['label'] ?? 'Work').toString(),
                'value': (e['value'] ?? '').toString(),
              })
          .toList();
      _phones = c.phones
          .map((p) => {
                'id': (p['id'] ?? 'phone-initial').toString(),
                'label': (p['label'] ?? 'Work').toString(),
                'value': (p['value'] ?? '').toString(),
              })
          .toList();
      if (_emails.isEmpty) _emails = [{'id': 'email-initial', 'label': 'Work', 'value': ''}];
      if (_phones.isEmpty) _phones = [{'id': 'phone-initial', 'label': 'Work', 'value': ''}];

      if (c.companyNames.isNotEmpty) {
        _selectedCompanies = c.companyNames.map((m) {
          return Company(
            id: (m['id'] ?? '').toString(),
            companyNames: [
              {
                'id': (m['id'] ?? '').toString(),
                'label': (m['label'] ?? 'Main').toString(),
                'value': (m['value'] ?? '').toString(),
              }
            ],
            customId: '',
            emails: const [],
            phones: const [],
            taxId: '',
            branch: (m['label'] ?? '').toString(),
            addressLine1: '',
            subdistrict: '',
            district: '',
            province: '',
            postalCode: '',
            country: '',
            hashtags: const [],
            website: '',
            workspaceId: c.workspaceId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: c.createdBy,
            updatedBy: c.updatedBy,
            associatedCustomerIds: const [],
          );
        }).toList();
      }
    } else {
      _emails = [
        {'id': 'email-initial', 'label': 'Work', 'value': ''}
      ];
      _phones = [
        {'id': 'phone-initial', 'label': 'Work', 'value': ''}
      ];
      _selectedSource = widget.customerSources.isNotEmpty ? widget.customerSources.first : '';
    }
  }

  Future<void> _loadHashtags() async {
    try {
      final controller = Get.find<CustomersController>();
      final workspaceId = controller.currentWorkspaceId.value;
      if (workspaceId.isEmpty) {
        setState(() => _isLoadingHashtags = false);
        return;
      }
      final tags = await _hashtagService.getHashtagsByScope(workspaceId, 'customer');
      setState(() {
        _availableHashtags = tags;
        _isLoadingHashtags = false;
      });
    } catch (_) {
      setState(() => _isLoadingHashtags = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final controller = Get.find<CustomersController>();
      final workspaceId = controller.currentWorkspaceId.value;
      if (workspaceId.isEmpty) {
        setState(() => _isLoadingMembers = false);
        return;
      }
      final members = await _workspaceMembersService.getAssignableMembers(workspaceId);
      setState(() {
        _availableMembers = members;
        _isLoadingMembers = false;
      });
    } catch (_) {
      setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await ThaiLocationService().getProvinces();
      setState(() => _provinces = provinces);
    } catch (_) {}
  }

  Future<void> _loadDistricts(String provinceId) async {
    setState(() {
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _districts.clear();
      _subdistricts.clear();
    });
    try {
      final ds = await ThaiLocationService().getDistrictsByProvince(provinceId);
      setState(() => _districts = ds);
    } catch (_) {}
  }

  Future<void> _loadSubdistricts(String districtId) async {
    setState(() {
      _selectedSubdistrictId = null;
      _subdistricts.clear();
    });
    try {
      final sd = await ThaiLocationService().getSubdistrictsByDistrict(districtId);
      setState(() => _subdistricts = sd);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _customIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(widget.customer != null ? 'แก้ไขรายละเอียดลูกค้า' : 'เพิ่มลูกค้า'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final needed = widget.customer != null ? 'customer:edit:all' : 'customer:create';
              guardAction(context, needed, _saveCustomer);
            },
            child: const Text('บันทึก', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader('แชร์กับผู้อื่น', isRequired: true, trailing: _addButton(onPressed: () {})),
              const SizedBox(height: 8),
              AssigneesInputField(
                selectedAssignees: _selectedAssignees,
                availableMembers: _availableMembers,
                onAssigneesChanged: (v) => setState(() => _selectedAssignees = v),
                isLoading: _isLoadingMembers,
              ),
              const SizedBox(height: 16),
              _buildSectionDivider(),
              const SizedBox(height: 16),
              _buildSectionHeader('ข้อมูลส่วนบุคคล'),
              const SizedBox(height: 12),
              _buildAvatarPlaceholder(),
              const SizedBox(height: 16),
              _buildCustomerTypeSegmented(),
              const SizedBox(height: 16),
              if (_isLoadingHashtags)
                const Center(child: CircularProgressIndicator())
              else
                HashtagInputField(
                  selectedHashtags: _selectedHashtags,
                  availableHashtags: _availableHashtags,
                  onHashtagsChanged: (v) => setState(() => _selectedHashtags = v),
                  label: 'Hashtag',
                  hintText: 'กรุณากรอก Hashtag',
                ),
              const SizedBox(height: 16),
              _buildDropdownField('แหล่งที่มาลูกค้า', _selectedSource, widget.customerSources, (v) => setState(() => _selectedSource = v ?? '')),
              const SizedBox(height: 16),
              _buildTextField('ชื่อ-นามสกุล', _nameController, isRequired: true),
              const SizedBox(height: 16),
              _buildDropdownField('เพศ', _selectedGender, _genderOptions, (v) => setState(() => _selectedGender = v ?? _selectedGender)),
              const SizedBox(height: 16),
              _buildMultipleEmailsSection(),
              const SizedBox(height: 16),
              _buildMultiplePhonesSection(),
              const SizedBox(height: 16),
              _buildTextField('ที่อยู่', _addressController, maxLines: 3),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildSectionDivider(),
              const SizedBox(height: 16),
              _buildSectionHeader('ข้อมูลบริษัท', trailing: _addButton(onPressed: () {})),
              const SizedBox(height: 12),
              CompanyPicker(
                selectedCompanies: _selectedCompanies,
                onCompaniesChanged: (companies) => setState(() => _selectedCompanies = companies),
                label: 'บริษัท',
                hintText: 'เลือกบริษัท',
              ),
              const SizedBox(height: 16),
              _buildCustomIdField(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final needed = widget.customer != null ? 'customer:edit:all' : 'customer:create';
                guardAction(context, needed, _saveCustomer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ถัดไป', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  // ===== UI helpers =====
  Widget _addButton({required VoidCallback onPressed}) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, color: AppTheme.primaryOrange, size: 18),
        label: const Text('เพิ่ม', style: TextStyle(color: AppTheme.primaryOrange)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.primaryOrange),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
      );

  Widget _buildSectionHeader(String title, {bool isRequired = false, Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              if (isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSectionDivider() => Container(
        height: 8,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      );

  Widget _buildAvatarPlaceholder() => Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 28, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildCustomerTypeSegmented() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ประเภท', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _segButton('ลีด', _selectedCustomerType == 'Lead', () => setState(() => _selectedCustomerType = 'Lead'))),
          const SizedBox(width: 8),
          Expanded(child: _segButton('ลูกค้า', _selectedCustomerType == 'Customer', () => setState(() => _selectedCustomerType = 'Customer'))),
        ]),
      ]),
    );
  }

  Widget _segButton(String label, bool selected, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryOrange : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryOrange),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.primaryOrange, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          if (isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (v) {
            if (isRequired && (v == null || v.trim().isEmpty)) return 'จำเป็นต้องกรอก';
            return null;
          },
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
      ]),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    final hasValue = options.contains(value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: hasValue ? value : null,
          items: options.map((o) => DropdownMenuItem<String>(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          hint: Text('เลือก$label'),
        ),
      ]),
    );
  }

  Widget _buildMultipleEmailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('อีเมล', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          const Spacer(),
          _addButton(onPressed: _addEmail),
        ]),
        const SizedBox(height: 8),
        ..._emails.asMap().entries.map((entry) {
          final i = entry.key;
          final email = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: email['label'],
                  decoration: const InputDecoration(labelText: 'ประเภท', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => email['label'] = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: email['value'],
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'อีเมล', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => email['value'] = v,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _emails.length > 1 ? () => _removeEmail(i) : null,
                icon: Icon(Icons.delete, color: _emails.length > 1 ? Colors.red : Colors.grey),
                tooltip: 'ลบอีเมล',
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildMultiplePhonesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('เบอร์โทรศัพท์', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          const Spacer(),
          _addButton(onPressed: _addPhone),
        ]),
        const SizedBox(height: 8),
        ..._phones.asMap().entries.map((entry) {
          final i = entry.key;
          final phone = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: phone['label'],
                  decoration: const InputDecoration(labelText: 'ประเภท', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => phone['label'] = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: phone['value'],
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'เบอร์โทร', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => phone['value'] = v,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _phones.length > 1 ? () => _removePhone(i) : null,
                icon: Icon(Icons.delete, color: _phones.length > 1 ? Colors.red : Colors.grey),
                tooltip: 'ลบเบอร์โทร',
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ที่อยู่', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        _buildLocationDropdown('จังหวัด', _selectedProvinceId, _provinces, (v) {
          setState(() {
            _selectedProvinceId = v;
            if (v != null) _loadDistricts(v);
          });
        }),
        const SizedBox(height: 16),
        _buildLocationDropdown('อำเภอ/เขต', _selectedDistrictId, _districts, (v) {
          setState(() {
            _selectedDistrictId = v;
            if (v != null) _loadSubdistricts(v);
          });
        }),
        const SizedBox(height: 16),
        _buildLocationDropdown('ตำบล/แขวง', _selectedSubdistrictId, _subdistricts, (v) => setState(() => _selectedSubdistrictId = v)),
        const SizedBox(height: 16),
        _buildTextField('รหัสไปรษณีย์', TextEditingController(), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField('ประเทศ', TextEditingController()),
      ]),
    );
  }

  Widget _buildLocationDropdown(String label, String? selectedId, List<Map<String, dynamic>> options, ValueChanged<String?> onChanged) {
    String? validValue;
    if (selectedId != null && options.any((o) => o['id'] == selectedId)) {
      validValue = selectedId;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: validValue,
        items: options
            .where((o) => o['id'] != null && o['name_th'] != null)
            .map((o) => DropdownMenuItem<String>(value: o['id'] as String, child: Text(o['name_th'] as String)))
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        hint: Text('เลือก$label'),
      )
    ]);
  }

  Widget _buildCustomIdField() {
    final isEdit = widget.customer != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('รหัสลูกค้า', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _customIdController,
          enabled: isEdit,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: isEdit ? null : 'จะถูกสร้างอัตโนมัติเมื่อบันทึก',
          ),
        ),
      ]),
    );
  }

  // ===== Save handlers =====
  void _addEmail() {
    setState(() => _emails.add({'id': 'email-${DateTime.now().millisecondsSinceEpoch}', 'label': 'Work', 'value': ''}));
  }

  void _removeEmail(int index) {
    setState(() => _emails.removeAt(index));
  }

  void _addPhone() {
    setState(() => _phones.add({'id': 'phone-${DateTime.now().millisecondsSinceEpoch}', 'label': 'Work', 'value': ''}));
  }

  void _removePhone(int index) {
    setState(() => _phones.removeAt(index));
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      final hashtagObjects = _selectedHashtags.map((id) {
        final idx = _availableHashtags.indexWhere((h) => h.id == id);
        final found = idx >= 0 ? _availableHashtags[idx] : null;
        return {'color': found?.color ?? '#ef4444', 'id': id, 'text': found?.name ?? id};
      }).toList();

      final emailsObjects = _emails
          .where((e) => (e['value'] ?? '').trim().isNotEmpty)
          .map((e) => {'id': e['id'] ?? 'email-initial', 'label': e['label'] ?? 'Work', 'value': e['value'] ?? ''})
          .toList();
      final phonesObjects = _phones
          .where((p) => (p['value'] ?? '').trim().isNotEmpty)
          .map((p) => {'id': p['id'] ?? 'phone-initial', 'label': p['label'] ?? 'Work', 'value': p['value'] ?? ''})
          .toList();

      final controller = Get.find<CustomersController>();
      final workspaceId = controller.currentWorkspaceId.value;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (workspaceId.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบ Workspace'), backgroundColor: Colors.red));
        return;
      }

      final customId = widget.customer == null ? await _generateCustomerId(workspaceId) : _customIdController.text.trim();

      final customer = Customer(
        id: widget.customer?.id ?? '',
        name: _nameController.text.trim(),
        prefix: _prefixController.text.trim(),
        gender: _selectedGender,
        age: '0',
        customerType: _selectedCustomerType,
        emails: emailsObjects,
        phones: phonesObjects,
        companyNames: _selectedCompanies
            .map((c) => {
                  'id': c.id,
                  'label': c.branch.isNotEmpty ? c.branch : 'Main',
                  'value': c.companyNames.isNotEmpty ? (c.companyNames.first['value']?.toString() ?? '') : '',
                })
            .toList(),
        nationalId: _nationalIdController.text.trim(),
        address: _addressController.text.trim(),
        source: _selectedSource,
        hashtags: hashtagObjects,
        assignees: _selectedAssignees,
        customId: customId,
        workspaceId: workspaceId,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.customer?.createdBy ?? userId,
        updatedBy: userId,
      );

      if (widget.customer == null) {
        await controller.addCustomer(workspaceId, customer);
      } else {
        await controller.updateCustomer(workspaceId, customer);
      }

      Navigator.pop(context);

      if (controller.errorMessage.value.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage.value), backgroundColor: Colors.red));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.customer == null ? 'เพิ่มลูกค้าใหม่เรียบร้อยแล้ว' : 'อัปเดตข้อมูลลูกค้าเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ));

      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
    }
  }

  Future<String> _generateCustomerId(String workspaceId) async {
    try {
      return await _idService.generateCustomerId(workspaceId);
    } catch (_) {
      return 'CUST${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
