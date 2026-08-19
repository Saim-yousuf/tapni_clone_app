import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_detail_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _busyId;

  ButtonStyle get _compactFilledStyle => FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(72, 36),
        maximumSize: const Size(double.infinity, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      );

  ButtonStyle get _compactOutlinedStyle => OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(72, 36),
        maximumSize: const Size(double.infinity, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      );

  void _openFollowUser(Map item) {
    final username = (item['username'] as String?)?.trim() ?? '';
    final userId = (item['userId'] as String?)?.trim() ?? '';
    if (username.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(username: username),
        ),
      );
      return;
    }
    if (userId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScannedProfileScreen(user: userId),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      Provider.of<LeadsProvider>(context, listen: false).refreshNotifications(
        isBusinessUser: profileProvider.isProUser,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final notificationsList = leadsProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (notificationsList.isNotEmpty)
            TextButton(
              onPressed: () {
                leadsProvider.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.allNotificationsMarkedAsRead),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(context.l10n.readAll,
                style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: notificationsList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    SizedBox(height: 16),
                    Text(context.l10n.allCaughtUp,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      context.l10n.noNewNotificationsAtThisTime,
                      style: TextStyle(
                        color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: notificationsList.length,
                itemBuilder: (context, index) {
                  final item = notificationsList[index];
                  final isRead = item['isRead'] as bool;
                  
                  return Dismissible(
                    key: Key('${item['type']}_${item['id']}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      leadsProvider.clearNotification(item['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.notificationCleared),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          leadsProvider.toggleNotificationRead(item['id']);
                          if (item['type'] == 'catalog_order' &&
                              profileProvider.isProUser) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  orderId: item['id'],
                                  isBusinessView: true,
                                ),
                              ),
                            );
                          } else if (item['type'] == 'employee_invitation') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EmployeeInvitationsScreen(),
                              ),
                            );
                          } else if (item['type'] == 'event_invitation') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InvitationDetailScreen(
                                  invitationId: item['id'] as String,
                                  invitation: item['invitation'] is EventInvitation
                                      ? item['invitation'] as EventInvitation
                                      : null,
                                ),
                              ),
                            );
                          } else if (item['type'] == 'follow_accepted') {
                            _openFollowUser(item);
                          }
                        },
                        child: GlassCard(
                          borderOpacity: isRead ? 0.05 : 0.15,
                          customBgColor: isRead 
                              ? Colors.transparent
                              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Unread indicator dot
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6, right: 10),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.transparent : AppTheme.accentGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['type'] == 'catalog_order'
                                                ? CatalogHelper.orderTitleForType(
                                                    item['catalogType'] as String? ??
                                                        item['title'] as String?,
                                                    context.l10n,
                                                  )
                                                : item['type'] == 'follow_request'
                                                ? context.l10n.followRequestTitle
                                                : item['type'] == 'follow_accepted'
                                                ? context.l10n.followRequestAcceptedTitle
                                                : item['title'],
                                            style: TextStyle(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
                                              color: isRead 
                                                  ? (isDark ? Colors.white60 : Colors.black87)
                                                  : (isDark ? Colors.white : Colors.black),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          item['time'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: item['type'] == 'follow_request' ||
                                              item['type'] == 'follow_accepted'
                                          ? () => _openFollowUser(item)
                                          : null,
                                      child: Text(
                                        item['type'] == 'follow_request'
                                            ? context.l10n.followRequestBody(
                                                (item['userName'] as String?) ??
                                                    '',
                                              )
                                            : item['type'] == 'follow_accepted'
                                            ? context.l10n.followRequestAcceptedBody(
                                                (item['userName'] as String?) ??
                                                    '',
                                              )
                                            : item['body'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: item['type'] ==
                                                      'follow_request' ||
                                                  item['type'] ==
                                                      'follow_accepted'
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                          color: isRead
                                              ? (isDark
                                                  ? AppTheme.textGreyDark
                                                  : AppTheme.textGreyLight)
                                              : (isDark
                                                  ? Colors.white70
                                                  : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    if (item['type'] == 'follow_request') ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          FilledButton(
                                            onPressed: _busyId == item['id']
                                                ? null
                                                : () async {
                                                    final followId =
                                                        item['id'] as String;
                                                    final l10n = context.l10n;
                                                    final messenger =
                                                        ScaffoldMessenger.of(
                                                      context,
                                                    );
                                                    setState(
                                                      () => _busyId = followId,
                                                    );
                                                    final ok = await leadsProvider
                                                        .acceptFollowRequest(
                                                      followId,
                                                    );
                                                    if (!mounted) return;
                                                    setState(() => _busyId = null);
                                                    messenger.showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          ok
                                                              ? l10n.requestAccepted
                                                              : l10n.somethingWentWrong,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            style: _compactFilledStyle,
                                            child: Text(context.l10n.accept),
                                          ),
                                          OutlinedButton(
                                            onPressed: _busyId == item['id']
                                                ? null
                                                : () async {
                                                    setState(() =>
                                                        _busyId = item['id'] as String);
                                                    await leadsProvider
                                                        .declineFollowRequest(
                                                      item['id'] as String,
                                                    );
                                                    if (!mounted) return;
                                                    setState(() => _busyId = null);
                                                  },
                                            style: _compactOutlinedStyle,
                                            child: Text(context.l10n.decline),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => _openFollowUser(item),
                                            style: _compactOutlinedStyle,
                                            child: Text(context.l10n.profile),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
