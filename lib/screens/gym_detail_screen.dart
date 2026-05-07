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

  const GymDetailScreen({super.key, required this.gym, this.role = 'user'});

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
        const SnackBar(content: Text('Войдите, чтобы оставить отзыв')),
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
        SnackBar(
          content: Text(existing != null ? 'Отзыв обновлён' : 'Отзыв добавлен'),
        ),
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
        title: const Text('Удалить отзыв?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppStyles.errorColor),
            ),
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
    final colors = AppStyles.categoryGradient(_gym.type);

    return Scaffold(
      backgroundColor: AppStyles.darkBg,
      body: CustomScrollView(
        slivers: [
          // === HERO с градиентом по категории ===
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppStyles.darkBg,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _GlassButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: _GlassButton(
                  icon: _gym.isFavorite ? Icons.favorite : Icons.favorite_border,
                  active: _gym.isFavorite,
                  onTap: () {
                    provider.toggleFavorite(_gym);
                    setState(() {});
                  },
                ),
              ),
              if (widget.role == 'admin')
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                  child: _GlassButton(
                    icon: Icons.edit,
                    onTap: () async {
                      final edited = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GymEditScreen(gym: _gym),
                        ),
                      );
                      if (edited != null && mounted) {
                        Navigator.pop(context, edited);
                      }
                    },
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'gym-image-${_gym.id}',
                    child: _gym.imageUrl.isNotEmpty
                        ? Image.network(
                            _gym.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _heroGradient(colors),
                          )
                        : _heroGradient(colors),
                  ),
                  if (_gym.imageUrl.isNotEmpty)
                    Container(color: Colors.black.withValues(alpha: 0.4)),
                  // Тёмный градиент снизу под текст
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppStyles.darkBg.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  // Плашка статуса работы зала.
                  // Зелёная "Сейчас открыто" — если зал НЕ в корзине;
                  // серая "Не работает" — если админ удалил его в корзину.
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: _OpenStatusPill(isOpen: !_gym.isDeleted),
                  ),
                ],
              ),
            ),
          ),

          // === ОСНОВНОЕ ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название + бейдж категории
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _gym.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                          border: Border.all(
                            color: AppStyles.primaryColor.withValues(alpha: 0.27),
                          ),
                        ),
                        child: Text(
                          _gym.type.toUpperCase(),
                          style: const TextStyle(
                            color: AppStyles.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppStyles.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _gym.address,
                          style: const TextStyle(
                            color: AppStyles.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // === 3 stat-карточки ===
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          valueWidget: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppStyles.ratingColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _gym.rating > 0
                                    ? _gym.rating.toStringAsFixed(1)
                                    : '—',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppStyles.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          label: 'Рейтинг',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          valueWidget: Text(
                            '${_gym.pricePerMonth.toInt()} ₽',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.primaryColor,
                            ),
                          ),
                          label: 'Цена / мес',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          valueWidget: Text(
                            '${_reviews.length}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.textPrimary,
                            ),
                          ),
                          label: 'Отзывов',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // === Удобства ===
                  Text('УДОБСТВА', style: AppStyles.sectionLabel),
                  const SizedBox(height: 10),
                  if (_gym.amenities.isEmpty)
                    Text('Информация не указана', style: AppStyles.subtitleStyle)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gym.amenities.map(_buildAmenityChip).toList(),
                    ),
                  const SizedBox(height: 22),

                  // === Отзывы ===
                  Text(
                    'ОТЗЫВЫ · ${_reviews.length}',
                    style: AppStyles.sectionLabel,
                  ),
                  const SizedBox(height: 10),
                  _buildReviewsSection(currentUser, provider.role),

                  const SizedBox(height: 16),

                  // === CTA "Оставить/изменить отзыв" ===
                  // Если зал в корзине (не работает) — кнопка отключена.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _gym.isDeleted ? null : _openReviewDialog,
                      icon: Icon(
                        _gym.isDeleted
                            ? Icons.block
                            : Icons.rate_review_outlined,
                      ),
                      label: Text(
                        _gym.isDeleted
                            ? 'Зал не работает'
                            : (_reviews.any((r) => r.username == currentUser)
                                ? 'Изменить отзыв'
                                : 'Оставить отзыв'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppStyles.darkSurface,
                        disabledForegroundColor: AppStyles.textTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroGradient(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1),
          end: const Alignment(1, 1),
          colors: [
            colors[0],
            colors[1],
            AppStyles.primaryColor.withValues(alpha: 0.2),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          AppStyles.categoryIcon(_gym.type),
          size: 110,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium - 2),
        border: Border.all(color: AppStyles.darkBorderHi),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppStyles.amenityIcon(amenity),
            size: 14,
            color: AppStyles.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            amenity,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String currentUser, String role) {
    if (_reviewsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppStyles.primaryColor),
        ),
      );
    }
    if (_reviewsError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          children: [
            Text(
              'Ошибка: $_reviewsError',
              style: const TextStyle(color: AppStyles.errorColor),
            ),
            TextButton(
              onPressed: _loadReviews,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppStyles.darkSurface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(color: AppStyles.darkBorder),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 36,
              color: AppStyles.textMuted,
            ),
            const SizedBox(height: 8),
            Text('Пока нет отзывов', style: AppStyles.subtitleStyle),
            Text('Будь первым!', style: AppStyles.subtitleStyle),
          ],
        ),
      );
    }
    return Column(
      children: _reviews
          .map((r) => _buildReviewCard(r, currentUser, role))
          .toList(),
    );
  }

  Widget _buildReviewCard(Review r, String currentUser, String role) {
    final canDelete = role == 'admin' || r.username == currentUser;
    final isMine = r.username == currentUser;
    final initial = r.username.isNotEmpty ? r.username[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(
          color: isMine
              ? AppStyles.primaryColor.withValues(alpha: 0.4)
              : AppStyles.darkBorder,
          width: isMine ? 1.2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppStyles.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFFDDDDDD),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < r.rating ? Icons.star : Icons.star_border,
                          size: 12,
                          color: i < r.rating
                              ? AppStyles.ratingColor
                              : const Color(0xFF444444),
                        );
                      }),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'вы',
                          style: TextStyle(
                            color: AppStyles.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(r.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppStyles.textMuted,
                      ),
                    ),
                    if (canDelete)
                      GestureDetector(
                        onTap: () => _deleteReview(r),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppStyles.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                if (r.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
}

// ─── ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ───────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppStyles.primaryColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppStyles.primaryColor : Colors.white,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Widget valueWidget;
  final String label;

  const _StatCard({required this.valueWidget, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppStyles.darkBorder),
      ),
      child: Column(
        children: [
          valueWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppStyles.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenStatusPill extends StatelessWidget {
  final bool isOpen;
  const _OpenStatusPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOpen ? AppStyles.successColor : const Color(0xFF555555),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Сейчас открыто' : 'Не работает',
            style: TextStyle(
              color: isOpen ? AppStyles.successColor : AppStyles.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// === Диалог отзыва ===

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
      backgroundColor: AppStyles.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        side: const BorderSide(color: AppStyles.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? 'Изменить отзыв' : 'Оставить отзыв',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppStyles.textPrimary,
              ),
            ),
            const SizedBox(height: AppStyles.paddingMedium),
            const Text(
              'Ваша оценка',
              style: TextStyle(color: AppStyles.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final value = i + 1;
                return IconButton(
                  iconSize: 32,
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: AppStyles.ratingColor,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            TextField(
              controller: _textController,
              maxLines: 4,
              maxLength: 1000,
              style: const TextStyle(color: AppStyles.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Комментарий (необязательно)',
              ),
            ),
            const SizedBox(height: AppStyles.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _ReviewInput(_rating, _textController.text.trim()),
                    ),
                    child: const Text('Сохранить'),
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