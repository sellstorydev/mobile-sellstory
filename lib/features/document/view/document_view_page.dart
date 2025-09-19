import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/webview_api_service.dart';
import '../view/add_edit_document_page.dart';

class DocumentViewPage extends StatefulWidget {
  final String documentType; // 'QT', 'INV', 'RT'
  final String documentId;
  final String? title;

  const DocumentViewPage({
    super.key,
    required this.documentType,
    required this.documentId,
    this.title,
  });

  @override
  State<DocumentViewPage> createState() => _DocumentViewPageState();
}

class _DocumentViewPageState extends State<DocumentViewPage> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String _errorMessage = '';
  late WebviewApiService _webviewApiService;
  String? _currentUserId;
  String? _currentWorkspaceId;

  String get _documentTypeLabel {
    switch (widget.documentType.toUpperCase()) {
      case 'QT':
        return 'quotation'.tr;
      case 'INV':
        return 'invoice'.tr;
      case 'RT':
        return 'receipt'.tr;
      default:
        return 'document'.tr;
    }
  }

  String get _documentTypeName {
    switch (widget.documentType.toUpperCase()) {
      case 'QT':
        return 'quotation';
      case 'INV':
        return 'invoice';
      case 'RT':
        return 'receipt';
      default:
        return 'document';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize WebviewApiService from DI container
      _webviewApiService = Get.find<WebviewApiService>();

      // Get current user and workspace
      await _initializeUserAndWorkspace();

      // Initialize WebView
      await _initializeWebView();
    } catch (e) {
      print('❌ Failed to initialize services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize: $e';
        });
      }
    }
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _currentUserId = user.uid;

      // Get user's workspace information from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['workspaces'] != null) {
          final workspaces = userData['workspaces'] as List;
          if (workspaces.isNotEmpty) {
            _currentWorkspaceId = workspaces[0]['id'] as String;
          }
        }
      }

      if (_currentWorkspaceId == null) {
        throw Exception('No workspace found for user');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
      throw e;
    }
  }

  Future<void> _initializeWebView() async {
    if (_currentUserId == null || _currentWorkspaceId == null) {
      throw Exception('User ID or Workspace ID not available');
    }

    // Initialize WebView controller
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
            if (mounted) {
              setState(() {
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error loading document: ${error.description}';
              });
            }
          },
        ),
      );

    // Get document URL from API
    try {
      final documentUrl = await _webviewApiService.getDocumentShareUrl(
        documentId: widget.documentId,
        documentType: _documentTypeName,
      );

      if (documentUrl != null && _webViewController != null) {
        // Load the document URL
        _webViewController!.loadRequest(Uri.parse(documentUrl));
      } else {
        throw Exception('Failed to get document share URL');
      }
    } catch (e) {
      print('❌ Error getting document URL: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load document: $e';
        });
      }
    }
  }

  Future<void> _reloadPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_currentUserId != null && _currentWorkspaceId != null) {
        final documentUrl = await _webviewApiService.getDocumentShareUrl(
          documentId: widget.documentId,
          documentType: _documentTypeName,
        );

        if (documentUrl != null && _webViewController != null) {
          _webViewController!.loadRequest(Uri.parse(documentUrl));
        } else {
          throw Exception('Failed to get document share URL');
        }
      } else {
        _webViewController?.reload();
      }
    } catch (e) {
      print('❌ Error reloading document: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to reload document: $e';
        });
      }
    }
  }

  void _forceResponsiveReload() {
    // First reload, then inject viewport script after a delay
    // _reloadPage();
  }

  void _editDocument() {
    // Navigate to edit page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDocumentPage(
          documentType: widget.documentType,
          documentId: widget.documentId,
        ),
      ),
    ).then((result) {
      // Refresh the view if document was edited
      if (result == true) {
        _reloadPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(widget.title ?? _documentTypeLabel),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDocument,
            tooltip: 'edit'.tr,
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Reload'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fit_screen',
                child: Row(
                  children: [
                    Icon(Icons.fit_screen, size: 20),
                    SizedBox(width: 12),
                    Text('Fit to Screen'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'open_browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser, size: 20),
                    SizedBox(width: 12),
                    Text('Open in Browser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            ),

          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _errorMessage = '';
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _reloadPage,
                    tooltip: 'retry'.tr,
                  ),
                ],
              ),
            ),

          // WebView
          Expanded(
            child: _errorMessage.isEmpty && _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _errorMessage.isNotEmpty
                              ? Icons.error_outline
                              : Icons.hourglass_empty,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage.isNotEmpty
                              ? 'Failed to load document'
                              : 'Initializing...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage.isNotEmpty
                              ? 'Please check your connection and try again'
                              : 'Please wait while we prepare the document',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: _reloadPage,
                            icon: const Icon(Icons.refresh),
                            label: Text('retry'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      // Floating action button for quick edit
      floatingActionButton: FloatingActionButton(
        onPressed: _editDocument,
        backgroundColor: AppTheme.primaryOrange,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reload':
        _reloadPage();
        break;

      case 'fit_screen':
        _forceResponsiveReload();
        Get.snackbar(
          'Info',
          'Fitting document to screen size...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryOrange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        break;

      case 'open_browser':
        // Show document info since we don't have direct URL anymore
        Get.snackbar(
          'Info',
          'Document: ${widget.documentType}-${widget.documentId}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryOrange,
          colorText: Colors.white,
        );
        break;

      case 'share':
        // TODO: Share document URL
        Get.snackbar(
          'Info',
          'Document URL copied',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryOrange,
          colorText: Colors.white,
        );
        break;
    }
  }
}
