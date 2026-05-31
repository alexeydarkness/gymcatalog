import 'dart:io';

import 'package:curs_proj/providers/gym_provider.dart';
import 'package:curs_proj/providers/theme_provider.dart';
import 'package:curs_proj/screens/gym_detail_screen.dart';
import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'compare_screen.dart';
import 'filter_screen.dart';
import 'gym_edit_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'trash_screen.dart';
import 'login_screen.dart';

class GymListScreen extends StatefulWidget {
  final String role;
  final String username;

  const GymListScreen({super.key, required this.role, required this.username});

  @override
  State<GymListScreen> createState() => _GymListScreenState();
}

class _GymListScreenState extends State<GymListScreen> {
  String _activeCategory = 'Все';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GymProvider>();
      provider.setRole(widget.role);
      provider.setUsername(widget.username);
      provider.loadGyms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();

    // Динамические категории из загруженных залов + "Все" в начале.
    final categoriesSet = <String>{};
    for (final g in provider.gyms) {
      if (g.type.isNotEmpty) categoriesSet.add(g.type);
    }
    final categories = ['Все', ...categoriesSet];

    final shownGyms = _activeCategory == 'Все'
        ? provider.displayedGyms
        : provider.displayedGyms
            .where((g) => g.type.toLowerCase() == _activeCategory.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: AppStyles.darkBg,
      appBar: AppBar(
        title: const Text('Каталог залов'),
        actions: [
          IconButton(
            tooltip: 'Сортировка',
            icon: const Icon(Icons.sort, size: 20),
            color: AppStyles.textSecondary,
            onPressed: () => _showSortSheet(provider),
          ),
          IconButton(
            tooltip: 'Фильтры',
            icon: const Icon(Icons.tune, size: 20),
            color: AppStyles.textSecondary,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilterScreen(
                    selectedType: provider.selectedType,
                    selectedAmenities: provider.selectedAmenities,
                    priceRange: provider.priceRange,
                    minPrice: provider.minPrice,
                    maxPrice: provider.maxPrice,
                  ),
                ),
              );
              if (result != null) {
                provider.setFilters(
                  result['type'],
                  List<String>.from(result['amenities']),
                  priceRange: result['priceRange'],
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(provider),
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final newGym = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GymEditScreen()),
                );
                if (newGym != null) {
                  try {
                    await provider.createGym(newGym);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка при создании: $e')),
                    );
                  }
                }
              },
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          : null,
      body: Column(
        children: [
          // === Поиск + чипы категорий ===
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppStyles.darkDivider, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(provider),
                const SizedBox(height: 11),
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final active = cat == _activeCategory;
                      return _CategoryChip(
                        label: cat,
                        active: active,
                        onTap: () => setState(() => _activeCategory = cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // === Контент ===
          Expanded(child: _buildBody(provider, shownGyms)),
        ],
      ),
    );
  }

