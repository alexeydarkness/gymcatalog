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
        title: Text('Сравнение залов'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (gyms.isNotEmpty)
            IconButton(
              tooltip: 'Очистить',
              icon: Icon(Icons.delete_sweep),
              onPressed: () => provider.clearCompare(),
            ),
        ],
      ),
      body: gyms.isEmpty ? _buildEmpty() : _buildCompareTable(context, gyms, provider),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, size: 80, color: Colors.grey),
            SizedBox(height: AppStyles.paddingMedium),
            Text(
              'Список сравнения пуст',
              style: AppStyles.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppStyles.paddingSmall),
            Text(
              'Добавьте залы через иконку сравнения в списке (до ${GymProvider.maxCompare} залов)',
              style: AppStyles.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareTable(BuildContext context, List<Gym> gyms, GymProvider provider) {
    // подсветим лучшие значения
    final maxRating = gyms.map((g) => g.rating).reduce((a, b) => a > b ? a : b);
    final minPrice = gyms.map((g) => g.pricePerMonth).reduce((a, b) => a < b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(gyms, provider),
              Divider(height: 1),
              _buildRatingRow(gyms, maxRating),
              Divider(height: 1),
              _buildPriceRow(gyms, minPrice),
              Divider(height: 1),
              _buildTypeRow(gyms),
              Divider(height: 1),
              _buildAmenitiesRow(gyms),
              Divider(height: 1),
              _buildAddressRow(gyms),
            ],
          ),
        ),
      ),
    );
  }

  // === строки таблицы ===

  Widget _buildHeaderRow(List<Gym> gyms, GymProvider provider) {
    return _row(
      label: '',
      cells: gyms.map((gym) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: gym.imageUrl.isNotEmpty
                      ? Image.network(
                          gym.imageUrl,
                          width: double.infinity,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.white.withOpacity(0.85),
                    shape: CircleBorder(),
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => provider.toggleCompare(gym.id),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              gym.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 100,
      color: Colors.grey[200],
      child: Icon(Icons.fitness_center, size: 40, color: Colors.grey),
    );
  }

  Widget _buildRatingRow(List<Gym> gyms, double maxRating) {
    return _row(
      label: 'Рейтинг',
      cells: gyms.map((gym) {
        final isBest = gym.rating > 0 && gym.rating == maxRating;
        return Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 18),
            SizedBox(width: 4),
            Text(
              gym.rating > 0 ? gym.rating.toStringAsFixed(1) : '—',
              style: TextStyle(
                fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                color: isBest ? Colors.green[700] : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPriceRow(List<Gym> gyms, double minPrice) {
    return _row(
      label: 'Цена',
      cells: gyms.map((gym) {
        final isBest = gym.pricePerMonth == minPrice;
        return Text(
          '${gym.pricePerMonth.toInt()} ₽/мес',
          style: TextStyle(
            fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
            color: isBest ? Colors.green[700] : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeRow(List<Gym> gyms) {
    return _row(
      label: 'Тип',
      cells: gyms.map((gym) => Text(gym.type)).toList(),
    );
  }

  Widget _buildAmenitiesRow(List<Gym> gyms) {
    // собираем все удобства из всех залов, чтобы сравнить по строкам
    final all = <String>{};
    for (final g in gyms) {
      all.addAll(g.amenities);
    }
    final sorted = all.toList()..sort();

    if (sorted.isEmpty) {
      return _row(
        label: 'Удобства',
        cells: gyms.map((g) => Text('—')).toList(),
      );
    }

    return _row(
      label: 'Удобства',
      cells: gyms.map((gym) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sorted.map((a) {
            final has = gym.amenities.contains(a);
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    has ? Icons.check_circle : Icons.remove_circle_outline,
                    size: 16,
                    color: has ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      a,
                      style: TextStyle(
                        fontSize: 13,
                        color: has ? null : Colors.grey,
                        decoration: has ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildAddressRow(List<Gym> gyms) {
    return _row(
      label: 'Адрес',
      cells: gyms.map((gym) => Text(gym.address, style: TextStyle(fontSize: 13))).toList(),
    );
  }

  // === универсальная строка с подписью слева и ячейками ===

  Widget _row({required String label, required List<Widget> cells}) {
    const double labelWidth = 100;
    const double cellWidth = 160;
    return Padding(
      padding: EdgeInsets.all(AppStyles.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          ...cells.map((cell) => Container(
                width: cellWidth,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: cell,
              )),
        ],
      ),
    );
  }
}