import 'package:flutter/material.dart';
import '../../domain/entities/achievement.dart';

class AchievementBanner extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onClose;

  const AchievementBanner({super.key, required this.achievement, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                Achievement.emojiFor(achievement.type),
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Logro desbloqueado!',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Achievement.labelFor(achievement.type),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            Achievement.descriptionFor(achievement.type),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (achievement.habitName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              achievement.habitName,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: onClose, child: const Text('¡Genial!')),
        ],
      ),
    );
  }
}
