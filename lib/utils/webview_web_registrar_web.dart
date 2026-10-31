import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

/// Registers the web implementation of [WebViewPlatform].
void registerWebViewWebPlatform() {
  WebViewPlatform.instance = WebWebViewPlatform();
}
