import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/screens/explore_delivery_map_picker_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/app_map_tiles.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Save Address sheet — map pin + street (required); apt / building / access optional.
Future<bool> showExploreDeliveryAddressSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _ExploreDeliveryAddressSheet(),
  );
  return result == true;
}

class _ExploreDeliveryAddressSheet extends StatefulWidget {
  const _ExploreDeliveryAddressSheet();

  @override
  State<_ExploreDeliveryAddressSheet> createState() =>
      _ExploreDeliveryAddressSheetState();
}

class _ExploreDeliveryAddressSheetState
    extends State<_ExploreDeliveryAddressSheet> {
  late final TextEditingController _lineCtrl;
  late final TextEditingController _aptCtrl;
  late final TextEditingController _entryCtrl;
  late final TextEditingController _buildingCtrl;
  late final TextEditingController _notesCtrl;
  double? _lat;
  double? _lng;
  /// hand | door
  String _dropOff = 'hand';
  bool _showOptional = false;

  static const _fieldStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  @override
  void initState() {
    super.initState();
    final cart = context.read<ExploreCartProvider>();
    _lineCtrl = TextEditingController(text: cart.deliveryLine);
    _aptCtrl = TextEditingController(text: cart.deliveryApt);
    _entryCtrl = TextEditingController(text: cart.deliveryEntry);
    _buildingCtrl = TextEditingController(text: cart.deliveryBuilding);
    _notesCtrl = TextEditingController(text: cart.deliveryNotes);
    _lat = cart.deliveryLat;
    _lng = cart.deliveryLng;
    _showOptional = cart.deliveryApt.trim().isNotEmpty ||
        cart.deliveryEntry.trim().isNotEmpty ||
        cart.deliveryBuilding.trim().isNotEmpty ||
        cart.deliveryNotes.trim().isNotEmpty;
    if (cart.deliveryNotes.contains('Leave at my door')) {
      _dropOff = 'door';
    }
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _aptCtrl.dispose();
    _entryCtrl.dispose();
    _buildingCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, {String? helper}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: BarqodyChrome.secondaryText,
      ),
      helperStyle: const TextStyle(
        fontSize: 12,
        color: BarqodyChrome.secondaryText,
      ),
      filled: true,
      fillColor: BarqodyChrome.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );
  }

  Future<void> _pickMap() async {
    final result = await ExploreDeliveryMapPickerScreen.open(
      context,
      initialLatitude: _lat,
      initialLongitude: _lng,
      initialQuery: _lineCtrl.text.trim(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      final label = result.label.trim();
      if (label.isNotEmpty) {
        _lineCtrl.text = label;
      } else if (_lineCtrl.text.trim().isEmpty) {
        _lineCtrl.text =
            '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
      }
    });
  }

  void _save() {
    final line = _lineCtrl.text.trim();
    if (line.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Street address is required')),
      );
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a pin on the map')),
      );
      return;
    }
    var notes = _notesCtrl.text.trim();
    // Strip previous auto drop-off tags before re-applying.
    notes = notes
        .replaceAll(RegExp(r'(^|\s·\s)Leave at my door'), '')
        .replaceAll(RegExp(r'(^|\s·\s)Hand it to me'), '')
        .trim();
    final tag = _dropOff == 'door' ? 'Leave at my door' : 'Hand it to me';
    notes = notes.isEmpty ? tag : '$tag · $notes';

    context.read<ExploreCartProvider>().setDeliveryAddress(
          line: line,
          apt: _aptCtrl.text,
          entry: _entryCtrl.text,
          building: _buildingCtrl.text,
          notes: notes,
          lat: _lat,
          lng: _lng,
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Save Address',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CircleCloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickMap,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BarqodyChrome.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(
                            child: FlutterMap(
                              key: ValueKey(
                                '${_lat?.toStringAsFixed(5) ?? 'x'}_'
                                '${_lng?.toStringAsFixed(5) ?? 'y'}',
                              ),
                              options: MapOptions(
                                initialCenter: LatLng(
                                  _lat ?? 31.5204,
                                  _lng ?? 74.3587,
                                ),
                                initialZoom: _lat != null ? 15.5 : 12.5,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                AppMapTiles.street(),
                                if (_lat != null && _lng != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(_lat!, _lng!),
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.topCenter,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.black,
                                          size: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              color: Colors.white.withValues(alpha: 0.92),
                              child: Text(
                                _lat != null
                                    ? 'Tap to change location'
                                    : 'Pick on map',
                                textAlign: TextAlign.center,
                                style: WaUi.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Street address',
                style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lineCtrl,
                maxLines: 2,
                style: _fieldStyle,
                cursorColor: Colors.black,
                decoration: _dec('House / street / area'),
              ),
              const SizedBox(height: 8),
              Text(
                'Required · filled from map or search',
                style: WaUi.label.copyWith(
                  color: BarqodyChrome.secondaryText,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Drop-off',
                style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DropChip(
                      label: 'Hand it to me',
                      selected: _dropOff == 'hand',
                      onTap: () => setState(() => _dropOff = 'hand'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropChip(
                      label: 'Leave at my door',
                      selected: _dropOff == 'door',
                      onTap: () => setState(() => _dropOff = 'door'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showOptional = !_showOptional),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Apartment, access & notes (optional)',
                            style: WaUi.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          _showOptional
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _aptCtrl,
                      style: _fieldStyle,
                      cursorColor: Colors.black,
                      decoration: _dec('Apartment / floor / suite'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _buildingCtrl,
                      style: _fieldStyle,
                      cursorColor: Colors.black,
                      decoration: _dec('Building / landmark'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _entryCtrl,
                      style: _fieldStyle,
                      cursorColor: Colors.black,
                      decoration: _dec('Gate / entry / buzzer code'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      style: _fieldStyle,
                      cursorColor: Colors.black,
                      decoration: _dec(
                        'Delivery instructions',
                        helper:
                            'Parking, security, which entrance, call on arrival…',
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
                crossFadeState: _showOptional
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Save Address',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DropChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
