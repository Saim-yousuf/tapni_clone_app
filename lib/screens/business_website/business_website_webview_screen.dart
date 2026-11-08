import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/business_website/bw_flutter_commerce_bridge.dart';
import 'package:tapni_app/screens/business_website/bw_web_frame.dart';
import 'package:tapni_app/screens/explore_cart_screen.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/own_catalog_guard.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/catalog_item_configurator_sheet.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tapni_app/widgets/app_toast.dart';

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
  /// Only the first document load — avoid shimmer flashes on in-site nav.
  bool _initialLoading = true;
  /// When true, Ember (etc.) owns back/cart; Flutter floating chrome is hidden.
  bool _templateOwnsChrome = false;
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
      AppPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: id,
          isBusinessView: false,
          accessToken: token.isEmpty ? null : token,
        ),
      ),
    );
  }

  void _openNativeCart() {
    if (!mounted || widget.sampleDemoPreview) return;
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => const ExploreCartScreen()),
    );
  }

  Future<void> _handleAdjustCartQty(BwBridgeAdjustCartQty payload) async {
    if (!mounted || widget.sampleDemoPreview) return;
    final cart = context.read<ExploreCartProvider>();
    final vendors = cart.vendors;
    final vIdx = vendors.indexWhere((v) {
      if (payload.businessLinkId.isNotEmpty &&
          v.businessLinkId == payload.businessLinkId) {
        return true;
      }
      return v.businessId == payload.businessId;
    });
    if (vIdx < 0) {
      unawaited(_injectNativeCartToWeb(
        businessId: payload.businessId,
        websiteSlug: payload.websiteSlug,
      ));
      return;
    }
    final vendor = vendors[vIdx];
    final lineIdx = vendor.lines.indexWhere((line) {
      final id = line.item.id.trim();
      if (payload.catalogItemId.isNotEmpty && id == payload.catalogItemId) {
        return true;
      }
      if (payload.catalogItemId.isEmpty &&
          payload.name.isNotEmpty &&
          line.item.name.trim() == payload.name) {
        return true;
      }
      return false;
    });
    if (lineIdx < 0) {
      unawaited(_injectNativeCartToWeb(
        businessId: payload.businessId,
        websiteSlug: payload.websiteSlug,
      ));
      return;
    }
    final nextQty = vendor.lines[lineIdx].quantity + payload.delta;
    cart.updateQuantity(
      businessLinkId: vendor.businessLinkId,
      lineIndex: lineIdx,
      quantity: nextQty,
    );
    unawaited(_injectNativeCartToWeb(
      businessId: payload.businessId,
      websiteSlug: payload.websiteSlug,
    ));
  }

  Future<void> _handleAddToCart(BwBridgeAddToCart payload) async {
    if (!mounted || widget.sampleDemoPreview) return;
    if (OwnCatalogGuard.isOwnBusinessOf(
      context,
      businessId: payload.businessId,
      businessUsername: payload.businessUsername,
      websiteSlug: payload.websiteSlug,
    )) {
      showAppToast(
        context,
        OwnCatalogGuard.message,
        kind: AppToastKind.warning,
      );
      // Undo optimistic template cart bump so badge/ATC labels stay correct.
      unawaited(_injectNativeCartToWeb(
        businessId: payload.businessId,
        websiteSlug: payload.websiteSlug,
      ));
      return;
    }

    var line = payload.line;
    if (payload.needsConfiguration && line.item.hasConfiguration) {
      // Template ATC for configured items — Flutter owns the picker UI.
      // Size may already be chosen on the detail page (data-bw-variant-id).
      unawaited(_injectNativeCartToWeb(
        businessId: payload.businessId,
        websiteSlug: payload.websiteSlug,
      ));
      final configured = await showCatalogItemConfiguratorSheet(
        context: context,
        item: line.item,
        currency: payload.currency,
        initialQuantity: line.quantity,
        initialNotes: line.notes,
        initialVariantId:
            line.variantId.isNotEmpty ? line.variantId : null,
      );
      if (configured == null || !mounted) return;
      line = ExploreCartLine(
        item: line.item,
        quantity: configured.quantity,
        notes: configured.notes,
        bookingDate: line.bookingDate,
        bookingTime: line.bookingTime,
        resourceId: line.resourceId,
        resourceName: line.resourceName,
        checkInDate: line.checkInDate,
        checkOutDate: line.checkOutDate,
        bookingKind: line.bookingKind,
        variantId: configured.variantId,
        optionIds: configured.optionIds,
        configurationLabel: configured.configurationLabel,
      );
    }

    final cart = context.read<ExploreCartProvider>();
    cart.addItem(
      businessId: payload.businessId,
      // Prefer real catalog link id; never substitute businessId (breaks
      // findCatalogLink-by-id on authenticated placeOrder fallbacks).
      businessLinkId: payload.businessLinkId.isNotEmpty
          ? payload.businessLinkId
          : 'website:${payload.websiteSlug.isNotEmpty ? payload.websiteSlug : payload.businessId}',
      businessName: payload.businessName,
      businessUsername: payload.businessUsername,
      catalogType: payload.catalogType,
      currency: payload.currency,
      websiteSlug: payload.websiteSlug,
      ordersPaused: payload.ordersPaused,
      isClosedNow: payload.isClosedNow,
      catalogItems: [line.item],
      line: line,
    );
    // Keep detail-page ATC label in sync (In cart · Add more).
    unawaited(_injectNativeCartToWeb(
      businessId: payload.businessId,
      websiteSlug: payload.websiteSlug,
    ));
    showAppToast(
      context,
      '${line.item.name} added to cart',
      kind: AppToastKind.success,
      actionLabel: 'View cart',
      onAction: _openNativeCart,
    );
  }

  /// Push native cart lines into the template so ATC buttons show in-cart state.
  Future<void> _injectNativeCartToWeb({
    String businessId = '',
    String websiteSlug = '',
  }) async {
    final controller = _controller;
    if (controller == null || widget.sampleDemoPreview) return;
    final cart = context.read<ExploreCartProvider>();
    final bid = businessId.trim();
    final slug = websiteSlug.trim().toLowerCase();
    final lines = <Map<String, dynamic>>[];
    for (final vendor in cart.vendors) {
      if (vendor.lines.isEmpty) continue;
      final vBid = vendor.businessId.trim();
      final vSlug = vendor.websiteSlug.trim().toLowerCase();
      final match = (bid.isNotEmpty && vBid == bid) ||
          (slug.isNotEmpty && vSlug == slug) ||
          (bid.isEmpty && slug.isEmpty);
      if (!match) continue;
      for (final line in vendor.lines) {
        lines.add({
          'catalogItemId': line.item.id,
          'name': line.item.name,
          'quantity': line.quantity,
        });
      }
    }
    // Never wipe an optimistic JS bump with [] when Flutter cart has lines but
    // vendor id/slug matching missed (badge would disappear after ATC).
    if (lines.isEmpty && cart.itemCount > 0) {
      for (final vendor in cart.vendors) {
        for (final line in vendor.lines) {
          lines.add({
            'catalogItemId': line.item.id,
            'name': line.item.name,
            'quantity': line.quantity,
          });
        }
      }
    }
    final payload = jsonEncode(lines);
    await controller.runJavaScript('''
      (function(){
        try{
          var lines=$payload;
          if(typeof window.__BW_SET_NATIVE_CART==='function'){
            window.__BW_SET_NATIVE_CART(lines);
            return;
          }
          window.__BW_NATIVE_CART=lines;
          var n=lines.reduce(function(s,i){ return s+(Number(i.quantity)||1); },0);
          document.querySelectorAll('[data-bw-cart-badge]').forEach(function(el){
            el.textContent=String(n);
            if(n<1){ el.hidden=true; el.setAttribute('hidden','hidden'); }
            else { el.hidden=false; el.removeAttribute('hidden'); }
          });
          document.querySelectorAll('[data-bw-shared-cart-fab]').forEach(function(el){
            if(n<1){ el.hidden=true; el.setAttribute('hidden','hidden'); }
            else { el.hidden=false; el.removeAttribute('hidden'); }
          });
          if(typeof window.__BW_SYNC_ADD_BUTTONS==='function'){
            window.__BW_SYNC_ADD_BUTTONS();
          }
        }catch(e){}
      })();
    ''');
  }

  void _handleBridgeMessage(String rawMessage) {
    if (widget.sampleDemoPreview) return;
    final raw = rawMessage.trim();
    if (raw.isEmpty) return;

    Map<String, dynamic>? decoded;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        decoded = Map<String, dynamic>.from(parsed);
      }
    } catch (_) {
      decoded = null;
    }

    if (decoded != null) {
      final action = decoded['action']?.toString() ?? '';
      if (action == 'closeWebsite' || action == 'close') {
        _close();
        return;
      }
      if (action == 'immersiveNav') {
        final enabled = decoded['enabled'] != false;
        _applyTemplateOwnsChrome(enabled);
        return;
      }
      if (action == 'trackOrder') {
        final id = decoded['orderId']?.toString() ?? '';
        final token = decoded['token']?.toString();
        _openTrackOrder(id, accessToken: token);
        return;
      }
      if (BwFlutterCommerceBridge.isOpenCart(decoded)) {
        final ordering = BwFlutterCommerceBridge.parseOpenCartSite(decoded);
        if (ordering != null) {
          context.read<ExploreCartProvider>().updateVendorOrderingStatus(
                businessId: ordering.businessId,
                websiteSlug: ordering.websiteSlug,
                ordersPaused: ordering.ordersPaused,
                isClosedNow: ordering.isClosedNow,
              );
        }
        _openNativeCart();
        return;
      }
      final add = BwFlutterCommerceBridge.parseAddToCart(decoded);
      if (add != null) {
        _handleAddToCart(add);
        return;
      }
      final adjust = BwFlutterCommerceBridge.parseAdjustCartQty(decoded);
      if (adjust != null) {
        _handleAdjustCartQty(adjust);
        return;
      }
      // Unknown structured action — ignore (do not treat as order id).
      if (action.isNotEmpty) return;
    }

    // Plain order id fallback (legacy).
    _openTrackOrder(raw);
  }

  Future<void> _injectFlutterAppFlag() async {
    final controller = _controller;
    if (controller == null || widget.sampleDemoPreview) return;
    await controller.runJavaScript('''
      (function(){
        window.__BW_FLUTTER_APP=true;
        try{ document.documentElement.classList.add('bw-flutter'); }catch(e){}
        try{
          if(typeof window.__BW_ON_FLUTTER_APP==='function') window.__BW_ON_FLUTTER_APP();
        }catch(e){}
      })();
    ''');
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
    // Immersive templates own safe-area in their app-nav / detail header.
    if (_templateOwnsChrome) return 0;
    // Web: close strip sits outside the iframe — no inset.
    if (kIsWeb) return 0;
    // Native: floating close overlays the site — reserve top inset.
    final top = MediaQuery.paddingOf(context).top;
    return (top + 52).round();
  }

  void _applyTemplateOwnsChrome(bool enabled) {
    if (!mounted) return;
    if (_templateOwnsChrome == enabled) {
      _injectChromeInsets();
      return;
    }
    setState(() => _templateOwnsChrome = enabled);
    _injectChromeInsets();
  }

  Future<void> _detectImmersiveNav() async {
    final controller = _controller;
    if (controller == null || widget.sampleDemoPreview) return;
    try {
      final raw = await controller.runJavaScriptReturningResult(
        "(function(){try{return!!document.querySelector('[data-bw-immersive-nav]');}catch(e){return false;}})()",
      );
      final text = '$raw'.toLowerCase();
      final enabled = text == 'true' || text == '1';
      _applyTemplateOwnsChrome(enabled);
    } catch (_) {}
  }

  Future<void> _onAndroidBack() async {
    final controller = _controller;
    if (controller != null) {
      try {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return;
        }
      } catch (_) {}
    }
    _close();
  }

  void _retryLoad() {
    final controller = _controller;
    if (controller == null) {
      setState(() {
        _error = null;
        _initialLoading = true;
      });
      _initNativeWebView();
      return;
    }
    setState(() {
      _error = null;
      _initialLoading = true;
    });
    final html = widget.html;
    final url = widget.url;
    if (html != null && html.trim().isNotEmpty) {
      controller.loadHtmlString(html, baseUrl: Api.baseUrl);
    } else if (url != null && url.trim().isNotEmpty) {
      final normalized = rewriteLocalhostToApiBase(url);
      final target = _withShopperQuery(_withPreviewToken(normalized));
      controller.loadRequest(Uri.parse(target), headers: _authHeaders);
    }
  }

  String _withAppChromeQuery(String url) {
    try {
      final uri = Uri.parse(url);
      final q = Map<String, String>.from(uri.queryParameters);
      q['bw_chrome'] = '${_chromeTopPx(context)}';
      // Early signal for commerce runtime before JS injection finishes.
      if (!widget.sampleDemoPreview) q['bw_app'] = '1';
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
  /// Also injects `--bw-safe-*` because Android WebView often reports
  /// `env(safe-area-inset-*)` as 0 — without this, template nav buttons clip
  /// under the status bar in immersive mode.
  Future<void> _injectChromeInsets() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final chromeTop = _chromeTopPx(context);
    final pad = MediaQuery.paddingOf(context);
    await controller.runJavaScript('''
      (function(){
        var r=document.documentElement.style;
        r.setProperty('--bw-chrome-top','${chromeTop}px');
        r.setProperty('--bw-safe-top','${pad.top.round()}px');
        r.setProperty('--bw-safe-right','${pad.right.round()}px');
        r.setProperty('--bw-safe-bottom','${pad.bottom.round()}px');
        r.setProperty('--bw-safe-left','${pad.left.round()}px');
      })();
    ''');
  }

  Future<void> _injectShopper() async {
    final controller = _controller;
    if (controller == null) return;
    final shopper = _shopperPayload();
    if (shopper.isEmpty) return;
    // Only inject when we have a JWT — name/phone prefill alone must not
    // look like an authenticated session (and must not wipe a real one).
    // Token stays in JS memory for website checkout identity only; native
    // Flutter checkout never reads prices/tokens from the WebView for trust.
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
      _initialLoading = false;
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
      ..enableZoom(false)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setOnJavaScriptAlertDialog((request) async {
        if (!mounted) return;
        showAppToast(
              context,
              request.message,
              kind: AppToastKind.info,
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
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            // Intentionally no shimmer on subsequent in-site navigations.
          },
          onPageFinished: (_) async {
            await _injectChromeInsets();
            // Do not inject shopper JWT / flutter flag into synthetic samples.
            if (!widget.sampleDemoPreview) {
              await _injectFlutterAppFlag();
              await _detectImmersiveNav();
              await _injectChromeInsets();
              await _injectShopper();
              await _injectNativeCartToWeb();
            }
            if (mounted) {
              setState(() {
                _initialLoading = false;
                _error = null;
              });
            }
          },
          onWebResourceError: (error) {
            // Fonts / images / Stripe iframes fail often — never replace the
            // whole restaurant UI unless the main document failed.
            if (error.isForMainFrame != true) return;
            if (!mounted) return;
            setState(() {
              _initialLoading = false;
              _error = error.description;
            });
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

            // In-app: never open the website shared cart / checkout page.
            if (!widget.sampleDemoPreview) {
              final path = uri.path.toLowerCase();
              if (path.contains('/p/cart') || path.endsWith('/cart')) {
                _openNativeCart();
                return NavigationDecision.prevent;
              }
            }

            // Sample preview: cart screen must never open.
            if (widget.sampleDemoPreview) {
              final pageKey = (uri.queryParameters['pageKey'] ?? '').toLowerCase();
              final pageSlug =
                  (uri.queryParameters['pageSlug'] ?? '').toLowerCase();
              final pageType =
                  (uri.queryParameters['pageType'] ?? '').toLowerCase();
              final path = uri.path.toLowerCase();
              final isCart = pageKey == 'cart' ||
                  pageSlug == 'cart' ||
                  pageType == 'cart' ||
                  path.contains('/p/cart') ||
                  path.endsWith('/cart');
              if (isCart) {
                return NavigationDecision.prevent;
              }
            }

            // Phase 2B: sample detail pages load via preview API with JWT.
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
      _initialLoading = false;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Couldn’t load this restaurant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _retryLoad,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _close,
                child: const Text('Go back'),
              ),
            ],
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
        shopper: widget.sampleDemoPreview ? null : _shopperPayload(),
        flutterApp: !widget.sampleDemoPreview,
        onTrackOrder: widget.sampleDemoPreview ? null : _openTrackOrder,
        onAddToCart: widget.sampleDemoPreview ? null : _handleAddToCart,
        onAdjustCartQty:
            widget.sampleDemoPreview ? null : _handleAdjustCartQty,
        onOpenCart: widget.sampleDemoPreview ? null : _openNativeCart,
        onCloseWebsite: widget.sampleDemoPreview ? null : _close,
        onImmersiveNav: widget.sampleDemoPreview
            ? null
            : (enabled) => _applyTemplateOwnsChrome(enabled),
      );
    }
    if (_controller == null) return const SizedBox.shrink();
    return WebViewWidget(controller: _controller!);
  }

  Widget _chromeControls({required int cartCount}) {
    // Explicit MediaQuery insets (not nested SafeArea inside Positioned) so
    // close/cart stay inside the visible viewport on notched / small devices.
    final pad = MediaQuery.paddingOf(context);
    final left = pad.left > 12 ? pad.left : 12.0;
    final right = pad.right > 12 ? pad.right : 12.0;
    return Padding(
      padding: EdgeInsets.only(top: pad.top, left: left, right: right),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            CircleCloseButton(onTap: _close),
            const Spacer(),
            if (!widget.sampleDemoPreview)
              _WebViewCartButton(
                count: cartCount,
                onTap: _openNativeCart,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = widget.sampleDemoPreview
        ? 0
        : context.watch<ExploreCartProvider>().itemCount;
    final showFlutterChrome = !_templateOwnsChrome;

    // Web iframe steals overlay taps — keep a thin strip above the view unless
    // the template opted into immersive nav (Ember Kitchen).
    if (kIsWeb) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showFlutterChrome)
                ColoredBox(
                  color: Colors.white,
                  child: _chromeControls(cartCount: cartCount),
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _siteBody()),
                    if (_initialLoading && _error == null)
                      const Positioned.fill(
                        child: _RestaurantSiteShimmer(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onAndroidBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(child: _siteBody()),
            if (showFlutterChrome)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _chromeControls(cartCount: cartCount),
              ),
            if (_initialLoading && _error == null)
              const Positioned.fill(
                child: _RestaurantSiteShimmer(),
              ),
          ],
        ),
      ),
    );
  }
}

