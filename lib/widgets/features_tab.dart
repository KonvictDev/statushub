import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/router/route_names.dart';
import 'package:statushub/constants/app_strings.dart'; // ✅ central strings

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
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor?.withOpacity(0.1) ??
                              theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: iconColor ?? theme.colorScheme.primary,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Text(
          AppStrings.featuresTitle, // ✅ centralized
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureTile(
              icon: Icons.message_rounded,
              title: AppStrings.featureDirectMessageTitle,
              subtitle: AppStrings.featureDirectMessageSubtitle,
              routeName: RouteNames.directMessage,
            ),
            _buildFeatureTile(
              icon: Icons.sticky_note_2_rounded,
              iconColor: Colors.purple,
              title: AppStrings.featureStickerMakerTitle,
              subtitle: AppStrings.featureStickerMakerSubtitle,
              routeName: RouteNames.sticker,
            ),
            _buildFeatureTile(
              icon: Icons.restore_from_trash_rounded,
              iconColor: Colors.green,
              title: AppStrings.featureRecoverMessageTitle,
              subtitle: AppStrings.featureRecoverMessageSubtitle,
              routeName: RouteNames.recoverMessage,
            ),
            _buildFeatureTile(
              icon: Icons.gamepad_rounded,
              iconColor: Colors.orange,
              title: AppStrings.featureGamesTitle,
              subtitle: AppStrings.featureGamesSubtitle,
              routeName: RouteNames.games,
            ),
          ],
        ),
      ],
    );
  }
}
