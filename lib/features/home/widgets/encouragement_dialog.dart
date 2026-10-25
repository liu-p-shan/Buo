import 'package:flutter/material.dart';

import 'package:safemate/core/constants/safety_tips.dart';
import 'package:safemate/core/navigation/app_routes.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/home/widgets/companion_card.dart';

/// 鼓励弹窗:点按头像后弹出,弹簧缩放入场
Future<void> showEncouragementDialog(BuildContext context) {
  return AppRoutes.showSpringDialog(
    context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Material(
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 300,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            color: scheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CompanionAvatar(size: 76),
                const SizedBox(height: 18),
                Text(
                  SafetyContent.randomEncouragement(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  SafetyContent.companionAlwaysHere,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.companion,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('谢谢你',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
