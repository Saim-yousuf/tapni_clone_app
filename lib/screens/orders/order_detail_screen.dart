import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isBusinessView;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.isBusinessView,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _repo = CatalogRepo();
  CatalogOrder? _order;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await _repo.getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (_order == null) return;
    setState(() => _isUpdating = true);
    final res = await _repo.updateOrderStatus(
      _order!.id,
      CatalogHelper.statusApiValue(status),
    );
    if (!mounted) return;
    setState(() => _isUpdating = false);
    if (res.success) {
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${CatalogHelper.statusLabel(status)}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to update status')),
      );
    }
  }

  void _viewProfile({required String? userId, required String? username}) {
    if (userId == null && (username == null || username.isEmpty)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannedProfileScreen(
          user: userId,
          username: username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? const Center(child: Text('Order not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBanner(status: _order!.status),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    widget.isBusinessView ? 'Customer' : 'Business',
                  ),
                  const SizedBox(height: 10),
                  _PersonCard(
                    name: widget.isBusinessView
                        ? _order!.customerName
                        : _order!.businessName,
                    username: widget.isBusinessView
                        ? _order!.customerUsername
                        : _order!.businessUsername,
                    photoUrl: widget.isBusinessView
                        ? _order!.customerPhoto
                        : _order!.businessPhoto,
                    buttonLabel: 'View Profile',
                    onViewProfile: () => _viewProfile(
                      userId: widget.isBusinessView
                          ? _order!.customerId
                          : _order!.businessId,
                      username: widget.isBusinessView
                          ? _order!.customerUsername
                          : _order!.businessUsername,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Order Info'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Order ID', value: '#${_order!.id.substring(_order!.id.length > 6 ? _order!.id.length - 6 : 0)}'),
                  _InfoRow(label: 'Type', value: CatalogHelper.orderTitleForType(_order!.catalogType).replaceAll('New ', '')),
                  _InfoRow(label: 'Status', value: CatalogHelper.statusLabel(_order!.status)),
                  if (_order!.createdAt != null)
                    _InfoRow(
                      label: 'Date',
                      value: _formatDate(_order!.createdAt!),
                    ),
                  if (_order!.bookingDate != null &&
                      _order!.bookingDate!.isNotEmpty) ...[
                    _InfoRow(label: 'Booking date', value: _order!.bookingDate!),
                    if (_order!.bookingTime != null &&
                        _order!.bookingTime!.isNotEmpty)
                      _InfoRow(label: 'Booking time', value: _order!.bookingTime!),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle('Items'),
                  const SizedBox(height: 10),
                  ..._order!.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.name}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (item.notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.notes,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text('Rs ${item.lineTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rs ${_order!.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isBusinessView && _order!.status == OrderStatus.pending) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle('Update Status'),
                    const SizedBox(height: 12),
                    _StatusButton(
                      label: 'Mark Completed',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      isLoading: _isUpdating,
                      onPressed: () => _updateStatus(OrderStatus.completed),
                    ),
                    const SizedBox(height: 10),
                    _StatusButton(
                      label: 'Cancel Order',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      isLoading: _isUpdating,
                      onPressed: () => _updateStatus(OrderStatus.cancelled),
                    ),
                    const SizedBox(height: 10),
                    _StatusButton(
                      label: 'Customer No Show',
                      icon: Icons.person_off_outlined,
                      color: Colors.grey.shade700,
                      isLoading: _isUpdating,
                      onPressed: () => _updateStatus(OrderStatus.noShow),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  const _StatusBanner({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.noShow:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _color),
          const SizedBox(width: 10),
          Text(
            CatalogHelper.statusLabel(status),
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String name;
  final String username;
  final String? photoUrl;
  final String buttonLabel;
  final VoidCallback onViewProfile;

  const _PersonCard({
    required this.name,
    required this.username,
    this.photoUrl,
    required this.buttonLabel,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryBlack,
            backgroundImage:
                photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null || photoUrl!.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (username.isNotEmpty)
                  Text('@$username', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onViewProfile,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
