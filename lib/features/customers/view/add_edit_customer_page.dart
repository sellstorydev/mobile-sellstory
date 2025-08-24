import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';

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
  
  String _selectedGender = 'Male';
  String _selectedCustomerType = 'Customer';
  String _selectedSource = 'FB';
  
  // Location fields
  String _selectedDistrict = 'บางเขน';
  String _selectedProvince = 'กรุงเทพมหานคร';
  String _selectedSubdistrict = 'อนุสาวรีย์';
  String _selectedCountry = 'ไทย';
  String _postalCode = '';
  
  // Multiple emails and phones
  List<Map<String, String>> _emails = [];
  List<Map<String, String>> _phones = [];
  
  // Available options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _customerTypeOptions = ['Customer', 'Lead'];
  final List<String> _districtOptions = ['บางเขน', 'ลาดพร้าว', 'ห้วยขวาง', 'ดินแดง', 'วัฒนา'];
  final List<String> _provinceOptions = ['กรุงเทพมหานคร', 'นนทบุรี', 'ปทุมธานี', 'สมุทรปราการ'];
  final List<String> _subdistrictOptions = ['อนุสาวรีย์', 'ลาดยาว', 'เสนานิคม', 'จันทรเกษม'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  String _getSafeDropdownValue(String value, List<String> options) {
    if (options.contains(value)) {
      return value;
    }
    return options.isNotEmpty ? options.first : '';
  }

  void _initializeForm() {
    if (widget.customer != null) {
      // Edit mode - populate with existing data
      final customer = widget.customer!;
      _nameController.text = customer.name;
      _prefixController.text = customer.prefix;
      _nationalIdController.text = customer.nationalId;
      _addressLine1Controller.text = customer.address;
      _hashtagsController.text = customer.hashtags;
      
      _selectedGender = _getSafeDropdownValue(customer.gender, _genderOptions);
      _selectedCustomerType = _getSafeDropdownValue(customer.customerType, _customerTypeOptions);
      _selectedSource = _getSafeDropdownValue(customer.source, widget.customerSources.isNotEmpty ? widget.customerSources : ['FB', 'Line', 'IG']);
      
      // Set location fields with fallback to default values if empty
      _selectedDistrict = _districtOptions.first;
      _selectedProvince = _provinceOptions.first;
      _selectedSubdistrict = _subdistrictOptions.first;
      
      // Parse emails and phones from string format
      if (customer.emails.isNotEmpty) {
        _emails = [
          {'id': 'email-1', 'label': 'Work', 'value': customer.emails}
        ];
      }
      
      if (customer.phones.isNotEmpty) {
        _phones = [
          {'id': 'phone-1', 'label': 'Work', 'value': customer.phones}
        ];
      }
    } else {
      // Add mode - initialize with default values
      _emails = [
        {'id': 'email-initial', 'label': 'Work', 'value': ''}
      ];
      _phones = [
        {'id': 'phone-initial', 'label': 'Work', 'value': ''}
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    _nationalIdController.dispose();
    _addressLine1Controller.dispose();
    _hashtagsController.dispose();
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
            onPressed: _saveCustomer,
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
              // Assignees (Coming Soon)
              _buildComingSoonField('เซลที่รับผิดชอบ', 'assignees'),
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
              
              // Hashtags (Coming Soon)
              _buildComingSoonField('แฮชแท็ก', 'hashtags'),
              const SizedBox(height: 16),
              
              // Source
              _buildDropdownField(
                'แหล่งที่มา',
                _selectedSource,
                widget.customerSources.isNotEmpty ? widget.customerSources : ['FB', 'Line', 'IG'],
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
              
              // Company (Coming Soon)
              _buildComingSoonField('บริษัท', 'company'),
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
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
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
          
          // Subdistrict
          _buildDropdownField(
            'ตำบล/แขวง',
            _selectedSubdistrict,
            _subdistrictOptions,
            (value) => setState(() => _selectedSubdistrict = value!),
          ),
          const SizedBox(height: 16),
          
          // District
          _buildDropdownField(
            'อำเภอ/เขต',
            _selectedDistrict,
            _districtOptions,
            (value) => setState(() => _selectedDistrict = value!),
          ),
          const SizedBox(height: 16),
          
          // Province
          _buildDropdownField(
            'จังหวัด',
            _selectedProvince,
            _provinceOptions,
            (value) => setState(() => _selectedProvince = value!),
          ),
          const SizedBox(height: 16),
          
          // Postal Code
          Container(
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
                  'รหัสไปรษณีย์',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _postalCode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _postalCode = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Country
          _buildDropdownField(
            'ประเทศ',
            _selectedCountry,
            ['ไทย', 'สหรัฐอเมริกา', 'จีน', 'ญี่ปุ่น'],
            (value) => setState(() => _selectedCountry = value!),
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

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลลูกค้าเรียบร้อยแล้ว')),
      );
      Navigator.pop(context);
    }
  }
}