  Widget _buildSearchField(GymProvider provider) {
    // Синхронизируем контроллер с провайдером (например, после очистки)
    if (_searchController.text != provider.searchQuery) {
      _searchController.value = TextEditingValue(
        text: provider.searchQuery,
        selection: TextSelection.collapsed(offset: provider.searchQuery.length),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.darkInputBg,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppStyles.darkBorderHi),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppStyles.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => provider.setSearchQuery(v),
              style: const TextStyle(color: AppStyles.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'Поиск по названию или адресу...',
                hintStyle: TextStyle(color: AppStyles.textMuted, fontSize: 13),
              ),
            ),
          ),
          if (provider.searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                provider.setSearchQuery('');
              },
              child: const Icon(Icons.close, size: 16, color: AppStyles.textMuted),
            ),
        ],
      ),
    );
  }

  void _showSortSheet(GymProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppStyles.darkBorderHi,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Сортировка', style: AppStyles.titleStyle),
              ),
            ),
            for (final entry in const {
              SortOption.none: 'Без сортировки',
              SortOption.ratingDesc: 'По рейтингу ↓',
              SortOption.priceAsc: 'По цене ↑',
              SortOption.priceDesc: 'По цене ↓',
              SortOption.nameAsc: 'По названию А–Я',
            }.entries)
              ListTile(
                title: Text(entry.value),
                trailing: provider.sortOption == entry.key
                    ? const Icon(Icons.check, color: AppStyles.primaryColor, size: 20)
                    : null,
                onTap: () {
                  provider.setSortOption(entry.key);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Адаптивное число колонок: ширина / 360, минимум 1.
  /// На мобиле (< ~640) даёт 1 колонку, на планшете — 2, на десктопе — 3+.
  int _columnsFor(double width) {
    if (width < 640) return 1;
    if (width < 1000) return 2;
    if (width < 1400) return 3;
    return 4;
  }

  Widget _buildBody(GymProvider provider, List<Gym> gyms) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppStyles.primaryColor),
      );
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppStyles.errorColor),
            const SizedBox(height: 8),
            Text('Ошибка: ${provider.error}', style: AppStyles.subtitleStyle),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadGyms(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (gyms.isEmpty) {
      return RefreshIndicator(
        color: AppStyles.primaryColor,
        backgroundColor: AppStyles.darkSurface,
        onRefresh: () => provider.loadGyms(),
        child: ListView(
          children: [
            const SizedBox(height: 150),
            const Icon(
              Icons.fitness_center,
              size: 64,
              color: AppStyles.textMuted,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Ничего не найдено', style: AppStyles.subtitleStyle),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        // Соотношение сторон карточки: обложка ~16:9 + блок инфо ~70px.
        // Подбираем aspect ratio так, чтобы карточка не растягивалась слишком сильно.
        const cardAspect = 1.55;

        return RefreshIndicator(
          color: AppStyles.primaryColor,
          backgroundColor: AppStyles.darkSurface,
          onRefresh: () => provider.loadGyms(),
          child: CustomScrollView(
            slivers: [
              // Счётчик "Найдено: N залов"
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppStyles.textMuted,
                        fontSize: 12,
                      ),
                      children: [
                        const TextSpan(text: 'Найдено: '),
                        TextSpan(
                          text: '${gyms.length}',
                          style: const TextStyle(
                            color: AppStyles.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' залов'),
                      ],
                    ),
                  ),
                ),
              ),
              // Сетка карточек
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: cardAspect,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, dataIndex) {
                      final gym = gyms[dataIndex];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(gym.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 16),
                              child: child,
                            ),
                          );
                        },
                        child: _GymCard(
                          gym: gym,
                          role: widget.role,
                          provider: provider,
                          onTap: () => _openDetail(gym, provider),
                        ),
                      );
                    },
                    childCount: gyms.length,
                  ),
                ),
              ),
              // Кнопка "Загрузить ещё"
              if (provider.hasMore)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: OutlinedButton.icon(
                        onPressed: () => provider.loadMore(),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Загрузить ещё'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppStyles.primaryColor,
                          side: const BorderSide(color: AppStyles.primaryColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDetail(Gym gym, GymProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GymDetailScreen(gym: gym, role: widget.role),
      ),
    );
    if (result != null && result is Gym) {
      try {
        await provider.updateGym(result);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    }
  }

  // === DRAWER ===
  Widget _buildDrawer(GymProvider provider) {
    final themeProvider = context.watch<ThemeProvider>();
    final isAdmin = widget.role == 'admin';
    final initial = (provider.username.isNotEmpty
            ? provider.username
            : (isAdmin ? 'A' : 'U'))[0]
        .toUpperCase();

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      width: 280,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // === Шапка профиля ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.6, -1),
                  end: const Alignment(1, 1),
                  colors: [
                    const Color(0xFF1A0505),
                    const Color(0xFF2A0808),
                    AppStyles.primaryColor.withValues(alpha: 0.13),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: const Border(
                  bottom: BorderSide(color: AppStyles.darkDivider),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppStyles.primaryColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.username.isNotEmpty
                              ? provider.username
                              : (isAdmin ? 'admin' : 'user'),
                          style: const TextStyle(
                            color: AppStyles.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAdmin ? 'Администратор' : 'Пользователь',
                          style: const TextStyle(
                            color: AppStyles.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // === Навигация ===
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _DrawerItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Каталог',
                      active: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.favorite_outline,
                      label: 'Избранное',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FavoritesScreen(gyms: provider.gyms),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.compare_arrows,
                      label: 'Сравнение',
                      badge: provider.compareCount > 0
                          ? '${provider.compareCount}'
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CompareScreen()),
                        );
                      },
                    ),
                    if (isAdmin)
                      _DrawerItem(
                        icon: Icons.delete_outline,
                        label: 'Корзина',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrashScreen(),
                            ),
                          ).then((_) => provider.loadGyms());
                        },
                      ),
                    _DrawerItem(
                      icon: Icons.person_outline,
                      label: 'Профиль',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              role: widget.role,
                              gyms: provider.gyms,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      color: AppStyles.darkDivider,
                    ),
                    // Переключатель темы
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.dark_mode_outlined,
                            color: AppStyles.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Тёмная тема',
                              style: TextStyle(
                                color: AppStyles.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: themeProvider.isDark,
                            onChanged: (_) => themeProvider.toggle(),
                            activeColor: Colors.white,
                            activeTrackColor: AppStyles.primaryColor,
                            inactiveThumbColor: Colors.white70,
                            inactiveTrackColor: AppStyles.darkBorderHi,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // === Низ — выход ===
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppStyles.darkDivider)),
              ),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Выйти',
                    color: AppStyles.errorColor,
                    onTap: () {
                      ApiServices.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (_) => false,
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.exit_to_app,
                    label: 'Закрыть приложение',
                    color: AppStyles.textSecondary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Выход'),
                          content: const Text('Закрыть приложение?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Нет'),
                            ),
                            TextButton(
                              onPressed: () => exit(0),
                              child: const Text('Да'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppStyles.primaryColor : AppStyles.darkChipBg,
          borderRadius: BorderRadius.circular(AppStyles.radiusPill),
          border: Border.all(
            color: active ? AppStyles.primaryColor : const Color(0xFF282828),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppStyles.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _GymCard extends StatefulWidget {
  final Gym gym;
  final String role;
  final GymProvider provider;
  final VoidCallback onTap;

  const _GymCard({
    required this.gym,
    required this.role,
    required this.provider,
    required this.onTap,
  });

  @override
  State<_GymCard> createState() => _GymCardState();
}

class _GymCardState extends State<_GymCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _hovered
                ? AppStyles.darkSurfaceHi
                : AppStyles.darkSurfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? const Color(0xFF333333) : AppStyles.darkBorder,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHero()),
              _buildInfo(),
            ],
          ),
        ),
      ),
    );

    if (widget.role == 'admin') {
      return Dismissible(
        key: Key('gym-${widget.gym.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppStyles.errorColor,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        confirmDismiss: (_) async {
          try {
            await widget.provider.deleteGym(widget.gym.id);
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.gym.name} удалён')),
            );
            return true;
          } catch (e) {
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка удаления: $e')),
            );
            return false;
          }
        },
        child: card,
      );
    }
    return card;
  }

  Widget _buildHero() {
    final gym = widget.gym;
    final colors = AppStyles.categoryGradient(gym.type);
    final isFav = gym.isFavorite;
    final inCompare = widget.provider.isInCompare(gym.id);
    final isInactive = gym.isDeleted;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Фон: либо реальная картинка, либо градиент по категории
        Hero(
          tag: 'gym-image-${gym.id}',
          child: gym.imageUrl.isNotEmpty
              ? Image.network(
                  gym.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _gradientBg(colors),
                )
              : _gradientBg(colors),
        ),
        // Тёмное затемнение поверх фото для контраста плашек
        if (gym.imageUrl.isNotEmpty)
          Container(color: Colors.black.withValues(alpha: 0.35)),
        // Глухой серый оверлей для нерабочих залов (в корзине)
        if (isInactive)
          Container(color: Colors.black.withValues(alpha: 0.6)),

        // Плашка категории (слева сверху)
        Positioned(
          top: 12,
          left: 12,
          child: _CategoryPill(label: gym.type),
        ),
        // Плашка "Не работает" для удалённых — слева снизу
        if (isInactive)
          const Positioned(
            bottom: 12,
            left: 12,
            child: _InactivePill(),
          ),
        // Кнопки действий (справа сверху)
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              _ActionIcon(
                icon: inCompare ? Icons.check : Icons.compare_arrows,
                active: inCompare,
                onTap: () {
                  if (!inCompare && !widget.provider.canAddMoreToCompare) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Максимум ${GymProvider.maxCompare} зала для сравнения',
                        ),
                      ),
                    );
                    return;
                  }
                  widget.provider.toggleCompare(gym.id);
                },
              ),
              const SizedBox(width: 6),
              _ActionIcon(
                icon: isFav ? Icons.favorite : Icons.favorite_border,
                active: isFav,
                onTap: () => widget.provider.toggleFavorite(gym),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientBg(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0],
            colors[1],
            AppStyles.primaryColor.withValues(alpha: 0.13),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          AppStyles.categoryIcon(widget.gym.type),
          size: 56,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final gym = widget.gym;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Название
          Text(
            gym.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppStyles.textPrimary,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Адрес
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
                    color: AppStyles.textTertiary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Звёзды + цена
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StarsRow(rating: gym.rating),
              Text(
                '${gym.pricePerMonth.toInt()}₽',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppStyles.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ряд из 5 звёзд + числовая оценка справа (как в макете).
class _StarsRow extends StatelessWidget {
  final double rating;
  const _StarsRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final rounded = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Icon(
              Icons.star,
              size: 11,
              color: i <= rounded
                  ? AppStyles.ratingColor
                  : const Color(0xFF444444),
            ),
          ),
        const SizedBox(width: 3),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : '—',
          style: const TextStyle(
            color: AppStyles.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Серая плашка "Не работает" для залов, отправленных админом в корзину.
class _InactivePill extends StatelessWidget {
  const _InactivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF777777),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Не работает',
            style: TextStyle(
              color: Color(0xFFBBBBBB),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: Border.all(
            color: active
                ? AppStyles.primaryColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppStyles.primaryColor : Colors.white,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final String? badge;
  final Color? color;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.badge,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? AppStyles.primaryColor
        : (color ?? AppStyles.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: active
                ? AppStyles.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            border: Border.all(
              color: active
                  ? AppStyles.primaryColor.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}