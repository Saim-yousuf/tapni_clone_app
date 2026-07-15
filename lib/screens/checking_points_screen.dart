import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/social_links_screen.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class CheckingPointsScreen extends StatelessWidget {
  CheckingPointsScreen({super.key});

  List<Map<String, dynamic>> getChecklist(
    BuildContext context,
    UserProfile profile,
  ) {
    return [
      {
        "title": context.l10n.addProfileName,
        "completed": profile.name.isNotEmpty,
        "onTap": "name",
      },
      {"title": context.l10n.addBio, "completed": profile.bio.isNotEmpty, "onTap": "bio"},
      {
        "title": context.l10n.addProfilePhoto,
        "completed":
            profile.profilePhotoUrl != null &&
            profile.profilePhotoUrl!.isNotEmpty,
        "onTap": "photo",
      },
      {
        "title": context.l10n.addCoverPhoto,
        "completed":
            profile.coverPhotoUrl != null && profile.coverPhotoUrl!.isNotEmpty,
        "onTap": "cover",
      },
      {
        "title": context.l10n.addSocialLinks3,
        "completed": profile.socialLinks.length >= 3,
        "onTap": "social",
      },
      {"title": context.l10n.addIntroVoiceNote, "completed": false, "onTap": "voice"},
      {"title": context.l10n.createGallery, "completed": false, "onTap": "gallery"},
      {
        "title": context.l10n.businessVerified,
        "completed": profile.isPro == true,
        "onTap": "pro",
      },
    ];
  }

  void handleChecklistTap(BuildContext context, String action) {
    switch (action) {
      case "name":
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        profileProvider.setEditingProfile(true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(currentPage: "My Card")),
        );
        break;

      case "bio":
        debugPrint("Navigate to Edit Bio Screen");
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        profileProvider.setEditingProfile(true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(currentPage: "My Card")),
        );
        break;

      case "photo":
        debugPrint("Open Image Picker for Profile Photo");
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        profileProvider.setEditingProfile(true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(currentPage: "My Card")),
        );
        break;

      case "cover":
        debugPrint("Open Cover Photo Upload");
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        profileProvider.setEditingProfile(true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(currentPage: "My Card")),
        );
        break;

      case "social":
        debugPrint("Open Social Links Editor");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(currentPage: "Links")),
        );
        break;

      case "voice":
        debugPrint("Open Voice Note Recorder");
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        profileProvider.setEditingProfile(true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(currentPage: "My Card")),
        );
        break;

      case "gallery":
        debugPrint("Open Gallery Creator");
        break;

      case "pro":
        debugPrint("Open Business Upgrade Screen");
        SubcriptionSheet.show(context);

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;

    // SCORE CALCULATION
    double score = profileProvider.score;

    // if (profile.name.isNotEmpty) score += 12.5;
    // if (profile.bio.isNotEmpty) score += 12.5;
    // if (profile.profilePhotoUrl?.isNotEmpty ?? false) score += 12.5;
    // if (profile.coverPhotoUrl?.isNotEmpty ?? false) score += 12.5;
    // if (profile.socialLinks.length >= 3) score += 12.5;
    // // if (profile.introVoiceNoteUrl?.isNotEmpty ?? false) score += 12.5;
    // // if (profile.gallery.isNotEmpty) score += 12.5;
    // if (profile.isPro == true) score += 12.5;

    final checklist = getChecklist(context, profile);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(context.l10n.profileCheck),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // SCORE CARD (PRO UI)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "${score.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.profileStrength,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.completeTheseSteps,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  final item = checklist[index];

                  return CheckItem(
                    title: item["title"],
                    completed: item["completed"],
                    onTap: () {
                      if (item["completed"] == false) {
                        handleChecklistTap(context, item["onTap"]);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckItem extends StatelessWidget {
  final String title;
  final bool completed;
  final VoidCallback onTap;

  const CheckItem({
    super.key,
    required this.title,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: completed ? Colors.black : Colors.black54,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: completed ? Colors.black : Colors.black87,
                    ),
                  ),
                ),
                if (!completed)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
