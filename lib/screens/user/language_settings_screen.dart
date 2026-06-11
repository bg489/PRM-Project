import 'package:flutter/material.dart';

import '../../utils/app_language_controller.dart';
import '../../utils/app_text.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  AppLanguage selectedLanguage = appLanguageController.language;

  Future<void> changeLanguage(AppLanguage language) async {
    setState(() {
      selectedLanguage = language;
    });

    await appLanguageController.setLanguage(language);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppText.t('language_saved')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguageController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  title: AppText.t('select_language'),
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: Column(
                      children: [
                        _LanguageOptionCard(
                          iconText: 'VI',
                          title: AppText.t('vietnamese'),
                          subtitle: AppText.t('vietnamese_desc'),
                          isSelected:
                          appLanguageController.language == AppLanguage.vi,
                          onTap: () => changeLanguage(AppLanguage.vi),
                        ),
                        const SizedBox(height: 14),
                        _LanguageOptionCard(
                          iconText: 'EN',
                          title: AppText.t('english'),
                          subtitle: AppText.t('english_desc'),
                          isSelected:
                          appLanguageController.language == AppLanguage.en,
                          onTap: () => changeLanguage(AppLanguage.en),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String iconText;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.iconText,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE5E7EB),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF9333EA),
                  ],
                )
                    : null,
                color: isSelected ? null : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  iconText,
                  style: TextStyle(
                    color:
                    isSelected ? Colors.white : const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}