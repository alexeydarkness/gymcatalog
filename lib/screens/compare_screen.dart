import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../providers/gym_provider.dart';
import '../styles/app_styles.dart';

class CompareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();
    final gyms = provider.compareGyms;

    return Scaffold(
      appBar: AppBar(
        title: Text('Сравнение'),
        actions: [
          if (gyms.isNotEmpty)
            IconButton(
              tooltip: 'Очистить',
              icon: Icon(Icons.delete_sweep_outlined),
              onPressed: () => provider.clearCompare(),
            ),
        ],
      ),
      body: gyms.isEmpty ? _buildEmpty(context) : _buildCompare(context, gyms, provider),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.compare_arrows, size: 56, color: AppStyles.primaryColor),
            ),
            SizedBox(height: AppStyles.paddingLarge),
            Text('Список сравнения пуст', style: AppStyles.titleStyle, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Добавьте до ${GymProvider.maxCompare} залов через значок сравнения на карточке',
              style: AppStyles.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompare(BuildContext context, List<Gym> gyms, GymProvider provider) {
    final maxRating = gyms.map((g) => g.rating).reduce((a, b) => a > b ? a : b);
    final minPrice = gyms.map((g) => g.pricePerMonth).reduce((a, b) => a < b ? a : b);

    return ListView(
      padding: EdgeInsets.all(AppStyles.paddingMedium),
      children: [
        // горизонтально прокручивающиеся карточки залов сверху
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gyms.length,
            separatorBuilder: (_, __) => SizedBox(width: 10),
            itemBuilder: (_, i) => _gymCard(context, gyms[i], provider),
          ),
        ),
        SizedBox(height: AppStyles.paddingLarge),
        // сравнение по параметрам
        _sectionCard(
          context: context,
          title: 'Рейтинг',
          icon: Icons.star_outline,
          rows: gyms.map((g) {
            final isBest = g.rating > 0 && g.rating == maxRating;
            return _paramRow(
              name: g.name,
              value: g.rating > 0 ? g.rating.toStringAsFixed(1) : '—',
              isBest: isBest,
              trailing: Icon(Icons.star, color: Colors.amber, size: 16),
            );
          }).toList(),
        ),
        _sectionCard(
          context: context,
          title: 'Цена в месяц',
          icon: Icons.payments_outlined,
          rows: gyms.map((g) {
            final isBest = g.pricePerMonth == minPrice;
            return _paramRow(
              name: g.name,
              value: '${g.pricePerMonth.toInt()} ₽',
              isBest: isBest,
            );
          }).toList(),
        ),
        _sectionCard(
          context: context,
          title: 'Тип',
          icon: Icons.category_outlined,
          rows: gyms.map((g) => _paramRow(name: g.name, value: g.type)).toList(),
        ),
        _amenitiesSection(context, gyms),
        SizedBox(height: AppStyles.paddingLarge),
      ],
    );
  }

  Widget _gymCard(BuildContext context, Gym gym, GymProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: isDark ? AppStyles.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              gym.imageUrl.isNotEmpty
                  ? Image.network(
                      gym.imageUrl,
                      width: double.infinity,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback(),
                    )
                  : _imgFallback(),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withOpacity(0.5),
                  shape: CircleBorder(),
                  child: InkWell(
                    customBorder: CircleBorder(),
                    onTap: () => provider.toggleCompare(gym.id),
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  gym.address,
                  style: AppStyles.subtitleStyle.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    if (gym.rating > 0) ...[
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      SizedBox(width: 2),
                      Text(gym.rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                    Spacer(),
                    Text(
                      '${gym.pricePerMonth.toInt()} ₽',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppStyles.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(gradient: AppStyles.primaryGradient),
      child: Icon(Icons.fitness_center, size: 36, color: Colors.white54),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: AppStyles.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppStyles.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppStyles.paddingMedium),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppStyles.primaryColor),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          Divider(height: 1),
          ...rows,
        ],
      ),
    );
  }

  Widget _paramRow({
    required String name,
    required String value,
    bool isBest = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppStyles.paddingMedium, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[trailing, SizedBox(width: 4)],
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isBest ? Colors.green : null,
            ),
          ),
          if (isBest) ...[
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'лучший',
                style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amenitiesSection(BuildContext context, List<Gym> gyms) {
    final all = <String>{};
    for (final g in gyms) {
      all.addAll(g.amenities);
    }
    final sorted = all.toList()..sort();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (sorted.isEmpty) {
      return _sectionCard(
        context: context,
        title: 'Удобства',
        icon: Icons.check_circle_outline,
        rows: [
          Padding(
            padding: EdgeInsets.all(AppStyles.paddingMedium),
            child: Text('Нет данных', style: AppStyles.subtitleStyle),
          ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppStyles.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppStyles.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppStyles.paddingMedium),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: AppStyles.primaryColor),
                SizedBox(width: 8),
                Text('Удобства', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          Divider(height: 1),
          ...sorted.map((amenity) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: AppStyles.paddingMedium, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(amenity, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ...gyms.map((gym) {
                    final has = gym.amenities.contains(amenity);
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        has ? Icons.check_circle : Icons.remove_circle_outline,
                        color: has ? Colors.green : Colors.grey.withOpacity(0.4),
                        size: 22,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}