# GymCatalog

Кросс-платформенное приложение «Каталог спортивных залов». Пользователи просматривают, ищут и сравнивают залы, а администраторы управляют каталогом. Клиент на Flutter (Android, iOS, Windows), сервер на Spring Boot, база данных PostgreSQL.

## Возможности

- Каталог залов с поиском по названию и адресу
- Фильтрация по типу, удобствам и цене, сортировка по рейтингу, цене и названию
- Избранное (сохраняется отдельно для каждого пользователя)
- Сравнение до трёх залов по рейтингу, цене и удобствам
- Отзывы с оценкой и автоматический пересчёт рейтинга зала
- Две роли: пользователь и администратор
- Управление каталогом администратором: создание, редактирование, удаление
- Корзина с восстановлением удалённых залов (мягкое удаление)
- Светлая и тёмная темы

## Технологии

**Клиент:** Flutter, Dart, Provider (управление состоянием), http, shared_preferences

**Сервер:** Spring Boot 4, Java 17, Spring Data JPA / Hibernate, Spring Validation, Lombok

**База данных:** PostgreSQL 15+

## Архитектура

Трёхзвенная архитектура: клиент общается с сервером по REST API (JSON поверх HTTP), сервер работает с базой через Hibernate.

```
Flutter (устройство)  ──HTTP/REST──▶  Spring Boot (порт 8080)  ──JDBC──▶  PostgreSQL (порт 5432)
```

## Структура проекта

### Клиент (curs_proj/)

```
lib/
├── main.dart                     # точка входа, инициализация провайдеров
├── models/
│   ├── gym.dart                  # модель зала (fromJson/toJson)
│   └── review.dart               # модель отзыва
├── providers/
│   ├── gym_provider.dart         # состояние: залы, фильтры, избранное, корзина, сравнение
│   └── theme_provider.dart       # переключение и сохранение темы
├── services/
│   ├── api_services.dart         # HTTP-запросы к REST API
│   └── storage_service.dart      # локальное хранилище (роль, избранное)
├── styles/
│   └── app_styles.dart           # цвета, отступы, темы, иконки
└── screens/
    ├── login_screen.dart         # вход
    ├── register_screen.dart      # регистрация
    ├── gym_list_screen.dart      # главный экран (каталог)
    ├── gym_detail_screen.dart    # детали зала и отзывы
    ├── gym_edit_screen.dart      # создание/редактирование зала
    ├── filter_screen.dart        # фильтры
    ├── favorites_screen.dart     # избранное
    ├── trash_screen.dart         # корзина
    ├── compare_screen.dart       # сравнение
    └── profile_screen.dart       # профиль и настройки
```

### Сервер (gymcatalog/)

```
src/main/java/com/example/gymcatalog/
├── GymcatalogApplication.java    # точка входа
├── model/
│   ├── Gym.java                  # сущность gyms
│   ├── User.java                 # сущность users
│   └── Review.java               # сущность reviews
├── repository/
│   ├── GymRepository.java        # доступ к залам
│   ├── UserRepository.java       # доступ к пользователям
│   └── ReviewRepository.java     # доступ к отзывам
├── controller/
│   ├── GymController.java        # /api/gyms: CRUD, корзина, восстановление
│   ├── AuthController.java       # /api/auth: вход, регистрация
│   └── ReviewController.java     # /api/gyms/{id}/reviews: отзывы, рейтинг
└── config/
    └── WebConfig.java            # настройка CORS
```

## REST API

Базовый URL: `http://localhost:8080`. Все запросы и ответы в формате JSON.

| Метод | Эндпоинт | Описание |
|---|---|---|
| GET | /api/gyms | Список активных залов |
| GET | /api/gyms/{id} | Зал по ID |
| POST | /api/gyms | Создать зал (админ) |
| PUT | /api/gyms/{id} | Обновить зал (админ) |
| DELETE | /api/gyms/{id} | Мягко удалить зал |
| GET | /api/gyms/deleted | Список удалённых залов (корзина) |
| PUT | /api/gyms/{id}/restore | Восстановить зал из корзины |
| GET | /api/gyms/{id}/reviews | Отзывы зала |
| POST | /api/gyms/{id}/reviews | Добавить отзыв |
| DELETE | /api/reviews/{id} | Удалить отзыв |
| POST | /api/auth/login | Авторизация |
| POST | /api/auth/register | Регистрация |

## Запуск

### Требования

- Java 17+
- PostgreSQL 15+
- Flutter SDK 3.x и Dart SDK

### Сервер

1. Создать базу данных:
   ```sql
   CREATE DATABASE gymcatalog;
   ```
2. В файле `src/main/resources/application.properties` указать свои имя пользователя и пароль PostgreSQL.
3. Запустить сервер:
   ```bash
   mvn spring-boot:run
   ```
   Сервер будет доступен на `http://localhost:8080`. Таблицы создаются автоматически при первом запуске.

### Клиент

1. В файле `lib/services/api_services.dart` проверить адрес сервера (`_host`). Для эмулятора Android используйте `http://10.0.2.2:8080` вместо `localhost`.
2. Установить зависимости:
   ```bash
   flutter pub get
   ```
3. Запустить:
   ```bash
   flutter run                # мобильное устройство или эмулятор
   flutter run -d windows     # десктоп Windows
   ```
4. При первом запуске зарегистрировать пользователя. Для администратора выбрать роль admin при регистрации.

## База данных

Три таблицы:

- **gyms** — залы (название, адрес, картинка, рейтинг, цена, тип, удобства, флаг удаления)
- **users** — пользователи (логин, пароль, роль)
- **reviews** — отзывы (зал, автор, оценка 1-5, текст, дата)

## Примечания

Проект учебный. Пароли хранятся в открытом виде, аутентификация по токенам не реализована. Для продакшена следует добавить хеширование паролей, серверную проверку прав по ролям и миграции схемы БД.
