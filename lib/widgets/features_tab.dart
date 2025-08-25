import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/router/route_names.dart';

class FeaturesTab extends StatelessWidget {
  const FeaturesTab({super.key});

  @override
  Widget build(BuildContext context) {
    Widget _buildFeatureTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required String routeName,
      Color? iconColor,
    }) {
      final theme = Theme.of(context);
      return InkWell(
        onTap: () => GoRouter.of(context).pushNamed(routeName),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor?.withOpacity(0.1) ?? theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: iconColor ?? theme.colorScheme.primary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildFeatureTile(
            icon: Icons.message_rounded,
            title: 'Direct Message',
            subtitle: 'Quickly send WhatsApp messages without saving the number.',
            routeName: RouteNames.directMessage,
          ),

          const SizedBox(height: 16),

          _buildFeatureTile(
            icon: Icons.settings_rounded,
            iconColor: Colors.orange,
            title: 'Settings',
            subtitle: 'Manage your app preferences and configurations.',
            routeName: RouteNames.settings,
          ),

          const SizedBox(height: 16),

          _buildFeatureTile(
            icon: Icons.sticky_note_2_rounded,
            iconColor: Colors.purple,
            title: 'Sticker Maker',
            subtitle: 'Create personalized WhatsApp stickers easily.',
            routeName: RouteNames.sticker,
          ),

          const SizedBox(height: 16),

          _buildFeatureTile(
            icon: Icons.gif_box_rounded,
            iconColor: Colors.green,
            title: 'GIF Maker',
            subtitle: 'Turn videos or images into GIFs for sharing.',
            routeName: RouteNames.gif,
          ),
        ],
      ),
    );
  }
}
