// lib/features/achievements/view/achievements_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';

import '../data/all_achievements_data.dart';
import '../models/achievement_model.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  List<String> _unlockedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnlockedAchievements();
  }

  Future<void> _loadUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedIds = prefs.getStringList('unlocked_achievements') ?? [];
      _isLoading = false;
    });
  }

  void _showAchievementDetails(AchievementModel achievement, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(achievement.imagePath, width: 40, height: 40),
            const SizedBox(width: 10),
            Expanded(child: Text(achievement.title)),
          ],
        ),
        content: Text(achievement.description),
        actions: [
          TextButton(
            child: Text(isUnlocked ? 'Legal!' : 'Ok, entendi'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Conquistas'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.iceWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 colunas de badges
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Ajusta a proporção para caber o texto
              ),
              itemCount: allAchievements.length,
              itemBuilder: (context, index) {
                final achievement = allAchievements[index];
                final isUnlocked = _unlockedIds.contains(achievement.id);

                return _buildAchievementTile(achievement, isUnlocked);
              },
            ),
    );
  }

  Widget _buildAchievementTile(AchievementModel achievement, bool isUnlocked) {
    return InkWell(
      onTap: () => _showAchievementDetails(achievement, isUnlocked),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4, // Fica "apagado" se não desbloqueado
        child: Card(
          elevation: isUnlocked ? 4.0 : 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(achievement.imagePath, width: 60, height: 60),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.smallText.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}