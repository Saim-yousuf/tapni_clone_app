import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/bookable_resource.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/booking_repo.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_guide_sheet.dart';
import 'package:tapni_app/utils/api_error_messages.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/connection_error_state.dart';

/// Owner CRUD for rooms / tables / assets that appear in public booking.
/// Staff specialists are managed via Team Attendance → bookable toggle.
class BookableResourcesScreen extends StatefulWidget {
  const BookableResourcesScreen({super.key});

  @override
  State<BookableResourcesScreen> createState() =>
      _BookableResourcesScreenState();
}

enum _ResFilter { all, room, table, asset, staff }

class _BookableResourcesScreenState extends State<BookableResourcesScreen> {
  final _repo = BookingRepo();
  List<BookableResource> _items = [];
  bool _loading = true;
  String? _error;
  _ResFilter _filter = _ResFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  String get _businessId =>
      context.read<ProfileProvider>().profile.id?.trim() ?? '';

  Future<void> _load() async {
    final id = _businessId;
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Business profile not loaded';
        _items = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.listMine(businessId: id);
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message?.trim().isNotEmpty == true
            ? res.message!.trim()
            : 'Could not load resources';
        _items = [];
      });
      return;
    }
    final raw = res.data is List
        ? res.data as List
        : (res.data is Map && res.data['data'] is List
            ? res.data['data'] as List
            : <dynamic>[]);
    setState(() {
      _loading = false;
      _error = null;
      _items = raw
          .map((e) => BookableResource.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  List<BookableResource> get _visible {
    switch (_filter) {
      case _ResFilter.all:
        return _items;
      case _ResFilter.room:
        return _items.where((e) => e.type == 'room').toList();
      case _ResFilter.table:
        return _items.where((e) => e.type == 'table').toList();
      case _ResFilter.asset:
        return _items.where((e) => e.type == 'asset').toList();
      case _ResFilter.staff:
        return _items.where((e) => e.type == 'staff').toList();
    }
  }

  Future<void> _showEditor({BookableResource? existing}) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final tokenCtrl = TextEditingController(text: existing?.tableToken ?? '');
    var type = existing?.type ?? 'room';
    if (type == 'staff') {
      // Staff rows are attendance-driven; allow rename only.
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit resource' : 'Add resource',
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      CircleCloseButton(onTap: () => Navigator.pop(ctx, false)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type == 'staff'
                        ? 'Specialists are toggled from Team Attendance. You can rename here.'
                        : 'Rooms for hotels, tables for restaurants, assets like chairs.',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  if (!isEdit || existing.type != 'staff') ...[
                    const SizedBox(height: 16),
                    Text(
                      'TYPE',
                      style: WaUi.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final t in ['room', 'table', 'asset'])
                          ChoiceChip(
                            label: Text(t[0].toUpperCase() + t.substring(1)),
                            selected: type == t,
                            onSelected: isEdit
                                ? null
                                : (_) => setLocal(() => type = t),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: type == 'room'
                          ? 'e.g. Deluxe King'
                          : type == 'table'
                              ? 'e.g. Table 4'
                              : 'e.g. Chair A',
                      filled: true,
                      fillColor: BarqodyChrome.fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (type == 'table') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: tokenCtrl,
                      decoration: InputDecoration(
                        labelText: 'Table QR token',
                        hintText: 'e.g. t4',
                        filled: true,
                        fillColor: BarqodyChrome.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(isEdit ? 'Save' : 'Add'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    final token = tokenCtrl.text.trim();
    tokenCtrl.dispose();
    if (ok != true || name.isEmpty) return;

    final ApiResponse res;
    if (isEdit) {
      res = await _repo.updateResource(
        existing.id,
        name: name,
        tableToken: existing.type == 'table' ? token : null,
      );
    } else {
      res = await _repo.createResource(
        type: type,
        name: name,
        tableToken: type == 'table' ? token : '',
      );
    }
    if (!mounted) return;
    showSnackBar(
      context,
      res.success
          ? (isEdit ? 'Saved' : 'Added')
          : (res.message ?? 'Could not save'),
      isError: !res.success,
    );
    if (res.success) _load();
  }

  Future<void> _toggleActive(BookableResource item) async {
    final res = await _repo.updateResource(
      item.id,
      isActive: !item.isActive,
    );
    if (!mounted) return;
    if (!res.success) {
      showSnackBar(context, res.message ?? 'Update failed', isError: true);
      return;
    }
    _load();
  }

  Future<void> _deactivate(BookableResource item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Remove from booking?'),
        content: Text(
          '"${item.name}" will no longer appear for customers. You can add it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _repo.deleteResource(item.id);
    if (!mounted) return;
    showSnackBar(
      context,
      res.success ? 'Removed' : (res.message ?? 'Failed'),
      isError: !res.success,
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Rooms & tables',
              trailing: CircleAssetButton(
                asset: 'assets/images/png/plus-icon.png',
                iconSize: 16,
                onTap: () => _showEditor(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                0,
                BarqodyChrome.sidePad,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage what customers can book. Doctors & stylists: Team Attendance → Offer as bookable specialist.',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      height: 1.35,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showBusinessWebsiteSetupGuide(
                      context,
                      openAudience: GuideAudience.business,
                    ),
                    child: Text(
                      'Business guide',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: BarqodyChrome.sidePad,
                ),
                children: [
                  for (final f in _ResFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: switch (f) {
                          _ResFilter.all => 'All',
                          _ResFilter.room => 'Rooms',
                          _ResFilter.table => 'Tables',
                          _ResFilter.asset => 'Assets',
                          _ResFilter.staff => 'Staff',
                        },
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (_error != null) {
      return ConnectionErrorState(
        message: ApiErrorMessages.sanitize(_error!),
        onRetry: _load,
      );
    }
    final list = _visible;
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: const _EmptyState(
                title: 'Nothing to book yet',
                subtitle:
                    'Add hotel rooms or restaurant tables so customers can reserve them on your website.',
              ),
            ),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: const [
            SizedBox(
              height: 280,
              child: _EmptyState(
                title: 'No items in this filter',
                subtitle: 'Try another tab or add a new resource.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          BarqodyChrome.sidePad,
          4,
          BarqodyChrome.sidePad,
          24,
        ),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: BarqodyChrome.divider,
        ),
        itemBuilder: (_, i) {
          final item = list[i];
          return _ResourceRow(
            item: item,
            onEdit: () => _showEditor(existing: item),
            onToggle: () => _toggleActive(item),
            onRemove: () => _deactivate(item),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.black : const Color(0xFFE0E0E0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6B6B6B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 48,
            color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WaUi.toolsTitleOf(size: 17, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 14,
              height: 1.35,
              color: BarqodyChrome.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final BookableResource item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _ResourceRow({
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = item.type[0].toUpperCase() + item.type.substring(1);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: item.type == 'staff' ? null : onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BarqodyChrome.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.refUserPhoto.isNotEmpty
                    ? Image.network(
                        item.refUserPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          _iconFor(item.type),
                          color: BarqodyChrome.secondaryText,
                        ),
                      )
                    : Icon(
                        _iconFor(item.type),
                        color: BarqodyChrome.secondaryText,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        typeLabel,
                        if (item.tableToken.isNotEmpty) 'QR: ${item.tableToken}',
                        item.isActive ? 'Live' : 'Hidden',
                      ].join(' · '),
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: item.isActive
                            ? BarqodyChrome.secondaryText
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: BarqodyChrome.secondaryText.withValues(alpha: 0.85),
                ),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'toggle') onToggle();
                  if (v == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  if (item.type != 'staff')
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(item.isActive ? 'Hide from booking' : 'Show on booking'),
                  ),
                  if (item.type != 'staff')
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Remove',
                        style: TextStyle(color: Color(0xFFC62828)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'room':
        return Icons.bed_outlined;
      case 'table':
        return Icons.table_restaurant_outlined;
      case 'staff':
        return Icons.person_outline;
      default:
        return Icons.chair_outlined;
    }
  }
}
