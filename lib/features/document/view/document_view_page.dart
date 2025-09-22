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
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true) // Re-enable zoom to work with responsive design
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Block all external navigation requests to prevent ORB issues
            if (request.url.startsWith('http://') || request.url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
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
            // Inject mobile optimization JavaScript that works with existing responsive CSS
            _webViewController?.runJavaScript('''
              // Function to apply mobile optimization based on current orientation
              function applyMobileOptimization() {
                // Get screen dimensions
                var screenWidth = window.innerWidth || document.documentElement.clientWidth;
                var screenHeight = window.innerHeight || document.documentElement.clientHeight;
                
                console.log('Screen dimensions: ' + screenWidth + 'x' + screenHeight);
                
                // Ensure viewport is set for mobile
                var viewportMeta = document.querySelector('meta[name="viewport"]');
                if (!viewportMeta) {
                  viewportMeta = document.createElement('meta');
                  viewportMeta.setAttribute('name', 'viewport');
                  document.head.appendChild(viewportMeta);
                }
                viewportMeta.setAttribute('content', 'width=device-width, initial-scale=1.0, user-scalable=yes');
                
                // Check if the page already has responsive CSS for mobile
                var hasResponsiveCSS = false;
                var stylesheets = document.querySelectorAll('style, link[rel="stylesheet"]');
                stylesheets.forEach(function(sheet) {
                  if (sheet.textContent && sheet.textContent.includes('@media')) {
                    hasResponsiveCSS = true;
                  }
                });
                
                if (hasResponsiveCSS) {
                  console.log('Responsive CSS detected - using existing responsive design');
                  
                  // Check if device is in landscape mode
                  var isLandscape = screenWidth > screenHeight;
                  console.log('Device orientation: ' + (isLandscape ? 'Landscape' : 'Portrait'));
                  
                  // Remove previous orientation classes
                  document.body.classList.remove('landscape-view', 'portrait-view');
                  
                  // Let the existing responsive CSS handle the layout
                  // Just ensure body and html allow proper rendering
                  document.documentElement.style.cssText = `
                    margin: 0 !important;
                    padding: 0 !important;
                    width: 100% !important;
                    height: 100% !important;
                  `;
                  
                  document.body.style.cssText = `
                    margin: 0 !important;
                    padding: 0 !important;
                    width: 100% !important;
                    min-height: 100vh !important;
                    overflow-x: hidden !important;
                  `;
                  
                  // Force mobile media queries to activate if screen is mobile size
                  if (screenWidth <= 768) {
                    // Add a class to body to ensure mobile styles are applied
                    document.body.classList.add('mobile-view');
                    if (isLandscape) {
                      document.body.classList.add('landscape-view');
                    } else {
                      document.body.classList.add('portrait-view');
                    }
                    
                    // Ensure containers respect mobile layout
                    var containers = document.querySelectorAll('.container');
                    containers.forEach(function(container) {
                      container.style.cssText += `
                        max-width: 100% !important;
                        margin: 0 auto !important;
                        border-radius: 0 !important;
                        box-shadow: none !important;
                        ` + (isLandscape ? 'min-height: auto !important;' : '') + `
                      `;
                    });
                    
                    // Ensure pdf content is mobile optimized
                    var pdfContent = document.querySelector('#pdf-preview-content');
                    if (pdfContent) {
                      pdfContent.style.cssText += `
                        width: 100vw !important;
                        max-width: 100vw !important;
                        margin: 0 !important;
                        padding: 0 !important;
                        display: flex !important;
                        justify-content: center !important;
                        ` + (isLandscape ? 'overflow-y: auto !important;' : '') + `
                      `;
                    }
                    
                    // Force page scaling for mobile
                    var pages = document.querySelectorAll('.page');
                    pages.forEach(function(page) {
                      var scale = screenWidth / 794; // A4 width in pixels
                      if (screenWidth <= 480) {
                        scale = (screenWidth - 20) / 794;
                      }
                      if (screenWidth <= 320) {
                        scale = (screenWidth - 10) / 794;
                      }
                      
                      page.style.cssText += `
                        transform: scale(` + scale + `) !important;
                        transform-origin: top center !important;
                        margin: 0 !important;
                        position: relative !important;
                      `;
                    });
                    
                    // Adjust page container wrappers
                    var pageWrappers = document.querySelectorAll('.page-container-wrapper');
                    pageWrappers.forEach(function(wrapper) {
                      var scale = screenWidth / 794;
                      if (screenWidth <= 480) {
                        scale = (screenWidth - 20) / 794;
                      }
                      if (screenWidth <= 320) {
                        scale = (screenWidth - 10) / 794;
                      }
                      
                      wrapper.style.cssText += `
                        width: 100% !important;
                        display: flex !important;
                        justify-content: center !important;
                      `;
                    });
                  }
                  
                } else {
                  console.log('No responsive CSS detected - applying fallback mobile styles');
                  
                  // Check if device is in landscape mode
                  var isLandscape = screenWidth > screenHeight;
                  console.log('Device orientation: ' + (isLandscape ? 'Landscape' : 'Portrait'));
                  
                  // Fallback mobile optimization for non-responsive pages
                  document.body.style.cssText += `
                    margin: 0 !important;
                    padding: 8px !important;
                    width: 100% !important;
                    max-width: 100% !important;
                    overflow-x: hidden !important;
                    overflow-y: ` + (isLandscape ? 'auto' : 'hidden') + ` !important;
                    font-size: 14px !important;
                    line-height: 1.4 !important;
                  `;
                  
                  // Scale down content to fit mobile
                  var allContent = document.querySelector('body > *');
                  if (allContent && screenWidth < 768) {
                    var scale = screenWidth / 800; // Assume desktop width of 800px
                    allContent.style.cssText += `
                      transform: scale(` + scale + `) !important;
                      transform-origin: top left !important;
                      width: ` + (100/scale) + `% !important;
                    `;
                  }
                }
              }
              
              // Apply mobile optimization initially
              applyMobileOptimization();
              
              // Listen for orientation changes and viewport resize
              window.addEventListener('orientationchange', function() {
                // Add a small delay to ensure the orientation change is complete
                setTimeout(function() {
                  console.log('Orientation changed - reapplying mobile optimization');
                  applyMobileOptimization();
                }, 300);
              });
              
              // Also listen for resize events (covers more cases)
              window.addEventListener('resize', function() {
                // Debounce resize events
                clearTimeout(window.resizeTimeout);
                window.resizeTimeout = setTimeout(function() {
                  console.log('Window resized - reapplying mobile optimization');
                  applyMobileOptimization();
                }, 200);
              });
            ''');
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('⚠️ WebView resource error: ${error.errorCode} - ${error.description}');
            // Don't show error for blocked external resources
            if (error.errorCode == -10 || error.description.contains('ORB') || error.description.contains('CORS')) {
              print('🔧 Ignoring ORB/CORS related error as expected');
              return;
            }
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
      final documentResult = await _webviewApiService.getDocumentShareUrl(
        documentId: widget.documentId,
        documentType: _documentTypeName,
      );
      print('🔗 Document result: $documentResult');
      
      if (documentResult != null && _webViewController != null) {
        final resultType = documentResult['type'] as String?;
        final content = documentResult['content'] as String?;
        
        if (content != null && content.isNotEmpty) {
          if (resultType == 'url') {
            // Load URL directly
            if (content.startsWith('http://') || content.startsWith('https://')) {
              _webViewController!.loadRequest(Uri.parse(content));
            } else {
              throw Exception('Invalid URL format: $content');
            }
          } else if (resultType == 'html') {
            // Load HTML content directly using loadHtmlString
            print('📄 Loading HTML content directly (${content.length} characters)');
            _webViewController!.loadHtmlString(content);
          } else {
            throw Exception('Unknown result type: $resultType');
          }
        } else {
          throw Exception('Empty content received');
        }
      } else {
        throw Exception('Failed to get document content');
      }
    } catch (e) {
      print('❌ Error getting document content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load document. Please try again later.';
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
        final documentResult = await _webviewApiService.getDocumentShareUrl(
          documentId: widget.documentId,
          documentType: _documentTypeName,
        );

        if (documentResult != null && _webViewController != null) {
          final resultType = documentResult['type'] as String?;
          final content = documentResult['content'] as String?;
          
          if (content != null && content.isNotEmpty) {
            if (resultType == 'url') {
              // Load URL directly
              if (content.startsWith('http://') || content.startsWith('https://')) {
                _webViewController!.loadRequest(Uri.parse(content));
              } else {
                throw Exception('Invalid URL format: $content');
              }
            } else if (resultType == 'html') {
              // Load HTML content directly using loadHtmlString
              print('📄 Reloading HTML content directly (${content.length} characters)');
              _webViewController!.loadHtmlString(content);
            } else {
              throw Exception('Unknown result type: $resultType');
            }
          } else {
            throw Exception('Empty content received');
          }
        } else {
          throw Exception('Failed to get document content');
        }
      } else {
        _webViewController?.reload();
      }
    } catch (e) {
      print('❌ Error reloading document: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to reload document. Please try again later.';
        });
      }
    }
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

  Future<void> _deleteDocument() async {
    // Show confirmation dialog
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('delete_document'.tr),
          content: Text('delete_document_confirmation'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        // Show loading indicator
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        if (_currentWorkspaceId == null) {
          throw Exception('Workspace ID not available');
        }

        // Delete document from Firestore
        await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(_currentWorkspaceId)
            .collection('documents')
            .doc(widget.documentId)
            .delete();

        // Show success message
        Get.snackbar(
          'success'.tr,
          'document_deleted_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate back to previous screen with deletion result
        if (mounted) {
          Navigator.of(context).pop({'deleted': true, 'documentId': widget.documentId}); // Return deletion info
        }
      } catch (e) {
        print('❌ Error deleting document: $e');
        
        // Hide loading indicator
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        // Show error message
        Get.snackbar(
          'error'.tr,
          'failed_to_delete_document'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
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
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteDocument,
            tooltip: 'delete'.tr,
            color: Colors.red,
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
            Flexible(
              child: Container(
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
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
            ),

          // WebView
          Expanded(
            child: _errorMessage.isEmpty && _webViewController != null
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: WebViewWidget(controller: _webViewController!),
                  )
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
      )
    );
  }
}
