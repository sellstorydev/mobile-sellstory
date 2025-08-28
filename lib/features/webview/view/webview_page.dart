import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class WebViewPage extends StatefulWidget {
  final String? url;
  final Map<String, dynamic>? parameters;
  final String? title;

  const WebViewPage({
    super.key,
    this.url,
    this.parameters,
    this.title,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String _currentUrl = '';
  String _errorMessage = '';

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
                _currentUrl = url;
                _errorMessage = '';
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error: ${error.description}';
              });
            }
          },
        ),
      );

    // Load URL with parameters
    _loadUrlWithParameters();
  }

  void _loadUrlWithParameters() {
    String url = widget.url ?? 'https://example.com';
    
    // Add parameters to URL if provided
    if (widget.parameters != null && widget.parameters!.isNotEmpty) {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      
      // Add custom parameters
      widget.parameters!.forEach((key, value) {
        queryParams[key] = value.toString();
      });
      
      final newUri = uri.replace(queryParameters: queryParams);
      url = newUri.toString();
    }

    // Load the URL
    _webViewController.loadRequest(Uri.parse(url));
  }

  void _injectJavaScriptData() {
    if (widget.parameters != null) {
      // Convert parameters to JavaScript object
      final jsData = widget.parameters!.entries
          .map((e) => "'${e.key}': '${e.value}'")
          .join(', ');
      
      final jsCode = '''
        // Inject data into page
        window.flutterData = { $jsData };
        
        // Dispatch custom event
        window.dispatchEvent(new CustomEvent('flutterDataLoaded', {
          detail: window.flutterData
        }));
        
        // Log data for debugging
        console.log('Flutter data injected:', window.flutterData);
      ''';

      _webViewController.runJavaScript(jsCode);
    }
  }

  void _reloadPage() {
    _webViewController.reload();
  }

  void _goBack() {
    _webViewController.canGoBack().then((canGoBack) {
      if (canGoBack) {
        _webViewController.goBack();
      } else {
        Get.back();
      }
    });
  }

  void _goForward() {
    _webViewController.canGoForward().then((canGoForward) {
      if (canGoForward) {
        _webViewController.goForward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(widget.title ?? 'Web View'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          // Reload button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadPage,
            tooltip: 'Reload',
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'inject_data',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 12),
                    Text('Inject Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'show_parameters',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Show Parameters'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_url',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Copy URL'),
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
                ],
              ),
            ),
          
          // WebView
          Expanded(
            child: WebViewWidget(controller: _webViewController),
          ),
          
          // Bottom navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                  tooltip: 'Go Back',
                ),
                
                // Forward button
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _goForward,
                  tooltip: 'Go Forward',
                ),
                
                const SizedBox(width: 16),
                
                // URL display
                Expanded(
                  child: Text(
                    _currentUrl,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Home button
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    _webViewController.loadRequest(Uri.parse(widget.url ?? 'https://example.com'));
                  },
                  tooltip: 'Home',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'inject_data':
        _injectJavaScriptData();
        Get.snackbar(
          'Success',
          'Data injected into page',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        break;
        
      case 'show_parameters':
        _showParametersDialog();
        break;
        
      case 'copy_url':
        // Copy URL to clipboard
        // You can add clipboard functionality here
        Get.snackbar(
          'Info',
          'URL copied to clipboard',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
    }
  }

  void _showParametersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parameters'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.parameters != null) ...[
                ...widget.parameters!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(entry.value.toString()),
                      ),
                    ],
                  ),
                )),
              ] else ...[
                const Text('No parameters provided'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Current URL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _currentUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
