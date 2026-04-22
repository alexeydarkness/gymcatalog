class Review {
  final int id;
  final int gymId;
  final String username;
  final int rating;
  final String text;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.gymId,
    required this.username,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

    factory Review.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['Id'] ?? json['ID'];
    final int parsedId = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final dynamic rawGymId = json['gymId'] ?? json['GymId'];
    final int parsedGymId = rawGymId is num
        ? rawGymId.toInt()
        : int.tryParse(rawGymId?.toString() ?? '') ?? 0;

    return Review(
      id: parsedId,
      gymId: parsedGymId,
      username: json['username'] ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).toInt() : 0,
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() => {
        'username': username,
        'rating': rating,
        'text': text,
      };
}