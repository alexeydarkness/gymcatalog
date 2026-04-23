import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../models/review.dart';
import '../providers/gym_provider.dart';
import '../services/api_services.dart';
import '../styles/app_styles.dart';
import 'gym_edit_screen.dart';

class GymDetailScreen extends StatefulWidget {
  final Gym gym;
  final String role;

  const GymDetailScreen({required this.gym, this.role = 'user'});

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  List<Review> _reviews = [];
  bool _reviewsLoading = true;
  String? _reviewsError;
  late Gym _gym;

  @override
  void initState() {
    super.initState();
    _gym = widget.gym;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final list = await ApiServices.fetchReviews(_gym.id);
      setState(() {
        _reviews = list;
        _reviewsLoading = false;
      });
    } catch (e) {
      setState(() {
        _reviewsError = e.toString();
        _reviewsLoading = false;
      });
    }
  }

  Future<void> _refreshGymRating() async {
    final provider = context.read<GymProvider>();
    await provider.loadGyms();
    final updated = provider.gyms.firstWhere(
      (g) => g.id == _gym.id,
      orElse: () => _gym,
    );
    setState(() => _gym = updated);
  }

  Future<void> _openReviewDialog() async {
    final provider = context.read<GymProvider>();
    final username = provider.username;
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Войдите, чтобы оставить отзыв')),
      );
      return;
    }

    final mine = _reviews.where((r) => r.username == username).toList();
    final existing = mine.isNotEmpty ? mine.first : null;

    final result = await showDialog<_ReviewInput>(
      context: context,
      builder: (_) => _ReviewDialog(
        initialRating: existing?.rating ?? 5,
        initialText: existing?.text ?? '',
        isEditing: existing != null,
      ),
    );
    if (result == null) return;

    try {
      await ApiServices.addReview(
        gymId: _gym.id,
        username: username,
        rating: result.rating,
        text: result.text,
      );
      await _loadReviews();
      await _refreshGymRating();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing != null ? 'Отзыв обновлён' : 'Отзыв добавлен')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteReview(Review review) async {
    final provider = context.read<GymProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Удалить отзыв?'),
        content: Text('Действие необратимо'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить', style: TextStyle(color: AppStyles.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiServices.deleteReview(
        reviewId: review.id,
        username: provider.username,
        role: provider.role,
      );
      await _loadReviews();
      await _refreshGymRating();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();
    final currentUser = provider.username;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.05),
        duration: Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
        // бесконечная пульсация через перезапуск в onEnd
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        onEnd: () => setState(() {}),
        child: FloatingActionButton.extended(
          onPressed: _openReviewDialog,
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          icon: Icon(Icons.rate_review),
          label: Text(_reviews.any((r) => r.username == context.read<GymProvider>().username)
              ? 'Изменить отзыв'
              : 'Оставить отзыв'),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppStyles.darkBg : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
            actions: [
              if (widget.role == 'admin')
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final edited = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GymEditScreen(gym: _gym)),
                    );
                    if (edited != null) Navigator.pop(context, edited);
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.symmetric(horizontal: 56, vertical: 14),
              title: Text(
                _gym.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'gym-image-${_gym.id}',
                    child: _gym.imageUrl.isNotEmpty
                        ? Image.network(
                            _gym.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(gradient: AppStyles.primaryGradient),
                              child: Icon(Icons.fitness_center, size: 80, color: Colors.white30),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(gradient: AppStyles.primaryGradient),
                            child: Icon(Icons.fitness_center, size: 80, color: Colors.white30),
                          ),
                  ),
                  // тёмная виньетка снизу
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // тип и адрес
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        ),
                        child: Text(
                          _gym.type.toUpperCase(),
                          style: TextStyle(
                            color: AppStyles.primaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 180),
                            child: Text(
                              _gym.address,
                              style: AppStyles.subtitleStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  // три метрики
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          icon: Icons.star,
                          iconColor: Colors.amber,
                          value: _gym.rating > 0 ? _gym.rating.toStringAsFixed(1) : '—',
                          label: _reviews.isEmpty ? 'Нет оценок' : '${_reviews.length} отзывов',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          icon: Icons.payments_outlined,
                          iconColor: AppStyles.primaryColor,
                          value: '${_gym.pricePerMonth.toInt()} ₽',
                          label: 'в месяц',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.green,
                          value: '${_gym.amenities.length}',
                          label: 'удобств',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppStyles.paddingLarge),
                  Text('Удобства', style: AppStyles.titleStyle),
                  SizedBox(height: AppStyles.paddingSmall),
                  if (_gym.amenities.isEmpty)
                    Text('Информация не указана', style: AppStyles.subtitleStyle)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gym.amenities.map((a) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppStyles.darkSurface : Color(0xFFEFEFF2),
                            borderRadius: BorderRadius.circular(AppStyles.radiusSmall + 4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getAmenityIcon(a), size: 16, color: AppStyles.primaryColor),
                              SizedBox(width: 6),
                              Text(a, style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: AppStyles.paddingLarge),
                  Row(
                    children: [
                      Text('Отзывы', style: AppStyles.titleStyle),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_reviews.length}',
                          style: TextStyle(
                            color: AppStyles.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppStyles.paddingSmall),
                  _buildReviewsSection(currentUser, provider.role),
                  SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppStyles.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String currentUser, String role) {
    if (_reviewsLoading) {
      return Padding(
        padding: EdgeInsets.all(AppStyles.paddingMedium),
        child: Center(child: CircularProgressIndicator(color: AppStyles.primaryColor)),
      );
    }
    if (_reviewsError != null) {
      return Padding(
        padding: EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          children: [
            Text('Ошибка: $_reviewsError', style: TextStyle(color: AppStyles.errorColor)),
            TextButton(onPressed: _loadReviews, child: Text('Повторить')),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppStyles.paddingLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppStyles.darkSurface
              : Color(0xFFEFEFF2),
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Пока нет отзывов', style: AppStyles.subtitleStyle),
              Text('Будь первым!', style: AppStyles.subtitleStyle),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _reviews.map((r) => _buildReviewCard(r, currentUser, role)).toList(),
    );
  }

  Widget _buildReviewCard(Review r, String currentUser, String role) {
    final canDelete = role == 'admin' || r.username == currentUser;
    final isMine = r.username == currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: AppStyles.paddingSmall),
      padding: EdgeInsets.all(AppStyles.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppStyles.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: isMine ? Border.all(color: AppStyles.primaryColor.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppStyles.primaryGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  r.username.isNotEmpty ? r.username[0].toUpperCase() : '?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.username, style: TextStyle(fontWeight: FontWeight.w700)),
                        if (isMine) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'вы',
                              style: TextStyle(
                                color: AppStyles.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < r.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(_formatDate(r.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (canDelete)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  onPressed: () => _deleteReview(r),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          if (r.text.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(r.text, style: TextStyle(height: 1.35)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'душ': return Icons.shower;
      case 'сауна': return Icons.hot_tub;
      case 'парковка': return Icons.local_parking;
      case 'тренер': return Icons.person;
      case 'Wi-Fi': return Icons.wifi;
      case 'бассейн': return Icons.pool;
      case 'ринг': return Icons.sports_mma;
      case 'чай': return Icons.local_cafe;
      default: return Icons.check_circle;
    }
  }
}

// === диалог отзыва ===

class _ReviewInput {
  final int rating;
  final String text;
  _ReviewInput(this.rating, this.text);
}

class _ReviewDialog extends StatefulWidget {
  final int initialRating;
  final String initialText;
  final bool isEditing;

  const _ReviewDialog({
    required this.initialRating,
    required this.initialText,
    required this.isEditing,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusLarge)),
      child: Padding(
        padding: EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? 'Изменить отзыв' : 'Оставить отзыв',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: AppStyles.paddingMedium),
            Text('Ваша оценка', style: AppStyles.subtitleStyle),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final value = i + 1;
                return IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            SizedBox(height: AppStyles.paddingSmall),
            TextField(
              controller: _textController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Комментарий (необязательно)',
              ),
            ),
            SizedBox(height: AppStyles.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall + 4),
                      ),
                    ),
                    child: Text('Отмена'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _ReviewInput(_rating, _textController.text.trim()),
                    ),
                    child: Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}