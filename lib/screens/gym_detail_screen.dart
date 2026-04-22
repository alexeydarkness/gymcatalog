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
    // после добавления/удаления отзыва нужно обновить карточку в провайдере
    final provider = context.read<GymProvider>();
    await provider.loadGyms();
    // находим обновлённый зал, чтобы отобразить свежий средний рейтинг
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

    // ищем существующий отзыв юзера, чтобы предзаполнить форму
    final mine = _reviews.where((r) => r.username == username).toList();
    final existing = mine.isNotEmpty ? mine.first : null;

    final result = await showDialog<_ReviewInput>(
      context: context,
      builder: (context) => _ReviewDialog(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _deleteReview(Review review) async {
    final provider = context.read<GymProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_gym.name),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.role == 'admin')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final edited = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GymEditScreen(gym: _gym)),
                );
                if (edited != null) {
                  Navigator.pop(context, edited);
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReviewDialog,
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.rate_review),
        label: Text(
          _reviews.any((r) => r.username == currentUser)
              ? 'Изменить отзыв'
              : 'Оставить отзыв',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_gym.imageUrl.isNotEmpty)
              Image.network(
                _gym.imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Icon(Icons.fitness_center, size: 60, color: Colors.grey),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_gym.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: AppStyles.paddingSmall),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(child: Text(_gym.address, style: AppStyles.subtitleStyle)),
                    ],
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.paddingMedium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 28),
                              SizedBox(height: 4),
                              Text(
                                _reviews.isEmpty ? '—' : _gym.rating.toStringAsFixed(1),
                                style: AppStyles.titleStyle,
                              ),
                              Text(
                                _reviews.isEmpty
                                    ? 'Нет оценок'
                                    : 'Средний (${_reviews.length})',
                                style: AppStyles.subtitleStyle,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.attach_money, color: Colors.green, size: 28),
                              SizedBox(height: 4),
                              Text('${_gym.pricePerMonth.toInt()}', style: AppStyles.titleStyle),
                              Text('₽/мес', style: AppStyles.subtitleStyle),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.category, color: AppStyles.primaryColor, size: 28),
                              SizedBox(height: 4),
                              Text(_gym.type, style: AppStyles.titleStyle),
                              Text('Тип', style: AppStyles.subtitleStyle),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Text('Удобства', style: AppStyles.titleStyle),
                  SizedBox(height: AppStyles.paddingSmall),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _gym.amenities.map((a) {
                      return Chip(
                        avatar: Icon(_getAmenityIcon(a), size: 18),
                        label: Text(a),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppStyles.paddingLarge),
                  Row(
                    children: [
                      Text('Отзывы', style: AppStyles.titleStyle),
                      SizedBox(width: 8),
                      Text('(${_reviews.length})', style: AppStyles.subtitleStyle),
                    ],
                  ),
                  SizedBox(height: AppStyles.paddingSmall),
                  _buildReviewsSection(currentUser, provider.role),
                  // отступ снизу, чтобы FAB не закрывал последний отзыв
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(String currentUser, String role) {
    if (_reviewsLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppStyles.paddingMedium),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_reviewsError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppStyles.paddingMedium),
        child: Column(
          children: [
            Text('Ошибка: $_reviewsError',
                style: TextStyle(color: AppStyles.errorColor)),
            TextButton(onPressed: _loadReviews, child: Text('Повторить')),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppStyles.paddingMedium),
        child: Text(
          'Пока нет отзывов. Будь первым!',
          style: AppStyles.subtitleStyle,
        ),
      );
    }
    return Column(
      children: _reviews.map((r) => _buildReviewCard(r, currentUser, role)).toList(),
    );
  }

  Widget _buildReviewCard(Review r, String currentUser, String role) {
    print('REVIEW in list: id=${r.id}, username=${r.username}, text=${r.text}');
    final canDelete = role == 'admin' || r.username == currentUser;
    return Card(
      margin: EdgeInsets.symmetric(vertical: AppStyles.paddingSmall),
      child: Padding(
        padding: EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppStyles.primaryColor,
                  child: Text(
                    r.username.isNotEmpty ? r.username[0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.username, style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < r.rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(r.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (canDelete)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () => _deleteReview(r),
                  ),
              ],
            ),
            if (r.text.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(r.text),
            ],
          ],
        ),
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

// === диалог добавления/редактирования отзыва ===

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
    return AlertDialog(
      title: Text(widget.isEditing ? 'Редактировать отзыв' : 'Оставить отзыв'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ваша оценка:', style: AppStyles.subtitleStyle),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final value = i + 1;
              return IconButton(
                iconSize: 32,
                padding: EdgeInsets.symmetric(horizontal: 2),
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Комментарий (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _ReviewInput(_rating, _textController.text.trim()),
            );
          },
          child: Text('Сохранить'),
        ),
      ],
    );
  }
}