import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:intl/intl.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class FilterContactsSheet extends StatefulWidget {
  FilterContactsSheet({Key? key}) : super(key: key);

  @override
  State<FilterContactsSheet> createState() => _FilterContactsSheetState();
}

class _FilterContactsSheetState extends State<FilterContactsSheet> {
  late String _selectedSource;
  late String _sortBy;
  late String _sortOrder;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<String> _selectedMarkers;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<LeadsProvider>(context, listen: false);
    _selectedSource = provider.activeSource;
    _sortBy = provider.sortBy;
    _sortOrder = provider.sortOrder;
    _startDate = provider.startDate;
    _endDate = provider.endDate;
    _selectedMarkers = List.from(provider.activeMarkers);
  }

  void _onReset() {
    setState(() {
      _selectedSource = context.l10n.all;
      _sortBy = context.l10n.creationDate;
      _sortOrder = context.l10n.descending;
      _startDate = null;
      _endDate = null;
      _selectedMarkers.clear();
    });
  }

  void _onSave() {
    final provider = Provider.of<LeadsProvider>(context, listen: false);
    provider.applyFilters(
      source: _selectedSource,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      startDate: _startDate,
      endDate: _endDate,
      activeMarkers: _selectedMarkers,
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final provider = Provider.of<LeadsProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Title
              Center(
                child: Text(
                  context.l10n.filterContacts2,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Contact Source
              Text(
                context.l10n.contactSource,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    context.l10n.all,
                    'Direct',
                    'Form',
                    'Manually',
                    context.l10n.scan
                  ].map((source) {
                    final isSelected = _selectedSource == source;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSource = source;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white12 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            source,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  _selectedSource == 'All' 
                      ? context.l10n.allContactTypes
                      : '$_selectedSource contacts only',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Sort Options
              Text(
                context.l10n.sortOptions,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSortOption(
                      label: context.l10n.creationDate,
                      isSelected: _sortBy == 'Creation Date',
                      onTap: () => setState(() => _sortBy = context.l10n.creationDate),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSortOption(
                      label: context.l10n.fullName,
                      isSelected: _sortBy == 'Full Name',
                      onTap: () => setState(() => _sortBy = context.l10n.fullName),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSortOption(
                      label: context.l10n.descending,
                      isSelected: _sortOrder == 'Descending',
                      onTap: () => setState(() => _sortOrder = context.l10n.descending),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSortOption(
                      label: context.l10n.ascending,
                      isSelected: _sortOrder == 'Ascending',
                      onTap: () => setState(() => _sortOrder = context.l10n.ascending),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Date Range
              Text(
                context.l10n.dateRange,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}'
                              : context.l10n.selectDateRange,
                          style: TextStyle(
                            fontSize: 14,
                            color: (_startDate != null && _endDate != null)
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white54 : Colors.grey.shade500),
                          ),
                        ),
                      ),
                      if (_startDate != null && _endDate != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          child: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Select Markers
              Text(
                context.l10n.selectMarkers,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.categories.map((category) {
                  final isSelected = _selectedMarkers.contains(category.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMarkers.remove(category.id);
                        } else {
                          _selectedMarkers.add(category.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white12 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 40),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _onReset,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          context.l10n.reset,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _onSave,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          context.l10n.save,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
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

  Widget _buildSortOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white12 : Colors.grey.shade200)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (isDark ? Colors.white38 : Colors.grey.shade400)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
