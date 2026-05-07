import 'package:flutter/material.dart';

/// Стили из макета gym-redesign.html.
///
/// Палитра целиком тёмная, поверхности нескольких уровней,
/// акцент насыщенный красный #e52e2e.
class AppStyles {
  // === БРЕНДОВЫЕ ЦВЕТА ===
  static const primaryColor = Color(0xFFE52E2E); // акцент красный
  static const primaryDark  = Color(0xFFB71C1C);
  static const accentColor  = Color(0xFFFF5252);
  static const errorColor   = Color(0xFFE5533D);

  // === ТЁМНАЯ ПАЛИТРА (основная, под макет) ===
  static const darkBg          = Color(0xFF0D0D0D); // фон скаффолда
  static const darkSurface     = Color(0xFF161616); // карточки/панели
  static const darkSurfaceAlt  = Color(0xFF181818); // карточка списка
  static const darkSurfaceHi   = Color(0xFF1F1F1F); // ховер/выделение
  static const darkBorder      = Color(0xFF222222); // обычный бордер
  static const darkBorderHi    = Color(0xFF252525); // бордер инпутов/кнопок
  static const darkChipBg      = Color(0xFF1A1A1A); // фон чипа/кнопки
  static const darkInputBg     = Color(0xFF141414); // поле поиска
  static const darkDivider     = Color(0xFF1E1E1E);

  // === ТЕКСТ ===
  static const textPrimary     = Color(0xFFF0F0F0);
  static const textSecondary   = Color(0xFF888888);
  static const textTertiary    = Color(0xFF666666);
  static const textMuted       = Color(0xFF555555);

  // === ДОПОЛНИТЕЛЬНЫЕ ===
  static const successColor    = Color(0xFF4ADE80); // "открыто" статус
  static const ratingColor     = Color(0xFFF5A623); // звёзды

  // === СВЕТЛАЯ ПАЛИТРА (на случай переключения темы) ===
  static const lightBg         = Color(0xFFF5F5F7);
  static const lightSurface    = Colors.white;
  static const lightBorder     = Color(0xFFE5E5EA);

  // === ГРАДИЕНТЫ ===
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE52E2E), Color(0xFF8E0000)],
  );

  /// Градиенты по категориям спорта (из макета CATEGORY_COLORS)
  static const Map<String, List<Color>> categoryColors = {
    'единоборства': [Color(0xFF8B1A1A), Color(0xFFC0392B)],
    'бокс':         [Color(0xFF8B1A1A), Color(0xFFC0392B)],
    'мма':          [Color(0xFF8B1A1A), Color(0xFFC0392B)],
    'йога':         [Color(0xFF1A3A4A), Color(0xFF1E6985)],
    'пилатес':      [Color(0xFF1A3A4A), Color(0xFF1E6985)],
    'бодибилдинг':  [Color(0xFF2A1A0A), Color(0xFF8B5E1A)],
    'силовой':      [Color(0xFF2A1A0A), Color(0xFF8B5E1A)],
    'фитнес':       [Color(0xFF2A1A0A), Color(0xFF8B5E1A)],
    'кроссфит':     [Color(0xFF1A2A0A), Color(0xFF4A7A1A)],
    'плавание':     [Color(0xFF0A1A3A), Color(0xFF1A4A8B)],
    'бассейн':      [Color(0xFF0A1A3A), Color(0xFF1A4A8B)],
  };

  /// Подбирает градиент по типу зала. Сравнение нечувствительно к регистру.
  static List<Color> categoryGradient(String type) {
    final t = type.toLowerCase().trim();
    return categoryColors[t] ?? const [Color(0xFF1a1a2e), Color(0xFF16213e)];
  }

  /// Иконка по категории (Material аналоги SVG из макета).
  static IconData categoryIcon(String type) {
    final t = type.toLowerCase().trim();
    if (t.contains('йога') || t.contains('пилатес')) return Icons.self_improvement;
    if (t.contains('единоборств') || t.contains('бокс') || t.contains('мма')) {
      return Icons.sports_mma;
    }
    if (t.contains('кроссфит')) return Icons.directions_run;
    if (t.contains('плаван') || t.contains('бассейн')) return Icons.pool;
    if (t.contains('бодибилд') || t.contains('силов')) return Icons.fitness_center;
    return Icons.fitness_center;
  }

  /// Подходящая иконка для удобства.
  static IconData amenityIcon(String amenity) {
    final a = amenity.toLowerCase();
    if (a.contains('душ')) return Icons.shower;
    if (a.contains('сауна')) return Icons.hot_tub;
    if (a.contains('парковк')) return Icons.local_parking;
    if (a.contains('тренер')) return Icons.person;
    if (a.contains('wi') || a.contains('wifi')) return Icons.wifi;
    if (a.contains('бассейн') || a.contains('плаван')) return Icons.pool;
    if (a.contains('ринг')) return Icons.sports_mma;
    if (a.contains('коврик')) return Icons.crop_landscape;
    if (a.contains('чай') || a.contains('кафе')) return Icons.local_cafe;
    return Icons.check_rounded;
  }

  // === ОТСТУПЫ И СКРУГЛЕНИЯ ===
  static const paddingSmall  = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge  = 24.0;
  static const radiusSmall   = 8.0;
  static const radiusMedium  = 12.0;
  static const radiusLarge   = 16.0;
  static const radiusPill    = 20.0;

  // === ТЕКСТОВЫЕ СТИЛИ ===
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 13,
    color: textTertiary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle priceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: primaryColor,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // === ТЁМНАЯ ТЕМА (основная) ===
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    canvasColor: darkBg,
    dividerColor: darkDivider,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryColor,
      secondary: accentColor,
      surface: darkSurface,
      onSurface: textPrimary,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: darkBorderHi),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputBg,
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: textSecondary),
      prefixIconColor: textTertiary,
      suffixIconColor: textTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkBorderHi),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkBorderHi),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: darkSurfaceHi,
      contentTextStyle: TextStyle(color: textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: textSecondary),
    listTileTheme: const ListTileThemeData(
      iconColor: textSecondary,
      textColor: textPrimary,
    ),
  );

  // === СВЕТЛАЯ ТЕМА (минимальная адаптация) ===
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: lightBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEFEFF2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}