import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/services/account_storage.dart';

/// Blocks shoppers from ordering against a catalog they own.
class OwnCatalogGuard {
  OwnCatalogGuard._();

  static const message = 'You cannot place an order on your own catalog';

  static String _normUser(String value) =>
      value.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');

  static String currentUserId(BuildContext context) {
    try {
      final id = (context.read<ProfileProvider>().profile.id ?? '').trim();
      if (id.isNotEmpty) return id;
    } catch (_) {}
    final accountId = AccountStorage.getActiveAccount()?.userId.trim() ?? '';
    if (accountId.isNotEmpty && accountId != 'legacy') return accountId;
    return '';
  }

  static String currentUsername(BuildContext context) {
    try {
      return _normUser(
        context.read<ProfileProvider>().profile.username ?? '',
      );
    } catch (_) {
      return '';
    }
  }

  /// True when [businessId] / username / website slug belongs to the signed-in user.
  static bool isOwnBusiness({
    required String myUserId,
    required String myUsername,
    String businessId = '',
    String businessUsername = '',
    String websiteSlug = '',
  }) {
    final me = myUserId.trim();
    final uname = _normUser(myUsername);
    final bid = businessId.trim();
    final bun = _normUser(businessUsername);
    final slug = _normUser(websiteSlug);

    if (me.isNotEmpty && bid.isNotEmpty && me == bid) return true;
    if (uname.isNotEmpty) {
      if (bun.isNotEmpty && bun == uname) return true;
      if (slug.isNotEmpty && slug == uname) return true;
    }
    return false;
  }

  static bool isOwnBusinessOf(
    BuildContext context, {
    String businessId = '',
    String businessUsername = '',
    String websiteSlug = '',
  }) {
    return isOwnBusiness(
      myUserId: currentUserId(context),
      myUsername: currentUsername(context),
      businessId: businessId,
      businessUsername: businessUsername,
      websiteSlug: websiteSlug,
    );
  }
}
