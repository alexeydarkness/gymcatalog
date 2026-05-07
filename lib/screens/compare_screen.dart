import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../providers/gym_provider.dart';
import '../styles/app_styles.dart';

/// Экран сравнения залов.
///
/// Структура: горизонтальный стрип-карточек сверху, ниже секции
/// с параметрами (рейтинг, цена, тип, удобства). В каждой секции
/// слева — название параметра, справа — по колонке на каждый зал.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();
    final gyms = provider.compareGyms;

    return Scaffold(
      backgroundColor: AppStyles.darkBg,
      appBar: AppBar(
        title: const Text('Сравнение'),
        actions: [
          if (gyms.isNotEmpty)
            IconButton(
              tooltip: 'Очистить',
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              color: AppStyles.textSecondary,
              onPressed: () => provider.clearCompare(),
            ),
        ],
      ),
      body: gyms.isEmpty
          ? _buildEmpty(context)
          : _buildCompare(context, gyms, provider),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows,
                size: 56,
                color: AppStyles.primaryColor,
              ),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            Text(
              'Список сравнения пуст',
              style: AppStyles.titleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
    final maxRating = gyms
        .map((g) => g.rating)
        .reduce((a, b) => a > b ? a : b);
    final minPrice = gyms
        .map((g) => g.pricePerMonth)
        .reduce((a, b) => a < b ? a : b);

    // Все уникальные удобства из выбранных залов.
    final allAmenities = <String>{};
    for (final g in gyms) {
      allAmenities.addAll(g.amenities);
    }
    final sortedAmenities = allAmenities.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      children: [
        // Стрип карточек залов сверху
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gyms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _gymCard(context, gyms[i], provider),
          ),
        ),
        const SizedBox(height: AppStyles.paddingLarge),

        // Параметры — каждая секция с колонками на зал
        _SectionCard(
          title: 'Рейтинг',
          icon: Icons.star_outline,
          gyms: gyms,
          rows: [
            _ParamRow(
              label: 'Оценка',
              values: gyms.map((g) {
                final isBest = g.rating > 0 && g.rating == maxRating;
                return _CellValue(
                  text: g.rating > 0 ? g.rating.toStringAsFixed(1) : '—',
                  isBest: isBest && gyms.length > 1,
                );
              }).toList(),
            ),
          ],
        ),
        _SectionCard(
          title: 'Цена',
          icon: Icons.payments_outlined,
          gyms: gyms,
          rows: [
            _ParamRow(
              label: 'В месяц',
              values: gyms.map((g) {
                final isBest = g.pricePerMonth == minPrice;
                return _CellValue(
                  text: '${g.pricePerMonth.toInt()} ₽',
                  isBest: isBest && gyms.length > 1,
                );
              }).toList(),
            ),
          ],
        ),
        _SectionCard(
          title: 'Тип',
          icon: Icons.category_outlined,
          gyms: gyms,
          rows: [
            _ParamRow(
              label: 'Категория',
              values: gyms.map((g) => _CellValue(text: g.type)).toList(),
            ),
          ],
        ),
        _SectionCard(
          title: 'Удобства',
          icon: Icons.check_circle_outline,
          gyms: gyms,
          rows: sortedAmenities.isEmpty
              ? [
                  const _ParamRow(
                    label: 'Нет данных',
                    values: [],
                    isAmenity: true,
                  ),
                ]
              : sortedAmenities
                  .map((amenity) => _ParamRow(
                        label: amenity,
                        isAmenity: true,
                        values: gyms
                            .map((g) => _CellValue(
                                  text: g.amenities.contains(amenity) ? '✓' : '—',
                                  has: g.amenities.contains(amenity),
                                ))
                            .toList(),
                      ))
                  .toList(),
        ),
        const SizedBox(height: AppStyles.paddingLarge),
      ],
    );
  }

  Widget _gymCard(BuildContext context, Gym gym, GymProvider provider) {
    final colors = AppStyles.categoryGradient(gym.type);

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppStyles.darkBorder),
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
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback(gym, colors),
                    )
                  : _imgFallback(gym, colors),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => provider.toggleCompare(gym.id),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppStyles.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  gym.address,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppStyles.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (gym.rating > 0) ...[
                      const Icon(Icons.star, color: AppStyles.ratingColor, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        gym.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.textPrimary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${gym.pricePerMonth.toInt()} ₽',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.primaryColor,
                      ),
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

  Widget _imgFallback(Gym gym, List<Color> colors) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        AppStyles.categoryIcon(gym.type),
        size: 32,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

// =====================================================================
// СЕКЦИИ И СТРОКИ ПАРАМЕТРОВ
// =====================================================================

/// Значение в одной ячейке (колонке зала).
class _CellValue {
  final String text;
  final bool isBest;
  /// Для удобств: true — есть, false — нет (рисуем иконку, а не текст).
  final bool? has;

  const _CellValue({required this.text, this.isBest = false, this.has});
}

/// Строка параметра: слева подпись, справа N колонок-значений.
class _ParamRow extends StatelessWidget {
  final String label;
  final List<_CellValue> values;
  /// Если true — рисуем зелёные галочки/прочерки вместо текста.
  final bool isAmenity;

  const _ParamRow({
    required this.label,
    required this.values,
    this.isAmenity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingMedium,
        vertical: 11,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isAmenity
                    ? AppStyles.textPrimary
                    : AppStyles.textSecondary,
                fontWeight: isAmenity ? FontWeight.w500 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final v in values)
            Expanded(
              child: _Cell(value: v, isAmenity: isAmenity),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final _CellValue value;
  final bool isAmenity;

  const _Cell({required this.value, required this.isAmenity});

  @override
  Widget build(BuildContext context) {
    if (isAmenity) {
      final has = value.has ?? false;
      return Center(
        child: Icon(
          has ? Icons.check_circle : Icons.remove_circle_outline,
          color: has
              ? AppStyles.successColor
              : AppStyles.textMuted.withValues(alpha: 0.5),
          size: 20,
        ),
      );
    }

    return Center(
      child: Container(
        padding: value.isBest
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : null,
        decoration: value.isBest
            ? BoxDecoration(
                color: AppStyles.successColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                border: Border.all(
                  color: AppStyles.successColor.withValues(alpha: 0.3),
                ),
              )
            : null,
        child: Text(
          value.text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: value.isBest
                ? AppStyles.successColor
                : AppStyles.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Gym> gyms;
  final List<_ParamRow> rows;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.gyms,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      decoration: BoxDecoration(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppStyles.darkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppStyles.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppStyles.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Шапка колонок: справа от подписи параметра — короткие имена залов
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.paddingMedium,
              vertical: 8,
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                for (final gym in gyms)
                  Expanded(
                    child: Center(
                      child: Text(
                        gym.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.textTertiary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppStyles.darkDivider),
          ...rows,
        ],
      ),
    );
  }
}