class _WebViewCartButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _WebViewCartButton({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/png/bag-icon.png',
                width: 20,
                height: 20,
                color: Colors.black,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.shopping_bag_outlined,
                  size: 22,
                  color: Colors.black,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ember-like menu skeleton — B&W shimmer while the restaurant page loads.
class _RestaurantSiteShimmer extends StatelessWidget {
  const _RestaurantSiteShimmer();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: Colors.white,
      child: AppShimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
          children: [
            Row(
              children: [
                const ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
                const SizedBox(width: 12),
                const Expanded(
                  child: ShimmerBox(width: double.infinity, height: 16, borderRadius: 8),
                ),
                const SizedBox(width: 12),
                const ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 72, height: 72, borderRadius: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 180, height: 22, borderRadius: 8),
                      SizedBox(height: 10),
                      ShimmerBox(width: double.infinity, height: 12, borderRadius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 140, height: 12, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const ShimmerBox(width: double.infinity, height: 44, borderRadius: 14),
            const SizedBox(height: 22),
            const ShimmerBox(width: 120, height: 18, borderRadius: 8),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 136, height: 136, borderRadius: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 96, height: 12, borderRadius: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                ShimmerBox(width: 44, height: 14, borderRadius: 6),
                SizedBox(width: 16),
                ShimmerBox(width: 64, height: 14, borderRadius: 6),
                SizedBox(width: 16),
                ShimmerBox(width: 52, height: 14, borderRadius: 6),
                SizedBox(width: 16),
                ShimmerBox(width: 56, height: 14, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 20),
            const ShimmerBox(width: 100, height: 18, borderRadius: 8),
            const SizedBox(height: 14),
            for (var i = 0; i < 4; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 160, height: 14, borderRadius: 6),
                        SizedBox(height: 8),
                        ShimmerBox(width: double.infinity, height: 10, borderRadius: 6),
                        SizedBox(height: 6),
                        ShimmerBox(width: 120, height: 10, borderRadius: 6),
                        SizedBox(height: 10),
                        ShimmerBox(width: 64, height: 14, borderRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const ShimmerBox(width: 108, height: 108, borderRadius: 14),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
