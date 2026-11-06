import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/screens/business_website/content_item_form_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class BusinessContentListScreen extends StatefulWidget {
  final String contentType;
  final String title;
  final List<BusinessContentCategory> categories;

  const BusinessContentListScreen({
    super.key,
    required this.contentType,
    required this.title,
    this.categories = const [],
  });

  @override
  State<BusinessContentListScreen> createState() =>
      _BusinessContentListScreenState();
}

class _BusinessContentListScreenState extends State<BusinessContentListScreen> {
  final _repo = BusinessWebsiteRepo();
  List<BusinessContentItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.listContent(type: widget.contentType);
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load items';
      });
      return;
    }
    setState(() {
      _items = _repo.parseContentItems(res.data);
      _loading = false;
    });
  }

  Future<void> _openForm({BusinessContentItem? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      AppPageRoute(
        builder: (_) => ContentItemFormScreen(
          contentType: widget.contentType,
          existing: existing,
          categories: widget.categories,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(BusinessContentItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.deleteContent(item.id);
    if (!mounted) return;
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Delete failed',
            kind: AppToastKind.error,
          );
      return;
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwUi.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: widget.title,
              onBack: () => Navigator.of(context).pop(true),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AuthUi.textSecondary),
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(
                              child: Text(
                                'No items yet. Tap + to add.',
                                style: TextStyle(color: AuthUi.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openForm(existing: item),
                                    onLongPress: () => _delete(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: BwUi.cardBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: item.image.isNotEmpty
                                                ? Image.network(
                                                    item.image,
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        _iconTile(),
                                                  )
                                                : _iconTile(),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (item.price.isNotEmpty)
                                                  Text(
                                                    item.price,
                                                    style: const TextStyle(
                                                      color:
                                                          AuthUi.textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Color(0xFFC7C7CC),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _iconTile() {
    return Container(
      width: 52,
      height: 52,
      color: BwUi.iconTileBg,
      child: Icon(
        BwUi.contentIcon(widget.contentType),
        color: Colors.black87,
      ),
    );
  }
}
