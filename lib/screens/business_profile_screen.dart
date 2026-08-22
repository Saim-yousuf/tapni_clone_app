import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/attendance/business/map_location_picker_screen.dart';
import 'package:tapni_app/utils/business_categories.dart';
import 'package:tapni_app/utils/business_completeness.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/radio_option_picker_sheet.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;

  String? _industry;
  double? _latitude;
  double? _longitude;
  bool _saving = false;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.businessName ?? '');
    _addressController =
        TextEditingController(text: profile.businessAddress ?? '');
    _cityController = TextEditingController(text: profile.city ?? '');
    _areaController = TextEditingController(text: profile.area ?? '');
    _industry = profile.businessCategory;
    _latitude = profile.latitude;
    _longitude = profile.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickIndustry() async {
    final selected = await showRadioOptionPickerSheet(
      context: context,
      selectedId: _industry,
      searchHint: context.l10n.businessCategory,
      options: kBusinessCategories
          .map(
            (c) => RadioPickerOption(
              id: c,
              label: businessCategoryLabel(context, c),
            ),
          )
          .toList(),
    );
    if (selected != null) {
      setState(() => _industry = selected);
    }
  }

  Future<void> _pickLocation() async {
    final result = await MapLocationPickerScreen.open(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      radiusMeters: 80,
    );
    if (result == null || !mounted) return;

    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _resolvingAddress = true;
    });

    final geo = await _reverseGeocode(result.latitude, result.longitude);
    if (!mounted) return;
    setState(() {
      _resolvingAddress = false;
      if (geo != null) {
        if ((_addressController.text).trim().isEmpty &&
            (geo['address'] ?? '').isNotEmpty) {
          _addressController.text = geo['address']!;
        }
        if ((_cityController.text).trim().isEmpty &&
            (geo['city'] ?? '').isNotEmpty) {
          _cityController.text = geo['city']!;
        }
        if ((_areaController.text).trim().isEmpty &&
            (geo['area'] ?? '').isNotEmpty) {
          _areaController.text = geo['area']!;
        }
      }
    });
  }

  Future<Map<String, String>?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'BarqodyApp/1.0'},
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final address = (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
      final display = (json['display_name']?.toString() ?? '').trim();
      final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state_district'] ??
              '')
          .toString();
      final area = (address['suburb'] ??
              address['neighbourhood'] ??
              address['county'] ??
              '')
          .toString();
      return {
        'address': display,
        'city': city,
        'area': area,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('Business name is required');
      return;
    }
    if ((_industry ?? '').trim().isEmpty) {
      _toast('Industry category is required');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _toast('Please set your business location on the map');
      return;
    }

    setState(() => _saving = true);
    final response = await Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).updateBusinessProfile(
      businessName: name,
      businessCategory: _industry!.trim(),
      latitude: _latitude,
      longitude: _longitude,
      businessAddress: _addressController.text.trim(),
      city: _cityController.text.trim(),
      area: _areaController.text.trim(),
      context: context,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (response.success) {
      Navigator.pop(context, true);
      return;
    }
    _toast(response.message ?? 'Could not save business profile');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: WaUi.body.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WaUi.primaryText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completeness = BusinessCompleteness(
      hasName: _nameController.text.trim().isNotEmpty,
      hasIndustry: (_industry ?? '').trim().isNotEmpty,
      hasLocation: _latitude != null && _longitude != null,
    );

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Business Profile',
          style: WaUi.headline.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WaUi.searchBg,
              borderRadius: BorderRadius.circular(WaUi.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: WaUi.secondaryText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Public listing details for Explore. Workplace attendance uses a separate location.',
                    style: WaUi.body.copyWith(color: WaUi.secondaryText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completeness.progressLabel,
            style: WaUi.label.copyWith(
              color: completeness.isComplete ? WaUi.accent : WaUi.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text('Business name', style: WaUi.label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: context.l10n.businessName,
              filled: true,
              fillColor: WaUi.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
                borderSide: const BorderSide(color: WaUi.fieldOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
                borderSide: const BorderSide(color: WaUi.fieldOutline),
              ),
            ),
          ),
          const SizedBox(height: 16),
          RadioPickerField(
            labelText: context.l10n.businessCategory,
            valueText: _industry == null
                ? null
                : businessCategoryLabel(context, _industry!),
            onTap: _pickIndustry,
          ),
          const SizedBox(height: 16),
          Text('Public business location', style: WaUi.label),
          const SizedBox(height: 6),
          InkWell(
            onTap: _resolvingAddress ? null : _pickLocation,
            borderRadius: BorderRadius.circular(WaUi.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WaUi.fieldFill,
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
                border: Border.all(color: WaUi.fieldOutline),
              ),
              child: Row(
                children: [
                  Icon(
                    _latitude == null
                        ? Icons.add_location_alt_outlined
                        : Icons.location_on,
                    color: WaUi.primaryText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resolvingAddress
                          ? 'Resolving address…'
                          : _latitude == null
                              ? context.l10n.pickLocation
                              : 'Lat ${_latitude!.toStringAsFixed(5)}, Lng ${_longitude!.toStringAsFixed(5)}',
                      style: WaUi.body,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: WaUi.secondaryText),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.address, style: WaUi.label),
          const SizedBox(height: 6),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: context.l10n.addressOptional,
              filled: true,
              fillColor: WaUi.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
                borderSide: const BorderSide(color: WaUi.fieldOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
                borderSide: const BorderSide(color: WaUi.fieldOutline),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('City', style: WaUi.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: WaUi.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WaUi.radiusMd),
                          borderSide:
                              const BorderSide(color: WaUi.fieldOutline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WaUi.radiusMd),
                          borderSide:
                              const BorderSide(color: WaUi.fieldOutline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Area', style: WaUi.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _areaController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: WaUi.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WaUi.radiusMd),
                          borderSide:
                              const BorderSide(color: WaUi.fieldOutline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WaUi.radiusMd),
                          borderSide:
                              const BorderSide(color: WaUi.fieldOutline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          WaPrimaryButton(
            label: _saving ? 'Saving…' : context.l10n.saveChanges,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
