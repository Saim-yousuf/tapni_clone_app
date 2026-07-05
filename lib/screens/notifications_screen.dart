import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      Provider.of<LeadsProvider>(context, listen: false).fetchCatalogOrderNotifications(
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
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (notificationsList.isNotEmpty)
            TextButton(
              onPressed: () {
                leadsProvider.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Read All',
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
                    const SizedBox(height: 16),
                    const Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No new notifications at this time.',
                      style: TextStyle(
                        color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: notificationsList.length,
                itemBuilder: (context, index) {
                  final item = notificationsList[index];
                  final isRead = item['isRead'] as bool;
                  
                  return Dismissible(
                    key: Key(item['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      leadsProvider.clearNotification(item['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification cleared'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          leadsProvider.toggleNotificationRead(item['id']);
                          if (item['type'] == 'catalog_order' && profileProvider.isProUser) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  orderId: item['id'],
                                  isBusinessView: true,
                                ),
                              ),
                            );
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
                                            item['title'],
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
                                    Text(
                                      item['body'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isRead 
                                            ? (isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight)
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
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
