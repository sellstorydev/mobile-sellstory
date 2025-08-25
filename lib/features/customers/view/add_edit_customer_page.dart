import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/services/hashtag_service.dart';
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
  
  // Hashtag related
  final HashtagService _hashtagService = HashtagService();
  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtags = [];
  bool _isLoadingHashtags = true;
  
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
    _loadHashtags();
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

  void _initializeForm() {
    if (widget.customer != null) {
      // Edit mode - populate with existing data
      final customer = widget.customer!;
      _nameController.text = customer.name;
      _prefixController.text = customer.prefix;
      _nationalIdController.text = customer.nationalId;
      _addressLine1Controller.text = customer.address;
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
      
      _selectedGender = _getSafeDropdownValue(customer.gender, _genderOptions);
      _selectedCustomerType = _getSafeDropdownValue(customer.customerType, _customerTypeOptions);
      _selectedSource = _getSafeDropdownValue(customer.source, widget.customerSources.isNotEmpty ? widget.customerSources : []);
      
      // Set location fields with fallback to default values if empty
      _selectedDistrict = _districtOptions.first;
      _selectedProvince = _provinceOptions.first;
      _selectedSubdistrict = _subdistrictOptions.first;
      
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
        
        if (workspaceId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถบันทึกข้อมูลได้: ไม่พบ Workspace'),
              backgroundColor: Colors.red,
            ),
          );
          return;
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
          companyNames: [], // TODO: Add company field to form
          nationalId: _nationalIdController.text.trim(),
          address: _addressLine1Controller.text.trim(),
          source: _selectedSource,
          hashtags: hashtagObjects,
          assignees: [], // TODO: Add assignees field to form
          customId: widget.customer?.customId ?? _generateCustomId(),
          workspaceId: workspaceId, // Dynamic workspace ID
          createdAt: widget.customer?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.customer?.createdBy ?? 'current-user', // TODO: Get from auth
          updatedBy: 'current-user', // TODO: Get from auth
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
        
        Navigator.pop(context);
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

  String _generateCustomId() {
    // Generate a simple custom ID with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CUST$timestamp';
  }
}
