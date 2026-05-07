import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'gym_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Gym> gyms;

  const FavoritesScreen({super.key, required this.gyms});

  List<Gym> get favorites => gyms.where((g) => g.isFavorite).toList();

  @override
  Widget build(BuildContext context) {
    final favs = favorites;

    return Scaffold(
      backgroundColor: AppStyles.darkBg,
      appBar: AppBar(
        title: const Text('Избранное'),
      ),
      body: favs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 56,
                    color: AppStyles.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text('Нет избранных залов', style: AppStyles.subtitleStyle),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: favs.length,
              itemBuilder: (context, index) {
                final gym = favs[index];
                return _FavTile(
                  gym: gym,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GymDetailScreen(gym: gym),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FavTile extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;

  const _FavTile({required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyles.categoryGradient(gym.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: AppStyles.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    AppStyles.categoryIcon(gym.type),
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gym.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppStyles.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              gym.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppStyles.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (gym.rating > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppStyles.ratingColor,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            gym.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppStyles.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${gym.pricePerMonth.toInt()} ₽',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppStyles.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
