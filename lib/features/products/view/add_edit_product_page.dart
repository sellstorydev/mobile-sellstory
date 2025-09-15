import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/services/id_generation_service.dart';
import '../../../domain/entities/product.dart';
import '../controller/products_controller.dart';
import '../../../core/widgets/permission_guard.dart';

class AddEditProductPage extends StatefulWidget {
  final Product? product; // null for add, not null for edit
  final Map<String, dynamic>? templateContext; // Template context if used in template
  final double? remainingQuantity; // Remaining quantity limit if applicable

  const AddEditProductPage({
    super.key, 
    this.product,
    this.templateContext,
    this.remainingQuantity,
  });

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Hashtag related
  final HashtagService _hashtagService = HashtagService();
  final IdGenerationService _idGenerationService =
      Get.find<IdGenerationService>();
  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtags = [];
  bool _isLoadingHashtags = true;

  // Product fields
  String _selectedStatus = 'draft';
  String _selectedCategory = '';
  bool _showInCatalog = true;
  String _coverImageUrl = '';
  List<String> _imageSet = [];

  // Image upload states
  bool _isUploadingCover = false;
  bool _isUploadingAdditional = false;

  // Available options
  final List<String> _statusOptions = ['draft', 'active', 'discontinued'];
  List<Map<String, String>> _availableCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadHashtags();
    _loadCategories();
  }

  // Check if template has predefined quantity column
  bool _hasQuantityColumn() {
    if (widget.templateContext == null) return false;
    
    final columns = widget.templateContext?['columns'] as List<dynamic>?;
    if (columns == null) return false;
    
    return columns.any((column) {
      return column['type'] == 'predefined' && 
             column['predefinedField'] == 'quantity';
    });
  }

  // Get quantity validation error message
  String? _getQuantityError(String? value) {
    if (!_hasQuantityColumn()) return null;
    if (widget.remainingQuantity == null) return null;
    
    if (value == null || value.trim().isEmpty) {
      return 'please_enter_quantity'.tr;
    }
    
    final inputQuantity = double.tryParse(value);
    if (inputQuantity == null || inputQuantity < 0) {
      return 'please_enter_valid_number'.tr;
    }
    
    if (inputQuantity > widget.remainingQuantity!) {
      final maxQty = widget.remainingQuantity!;
      final displayQty = maxQty.truncateToDouble() == maxQty 
          ? maxQty.toInt().toString() 
          : maxQty.toStringAsFixed(2);
      return 'quantity_exceeds_limit'.tr.replaceFirst('{limit}', displayQty);
    }
    
    return null;
  }

  Future<void> _loadHashtags() async {
    try {
      final controller = Get.find<ProductsController>();
      final workspaceId = controller.currentWorkspaceId;

      if (workspaceId.isEmpty) {
        print('⚠️ AddEditProductPage: No workspace ID available for hashtags');
        setState(() {
          _isLoadingHashtags = false;
        });
        return;
      }

      final hashtags = await _hashtagService.getHashtagsByScope(
        workspaceId,
        'product',
      );

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

  Future<void> _loadCategories() async {
    try {
      final controller = Get.find<ProductsController>();
      final workspaceId = controller.currentWorkspaceId;

      if (workspaceId.isEmpty) {
        print('⚠️ AddEditProductPage: No workspace ID available for categories');
        setState(() {
          _isLoadingCategories = false;
        });
        return;
      }

      // Get categories from Firebase
      final categories = await _getCategoriesFromFirebase(workspaceId);

      setState(() {
        _availableCategories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<List<Map<String, String>>> _getCategoriesFromFirebase(String workspaceId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final workspaceDoc = await firestore.collection('workspaces').doc(workspaceId).get();
      
      if (workspaceDoc.exists) {
        final data = workspaceDoc.data();
        final companyProfile = data?['companyProfile'] as Map<String, dynamic>?;
        final productCategories = companyProfile?['productCategories'] as List<dynamic>?;
        
        if (productCategories != null) {
          return productCategories.map((category) {
            final categoryMap = category as Map<String, dynamic>;
            return {
              'id': categoryMap['id'] as String,
              'name': categoryMap['name'] as String,
            };
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching categories from Firebase: $e');
      return [];
    }
  }

  void _initializeForm() {
    if (widget.product != null) {
      // Edit mode - populate with existing data
      final product = widget.product!;
      _nameController.text = product.name;
      _unitController.text = product.unit;
      _descriptionController.text = product.description;
      _barcodeController.text = product.barcode;
      _priceController.text = product.price.toString();
      _costPriceController.text = product.costPrice.toString();
      _skuController.text = product.sku;
      _coverImageUrl = product.imageUrl;
      _imageSet = List<String>.from(product.imageSet);
      _showInCatalog = product.showInCatalog;
      _selectedStatus = product.status;
      _selectedCategory = product.category;

      // Parse hashtags from object format to IDs
      if (product.hashtags.isNotEmpty) {
        _selectedHashtags = product.hashtags.map((hashtagObj) {
          return hashtagObj['id'] as String;
        }).toList();
      }
    }
  }

  // Image upload methods
  Future<void> _pickAndUploadCoverImage() async {
    try {
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('choose_image_source'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text('gallery'.tr),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text('camera'.tr),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingCover = true;
        });

        final imageUrl = await _uploadImage(image, 'cover');
        
        setState(() {
          _coverImageUrl = imageUrl;
          _isUploadingCover = false;
        });
        Get.snackbar(
          'success'.tr,
          'main_image_uploaded'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingCover = false;
      });
      Get.snackbar(
        'error'.tr,
        'cannot_upload_image'.tr.replaceFirst('{error}', e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickAndUploadAdditionalImage() async {
    try {
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('choose_image_source'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text('gallery'.tr),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text('camera'.tr),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingAdditional = true;
        });

        final imageUrl = await _uploadImage(image, 'additional');
        
        setState(() {
          _imageSet.add(imageUrl);
          _isUploadingAdditional = false;
        });

        Get.snackbar(
          'success'.tr,
          'additional_image_uploaded'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingAdditional = false;
      });
      Get.snackbar(
        'error'.tr,
        'cannot_upload_image'.tr.replaceFirst('{error}', e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> _uploadImage(XFile image, String type) async {
    try {
      final controller = Get.find<ProductsController>();
      final workspaceId = controller.currentWorkspaceId;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      
      if (workspaceId.isEmpty) {
        throw Exception('workspace_id_not_found'.tr);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${type}_${timestamp}_${image.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('workspaces/$workspaceId/products/$userId/$fileName');

      final file = File(image.path);
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('cannot_upload_image'.tr.replaceFirst('{error}', e.toString()));
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _imageSet.removeAt(index);
    });
    Get.snackbar(
      'success'.tr,
      'image_deleted_successfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(widget.product != null ? 'edit_product'.tr : 'add_product'.tr),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final needed = widget.product != null ? 'product:edit:all' : 'product:create';
              guardAction(context, needed, _saveProduct);
            },
            child: Text(
              'save'.tr,
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
              // Cover Image
              _buildImageSection(
                'main_image'.tr,
                _coverImageUrl,
                (url) => setState(() => _coverImageUrl = url),
                isRequired: true,
                isUploading: _isUploadingCover,
                onUpload: _pickAndUploadCoverImage,
              ),
              const SizedBox(height: 16),

              // Additional Images
              _buildMultipleImagesSection(),
              const SizedBox(height: 16),

              // Product Name
              _buildTextField('product_name'.tr, _nameController, isRequired: true),
              const SizedBox(height: 16),

              // Status
              _buildDropdownField(
                'status'.tr,
                _selectedStatus,
                _statusOptions,
                (value) => setState(() => _selectedStatus = value!),
                isRequired: true,
              ),
              const SizedBox(height: 16),

              // Category
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                _buildCategoryDropdownField(),
              const SizedBox(height: 16),

              // Unit
              _buildTextField('unit'.tr, _unitController),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                'details'.tr,
                _descriptionController,
                maxLines: 4,
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
                  label: 'hashtags'.tr,
                  hintText: 'select_hashtags'.tr,
                ),
              const SizedBox(height: 16),

              // SKU (Auto-generated)
              _buildSkuField(),
              const SizedBox(height: 16),

              // Barcode
              _buildTextField('barcode'.tr, _barcodeController),
              const SizedBox(height: 16),

              // Quantity (only if template has quantity column)
              if (_hasQuantityColumn()) ...[
                _buildTextField(
                  'quantity'.tr,
                  _quantityController,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  helperText: widget.remainingQuantity != null 
                      ? 'maximum_limit'.tr.replaceFirst('{limit}', '${widget.remainingQuantity!.truncateToDouble() == widget.remainingQuantity! ? widget.remainingQuantity!.toInt() : widget.remainingQuantity!.toStringAsFixed(2)}')
                      : null,
                  customValidator: _getQuantityError,
                ),
                const SizedBox(height: 16),
              ],

              // Show in Online Catalog
              _buildSwitchField(
                'show_in_online_catalog'.tr,
                _showInCatalog,
                (value) => setState(() => _showInCatalog = value),
              ),
              const SizedBox(height: 16),

              // Selling Price
              _buildTextField(
                'sale_price'.tr,
                _priceController,
                isRequired: true,
                keyboardType: TextInputType.number,
                prefix: '฿',
              ),
              const SizedBox(height: 16),

              // Cost Price
              _buildTextField(
                'cost_price'.tr,
                _costPriceController,
                keyboardType: TextInputType.number,
                prefix: '฿',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdownField() {
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
            'category'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'select_category'.tr,
            ),
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text('no_category'.tr),
              ),
              ..._availableCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Text(category['name'] ?? ''),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? '';
              });
            },
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
                  style: TextStyle(color: Colors.red, fontSize: 14),
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
                child: Text(_getStatusText(option)),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'please_select'.tr.replaceFirst('{label}', label);
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSkuField() {
    final isEditMode = widget.product != null;

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
                'product_sku'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (!isEditMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'auto_generate'.tr,
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
            controller: _skuController,
            enabled: isEditMode, // Enable editing only in edit mode
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: !isEditMode, // Only fill background when disabled
              fillColor: isEditMode ? null : Colors.grey.shade100,
              hintText: isEditMode ? null : 'auto_generate_sku'.tr,
            ),
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
    String? prefix,
    String? helperText,
    String? Function(String?)? customValidator,
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
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixText: prefix,
              helperText: helperText,
            ),
            validator: customValidator ?? (isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'please_enter_field'.tr.replaceFirst('{label}', label);
                    }
                    if (keyboardType == TextInputType.number) {
                      final number = double.tryParse(value);
                      if (number == null || number < 0) {
                        return 'please_enter_valid_number_field'.tr;
                      }
                    }
                    return null;
                  }
                : null),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    String label,
    String imageUrl,
    Function(String) onImageChanged, {
    bool isRequired = false,
    bool isUploading = false,
    VoidCallback? onUpload,
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
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isUploading
                ? Container(
                    color: AppTheme.backgroundGrey,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'uploading'.tr,
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : imageUrl.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryOrange,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.backgroundGrey,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppTheme.textGrey,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                          // Remove button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _coverImageUrl = '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppTheme.backgroundGrey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppTheme.textGrey,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'add_image'.tr,
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : onUpload,
                  icon: const Icon(Icons.upload, size: 16),
                  label: Text('upload'.tr),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : onUpload,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: Text('take_photo'.tr),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImagesSection() {
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
                'additional_images'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (_isUploadingAdditional)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryOrange,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _pickAndUploadAdditionalImage,
                  icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
                  tooltip: 'add_image'.tr,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_imageSet.isEmpty)
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'no_additional_images'.tr,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageSet.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageSet[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryOrange,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppTheme.backgroundGrey,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.textGrey,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        // Remove button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => _removeAdditionalImage(index),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'active'.tr;
      case 'draft':
        return 'draft'.tr;
      case 'discontinued':
        return 'discontinued'.tr;
      default:
        return status;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
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

        // Get workspace ID from controller
        final controller = Get.find<ProductsController>();
        final workspaceId = controller.currentWorkspaceId;

        if (workspaceId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_save_no_workspace'.tr),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Generate product ID for new products or use existing one for edit
        String productId;
        String sku;
        if (widget.product != null) {
          // Edit mode - use existing ID and SKU from controller
          productId = widget.product!.id;
          sku = _skuController.text.trim();
        } else {
          // Add mode - generate new ID and SKU
          productId = '';
          sku = await _generateSku();
        }

        // Create product object
        final product = Product(
          id: productId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
          unit: _unitController.text.trim(),
          barcode: _barcodeController.text.trim(),
          sku: sku,
          imageUrl: _coverImageUrl,
          imageSet: _imageSet,
          hashtags: hashtagObjects,
          customFields: [],
          features: [],
          initialStock: 0,
          reorderLevel: 0,
          targetStockLevel: 0,
          showInCatalog: _showInCatalog,
          status: _selectedStatus,
          category: _selectedCategory,
          workspaceId: workspaceId,
          searchableKeywords: [],
          createdAt: widget.product?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool success;
        if (widget.product != null) {
          // Update existing product
          success = await controller.updateProduct(workspaceId, product);
        } else {
          // Add new product
          success = await controller.addProduct(workspaceId, product);
        }

        // Close loading dialog
        Navigator.pop(context);

        if (!success) {
          final msg = controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'cannot_save_product'.tr;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
          return;
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null
                  ? 'product_updated_successfully'.tr
                  : 'product_added_successfully'.tr,
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
            content: Text('error_occurred_details'.tr.replaceFirst('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _generateSku() async {
    try {
      // Get workspace ID from controller
      final controller = Get.find<ProductsController>();
      final workspaceId = controller.currentWorkspaceId;

      if (workspaceId.isEmpty) {
        print(
          '⚠️ No workspace ID available for SKU generation, using fallback',
        );
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return 'P-$timestamp';
      }

      // Generate product SKU using the service
      final sku = await _idGenerationService.generateProductSku(workspaceId);
      print('✅ Generated product SKU: $sku');
      return sku;
    } catch (e) {
      print('❌ Error generating product SKU: $e');
      // Fallback to simple SKU generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'P-$timestamp';
    }
  }
}
