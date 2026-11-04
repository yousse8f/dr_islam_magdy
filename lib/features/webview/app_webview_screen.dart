import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../core/navigation/navigation_policy.dart';
import '../../core/services/app_config_service.dart';
import '../../core/theme/app_colors.dart';

class AppWebViewScreen extends StatefulWidget {
  final AppRouteItem routeItem;
  final bool isArabic;
  final bool showBottomNav;
  final VoidCallback? onReturnToHome;

  const AppWebViewScreen({
    super.key,
    required this.routeItem,
    this.isArabic = true,
    this.showBottomNav = false,
    this.onReturnToHome,
  });

  @override
  State<AppWebViewScreen> createState() => _AppWebViewScreenState();
}

class _AppWebViewScreenState extends State<AppWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _loadingProgress = 0;
  bool _isHandlingBack = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    final targetUrl = AppConfigService.getUrl(widget.routeItem);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.cream)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            // Set responsive viewport & center page content cleanly across the full screen width
            _controller.runJavaScript('''
              (function() {
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                  meta = document.createElement('meta');
                  meta.name = 'viewport';
                  if (document.head) {
                    document.head.appendChild(meta);
                  }
                }
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
                document.documentElement.style.maxWidth = '100%';
                document.documentElement.style.overflowX = 'hidden';
                document.body.style.maxWidth = '100%';
                document.body.style.margin = '0 auto';
                document.body.style.overflowX = 'hidden';
                document.body.style.zoom = '100%';
                document.body.style.transformOrigin = 'top center';
              })();
            ''');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final allowed =
                await NavigationPolicyHandler.shouldNavigateInternal(
                  request.url,
                );
            if (allowed) {
              return NavigationDecision.navigate;
            } else {
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  void _retryLoad() {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _loadingProgress = 0;
    });
    _controller.reload();
  }

  Future<void> _openInExternalBrowser() async {
    final targetUrl = AppConfigService.getUrl(widget.routeItem);
    final uri = Uri.parse(targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Single thread-safe back button handler.
  Future<void> _handleBackPress() async {
    if (_isHandlingBack) return;
    _isHandlingBack = true;

    try {
      final initialUrlStr = AppConfigService.getUrl(widget.routeItem);
      final initialUri = Uri.tryParse(initialUrlStr);

      String? currentUrlStr;
      bool canGoBack = false;

      try {
        currentUrlStr = await _controller.currentUrl();
        canGoBack = await _controller.canGoBack();
      } catch (_) {
        canGoBack = false;
      }

      bool isOnInitialUrl = false;
      if (currentUrlStr != null && initialUri != null) {
        final currentUri = Uri.tryParse(currentUrlStr);
        if (currentUri != null) {
          final currentNormalized =
              '${currentUri.host.toLowerCase()}${currentUri.path.replaceAll(RegExp(r'/+$'), '')}';
          final initialNormalized =
              '${initialUri.host.toLowerCase()}${initialUri.path.replaceAll(RegExp(r'/+$'), '')}';
          if (currentNormalized == initialNormalized) {
            isOnInitialUrl = true;
          }
        }
      }

      // If on initial URL or cannot go back in WebView, pop screen or return to home directly
      if (isOnInitialUrl || !canGoBack) {
        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else if (widget.onReturnToHome != null) {
          widget.onReturnToHome!();
        } else {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
        return;
      }

      // Otherwise navigate back inside WebView
      await _controller.goBack();
    } catch (e) {
      debugPrint('Error in _handleBackPress: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else if (widget.onReturnToHome != null) {
          widget.onReturnToHome!();
        }
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.routeItem.getTitle(widget.isArabic);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Directionality(
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: widget.isArabic ? 'رجوع' : 'Back',
              onPressed: _handleBackPress,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: widget.isArabic ? 'إعادة تحميل' : 'Reload',
                onPressed: _retryLoad,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'browser') {
                    _openInExternalBrowser();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'browser',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.open_in_browser_rounded,
                          color: AppColors.forestGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isArabic
                              ? 'فتح في المتصفح'
                              : 'Open in Browser',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress Bar during loading
              if (_isLoading && _loadingProgress < 100)
                LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: AppColors.cream,
                  color: AppColors.accentOrange,
                  minHeight: 3,
                ),

              // Main content area
              Expanded(
                child: Stack(
                  children: [
                    // WebView widget
                    WebViewWidget(controller: _controller),

                    // Initial loading screen
                    if (_isLoading && _loadingProgress < 25)
                      Container(
                        color: AppColors.cream,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.forestGreen,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.isArabic
                                    ? 'جاري تحميل الصفحة...'
                                    : 'Loading page...',
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error overlay
                    if (_hasError)
                      Container(
                        color: AppColors.cream,
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 64,
                                color: AppColors.mutedText,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.isArabic
                                    ? 'تعذر تحميل الصفحة'
                                    : 'Failed to load page',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isArabic
                                    ? 'يرجى التأكد من الاتصال بالإنترنت والمحاولة مرة أخرى.'
                                    : 'Please check your internet connection and try again.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _retryLoad,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestGreen,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  widget.isArabic ? 'إعادة المحاولة' : 'Retry',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
