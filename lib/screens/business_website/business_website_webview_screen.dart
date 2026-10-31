import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/business_website/bw_web_frame.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Loads a business website public URL or preview HTML.
/// Full-bleed website with a Flutter-only close strip (iframe cannot steal taps).
class BusinessWebsiteWebViewScreen extends StatefulWidget {
  final String? url;
  final String? html;
  final String title;
  final bool previewMode;

  /// Template sample HTML from `previewTemplateSample` — not an owner draft
  /// or published site. Blocks native track/claim bridges and transaction nav.
  final bool sampleDemoPreview;

  const BusinessWebsiteWebViewScreen({
    super.key,
    this.url,
    this.html,
    this.title = 'Website',
    this.previewMode = false,
    this.sampleDemoPreview = false,
  }) : assert(url != null || html != null);

  @override
  State<BusinessWebsiteWebViewScreen> createState() =>
      _BusinessWebsiteWebViewScreenState();
}

class _BusinessWebsiteWebViewScreenState
    extends State<BusinessWebsiteWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;
  late final String _webViewType;

  Map<String, String> get _authHeaders {
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    if (token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, String> _shopperPayload() {
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    var name = '';
    var phone = '';
    var username = '';
    try {
      final profile =
          Provider.of<ProfileProvider>(context, listen: false).profile;
      name = profile.name.trim();
      phone = profile.phone.trim();
      username = (profile.username ?? '').trim().replaceFirst('@', '');
    } catch (_) {}
    return {
      if (name.isNotEmpty) 'name': name,
      if (phone.isNotEmpty) 'phone': phone,
      if (username.isNotEmpty) 'username': username,
      if (token.isNotEmpty) 'token': token,
    };
  }

  void _openTrackOrder(String orderId, {String? accessToken}) {
    // Sample template demos must never open real order tracking.
    if (widget.sampleDemoPreview) return;
    final id = orderId.trim();
    if (id.isEmpty || !mounted) return;
    final token = (accessToken ?? '').trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: id,
          isBusinessView: false,
          accessToken: token.isEmpty ? null : token,
        ),
      ),
    );
  }

  bool _tryHandleTrackOrderUrl(String url) {
    if (widget.sampleDemoPreview) {
      final uri = Uri.tryParse(url);
      if (uri?.scheme == 'barqody') return true; // swallow
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'barqody' &&
        (uri.host == 'orders' || uri.pathSegments.isNotEmpty)) {
      final id = uri.host == 'orders' && uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '');
      if (id.isNotEmpty) {
        _openTrackOrder(id);
        return true;
      }
    }
    return false;
  }

  /// Sample multi-page preview API (Phase 2B) — allowed with auth headers.
  bool _isSamplePreviewApiUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    final isAppPreview = RegExp(
      r'/api/business-websites/templates/[^/]+/preview/?$',
    ).hasMatch(path);
    final isAdminPreview = RegExp(
      r'/api/admin/website-templates/[^/]+/preview/?$',
    ).hasMatch(path);
    return isAppPreview || isAdminPreview;
  }

  /// Block navigations that would hit real commerce / payment / track APIs
  /// while viewing a synthetic template sample.
  bool _isSampleBlockedNavigation(String url) {
    if (!widget.sampleDemoPreview) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    // Multi-page sample preview API is allowed (loaded with auth below).
    if (_isSamplePreviewApiUrl(url)) return false;
    if (path.contains('/api/catalog/') &&
        (path.contains('/orders') ||
            path.contains('payment') ||
            path.contains('availability') ||
            path.contains('claim'))) {
      return true;
    }
    if (path.contains('/api/offers/') ||
        path.contains('/api/loyalty/') ||
        path.contains('/api/booking') ||
        path.contains('/api/user/auth/otp/')) {
      return true;
    }
    // Sample HTML must not leave the preview surface for a live /w/ site.
    if (path.startsWith('/w/')) return true;
    return false;
  }

  int _chromeTopPx(BuildContext context) {
    // Close sits in a Flutter strip above the site — no overlay inset needed.
    return 0;
  }

  String _withAppChromeQuery(String url) {
    try {
      final uri = Uri.parse(url);
      final q = Map<String, String>.from(uri.queryParameters);
      q['bw_chrome'] = '${_chromeTopPx(context)}';
      return uri.replace(queryParameters: q).toString();
    } catch (_) {
      return url;
    }
  }

  String _withShopperQuery(String url) {
    try {
      final uri = Uri.parse(_withAppChromeQuery(url));
      final q = Map<String, String>.from(uri.queryParameters);
      final shopper = _shopperPayload();
      final name = shopper['name'];
      final phone = shopper['phone'];
      // Prefill only — never put JWT in the URL (logs / referrers / history).
      // Auth token is injected via _injectShopper() → window.__BW_SHOPPER.
      if (name != null && name.isNotEmpty) q['bw_n'] = name;
      if (phone != null && phone.isNotEmpty) q['bw_p'] = phone;
      q.remove('bw_t');
      q.remove('token');
      q.remove('access_token');
      return uri.replace(queryParameters: q).toString();
    } catch (_) {
      return url;
    }
  }

  /// Clearance under Flutter close button + status bar (shared by every template).
  Future<void> _injectChromeInsets() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final chromeTop = _chromeTopPx(context);
    await controller.runJavaScript(
      "document.documentElement.style.setProperty('--bw-chrome-top','${chromeTop}px');",
    );
  }

  Future<void> _injectShopper() async {
    final controller = _controller;
    if (controller == null) return;
    final shopper = _shopperPayload();
    if (shopper.isEmpty) return;
    // Only inject when we have a JWT — name/phone prefill alone must not
    // look like an authenticated session (and must not wipe a real one).
    if ((shopper['token'] ?? '').trim().isEmpty) return;
    final json = jsonEncode(shopper);
    await controller.runJavaScript('''
      (function(){
        var incoming=$json;
        window.__BW_SHOPPER=incoming;
        try{localStorage.setItem('bw_shopper_v1', JSON.stringify(incoming));}catch(e){}
        if(typeof window.__BW_ON_SHOPPER==='function'){
          window.__BW_ON_SHOPPER();
          return;
        }
        document.querySelectorAll('[data-bw-auth-choice]').forEach(function(el){ el.hidden=true; });
        document.querySelectorAll('[data-bw-guest-fields],[data-bw-barqody-auth]').forEach(function(el){ el.hidden=true; });
        document.querySelectorAll('[data-bw-authed-banner]').forEach(function(el){ el.hidden=false; });
        var nameLabel=document.querySelector('[data-bw-auth-name]');
        if(nameLabel){
          var label=String(incoming.name||'').trim();
          if(!label && incoming.username) label=String(incoming.username).replace(/^@/,'');
          if(!label) label='BarQody customer';
          nameLabel.textContent=label;
        }
      })();
    ''');
  }

  String _withPreviewToken(String url) {
    var target = url.trim();
    if (!widget.previewMode) return target;
    if (!target.contains('preview=')) {
      final sep = target.contains('?') ? '&' : '?';
      target = '$target${sep}preview=1';
    }
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    if (token.isNotEmpty && !target.contains('token=')) {
      final sep = target.contains('?') ? '&' : '?';
      target = '$target${sep}token=${Uri.encodeQueryComponent(token)}';
    }
    return target;
  }

  @override
  void initState() {
    super.initState();
    _webViewType =
        'bw-site-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

    if (kIsWeb) {
      _loading = false;
      final html = widget.html?.trim();
      final url = widget.url?.trim();
      if ((html == null || html.isEmpty) && (url == null || url.isEmpty)) {
        _error = 'Nothing to load';
      }
      return;
    }

    _initNativeWebView();
  }

  void _initNativeWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setOnJavaScriptAlertDialog((request) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(request.message)),
        );
      })
      ..setOnJavaScriptConfirmDialog((request) async {
        if (!mounted) return false;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(request.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return ok == true;
      })
      ..addJavaScriptChannel(
        'BarqodyBridge',
        onMessageReceived: (message) {
          // Sample demos: ignore track/claim bridge messages entirely.
          if (widget.sampleDemoPreview) return;
          try {
            final raw = message.message.trim();
            if (raw.isEmpty) return;
            final decoded = jsonDecode(raw);
            if (decoded is Map && decoded['action'] == 'trackOrder') {
              final id = decoded['orderId']?.toString() ?? '';
              final token = decoded['token']?.toString();
              _openTrackOrder(id, accessToken: token);
              return;
            }
            // Plain order id fallback
            _openTrackOrder(raw);
          } catch (_) {
            _openTrackOrder(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) async {
            await _injectChromeInsets();
            // Do not inject shopper JWT into synthetic sample previews.
            if (!widget.sampleDemoPreview) {
              await _injectShopper();
            }
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = error.description;
              });
            }
          },
          onNavigationRequest: (request) {
            if (_tryHandleTrackOrderUrl(request.url)) {
              return NavigationDecision.prevent;
            }

            if (_isSampleBlockedNavigation(request.url)) {
              return NavigationDecision.prevent;
            }

            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            final base = Uri.tryParse(Api.baseUrl);
            final sameHost =
                base != null &&
                uri.host.isNotEmpty &&
                uri.host == base.host;

            // Phase 2B: sample detail/cart pages load via preview API with JWT.
            if (widget.sampleDemoPreview &&
                sameHost &&
                _isSamplePreviewApiUrl(request.url)) {
              _controller?.loadRequest(
                uri,
                headers: _authHeaders,
              );
              return NavigationDecision.prevent;
            }

            // Owner draft preview only — never rewrite sample HTML into /w/.
            if (widget.previewMode &&
                !widget.sampleDemoPreview &&
                sameHost &&
                uri.path.startsWith('/w/')) {
              final patched = _withPreviewToken(request.url);
              if (patched != request.url) {
                _controller?.loadRequest(
                  Uri.parse(patched),
                  headers: _authHeaders,
                );
                return NavigationDecision.prevent;
              }
            }

            if (sameHost ||
                request.url.startsWith('about:blank') ||
                request.url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            if (!uri.hasScheme) return NavigationDecision.navigate;
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller = controller;

    final html = widget.html;
    final url = widget.url;
    if (html != null && html.trim().isNotEmpty) {
      controller.loadHtmlString(html, baseUrl: Api.baseUrl);
    } else if (url != null && url.trim().isNotEmpty) {
      // Chrome may have stored localhost; Android must use Api.baseUrl (LAN IP).
      final normalized = rewriteLocalhostToApiBase(url);
      final target = _withShopperQuery(_withPreviewToken(normalized));
      controller.loadRequest(
        Uri.parse(target),
        headers: _authHeaders,
      );
    } else {
      _error = 'Nothing to load';
      _loading = false;
    }
  }

  void _close() {
    // Always dismiss the screen — close is not browser back.
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  Widget _siteBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF71717A),
              fontSize: 15,
            ),
          ),
        ),
      );
    }
    if (kIsWeb) {
      return buildBusinessWebsiteWebFrame(
        viewType: _webViewType,
        url: widget.url != null
            ? _withShopperQuery(_withPreviewToken(widget.url!))
            : null,
        html: widget.html,
        shopper: _shopperPayload(),
        onTrackOrder: _openTrackOrder,
      );
    }
    if (_controller == null) return const SizedBox.shrink();
    return WebViewWidget(controller: _controller!);
  }

  @override
  Widget build(BuildContext context) {
    // Close lives in a Flutter-only strip ABOVE the platform view.
    // On web, HtmlElementView/iframe steals taps from Stack overlays.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    if (_loading)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: CircleCloseButton(onTap: _close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _siteBody()),
        ],
      ),
    );
  }
}
