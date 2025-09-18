import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/mobile_api.dart';
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
  late WebViewController _webViewController;
  bool _isLoading = true;
  String _errorMessage = '';

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

  String get _documentUrl {
    String type;
    switch (widget.documentType.toUpperCase()) {
      case 'QT':
        type = 'quotation';
        break;
      case 'INV':
        type = 'invoice';
        break;
      case 'RT':
        type = 'receipt';
        break;
      default:
        type = 'document';
    }
    return '${MobileApiConfig.baseUrl}/doc/$type/${widget.documentId}';
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
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
            // Inject viewport and scaling JavaScript after page loads
            _injectViewportScript();
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

    // Load the document URL
    _webViewController.loadRequest(Uri.parse(_documentUrl));
  }

  void _reloadPage() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _webViewController.reload();
  }

  void _forceResponsiveReload() {
    // First reload, then inject viewport script after a delay
    _reloadPage();
    Future.delayed(const Duration(milliseconds: 1000), () {
      _injectViewportScript();
    });
  }

  void _injectViewportScript() {
    // Inject viewport meta tag and responsive CSS
    final viewportScript = '''
      // Add or update viewport meta tag
      var viewport = document.querySelector('meta[name="viewport"]');
      if (!viewport) {
        viewport = document.createElement('meta');
        viewport.name = 'viewport';
        document.head.appendChild(viewport);
      }
      viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
      
      // Add responsive CSS
      var style = document.createElement('style');
      style.textContent = `
        body {
          -webkit-text-size-adjust: 100% !important;
          -ms-text-size-adjust: 100% !important;
          text-size-adjust: 100% !important;
          width: 100% !important;
          max-width: 100% !important;
          overflow-x: auto !important;
        }
        
        * {
          max-width: 100% !important;
          box-sizing: border-box !important;
        }
        
        img, video, iframe, embed, object {
          max-width: 100% !important;
          height: auto !important;
        }
        
        table {
          width: 100% !important;
          table-layout: fixed !important;
        }
        
        .container, .content, .main {
          width: 100% !important;
          max-width: 100% !important;
          padding: 10px !important;
        }
      `;
      document.head.appendChild(style);
      
      // Force reflow
      document.body.style.zoom = '1';
      
      console.log('Viewport and responsive CSS injected');
    ''';

    _webViewController.runJavaScript(viewportScript);
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
            child: _errorMessage.isEmpty 
              ? WebViewWidget(
                  controller: _webViewController,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load document',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
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
        // TODO: Open in external browser
        Get.snackbar(
          'Info',
          'Opening in browser: $_documentUrl',
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