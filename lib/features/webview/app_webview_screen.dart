import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../core/navigation/navigation_policy.dart';
import '../../core/theme/app_colors.dart';
import '../about/about_us_screen.dart';
import '../main/persistent_bottom_nav.dart';
import '../services/services_screen.dart';

class AppWebViewScreen extends StatefulWidget {
  final AppRouteItem routeItem;
  final bool isArabic;

  const AppWebViewScreen({
    super.key,
    required this.routeItem,
    this.isArabic = true,
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

  int get _currentIndex {
    if (widget.routeItem.id == 'book') return 2;
    if (widget.routeItem.id == 'faq' || widget.routeItem.id == 'articles') return 4;
    if (widget.routeItem.id == 'chatbot' || widget.routeItem.id == 'followupChat') {
      return 5;
    }
    if (widget.routeItem.id == 'packages') return 4;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
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
      ..loadRequest(Uri.parse(widget.routeItem.url));
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
    final uri = Uri.parse(widget.routeItem.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  void _onBottomNavTapped(int index, BuildContext context) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AboutUsScreen(isArabic: widget.isArabic),
        ),
      );
      return;
    }
    if (index == 2 && widget.routeItem.id != 'book') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(
            routeItem: AppRouteRegistry.book,
            isArabic: widget.isArabic,
          ),
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ServicesScreen(isArabic: widget.isArabic),
        ),
      );
      return;
    }
    if (index == 4 && widget.routeItem.id != 'faq') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(
            routeItem: AppRouteRegistry.faq,
            isArabic: widget.isArabic,
          ),
        ),
      );
      return;
    }
    if (index == 5) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.routeItem.getTitle(widget.isArabic);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
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
              onPressed: () async {
                final shouldPop = await _handleWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
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
          body: Stack(
            children: [
              Column(
                children: [
                  // Progress Bar during loading
                  if (_isLoading && _loadingProgress < 100)
                    LinearProgressIndicator(
                      value: _loadingProgress / 100.0,
                      backgroundColor: AppColors.cream,
                      color: AppColors.accentOrange,
                      minHeight: 3,
                    ),

                  // Main content area with bottom padding for persistent nav bar
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 75),
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
                  ),
                ],
              ),

              // Persistent Bottom Navigation Bar
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: PersistentBottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => _onBottomNavTapped(index, context),
                  isArabic: widget.isArabic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
