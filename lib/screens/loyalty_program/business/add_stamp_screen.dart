import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class AddStampScreen extends StatefulWidget {
  final RewardEnrollment enrollment;
  AddStampScreen({super.key, required this.enrollment});

  @override
  State<AddStampScreen> createState() => _AddStampScreenState();
}

class _AddStampScreenState extends State<AddStampScreen> {
  late RewardEnrollment _enrollment;
  bool _isLoading = false;
  bool _justCompleted = false;

  @override
  void initState() {
    super.initState();
    _enrollment = widget.enrollment;
  }

  Future<void> _addStamp() async {
    if (_isLoading || _enrollment.isCompleted) return;
    setState(() => _isLoading = true);
    final res = await RewardRepo().addStamp(_enrollment.id);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final updated = RewardEnrollment.fromJson(res.data['data'] ?? res.data);
      setState(() {
        _enrollment = updated;
        _justCompleted = updated.isCompleted;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToAddStamp)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = _enrollment.program;
    final totalStamps = program?.stamps ?? 10;
    final currentStamps = _enrollment.stamps;
    final theme = program?.theme ?? RewardTheme();

    return Scaffold(
      backgroundColor: theme.screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.screenBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.screenTextColor),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          program?.label.isNotEmpty == true ? program!.label : context.l10n.stampCard,
          style: TextStyle(color: theme.screenTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Program Title
              if (program != null) ...[
                if (program.logo.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(program.logo, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                const SizedBox(height: 12),
                Text(program.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.screenTextColor, fontSize: 22, fontWeight: FontWeight.bold)),
                if (program.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(program.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.screenTextColor.withOpacity(0.6), fontSize: 13)),
                ],
              ],
              const SizedBox(height: 32),

              // Stamp progress card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Text('$currentStamps / $totalStamps Stamps',
                        style: TextStyle(color: theme.cardTextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(totalStamps, (i) {
                        final filled = i < currentStamps;
                        return RewardStampSlot(
                          filled: filled,
                          theme: theme,
                          animated: true,
                          stampIconUrl: program?.stampIcon,
                          unstampIconUrl: program?.unstampIcon,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Completed Banner
              if (_justCompleted || _enrollment.isCompleted)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(Icons.celebration, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(context.l10n.rewardCompleted,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ]),
                ),

              Spacer(),

              // Add Stamp Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _enrollment.isCompleted ? null : (_isLoading ? null : _addStamp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _enrollment.isCompleted ? Colors.grey.shade300 : Colors.black,
                    foregroundColor: _enrollment.isCompleted ? Colors.grey : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_enrollment.isCompleted ? Icons.done_all : Icons.add_circle_outline),
                  label: Text(
                    _enrollment.isCompleted ? context.l10n.cardCompleted : context.l10n.addStamp,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
