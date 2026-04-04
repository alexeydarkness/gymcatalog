class Gym {
  final int id;
  final String name;
  final String address;
  final String imageUrl;
  final double rating;
  final double pricePerMonth;
  final String type;
  final List<String> amenities;
  bool isFavorite;
  bool isDeleted;

Gym({
  required this.id,
  required this.name,
  required this.address,
  required this.imageUrl,
  required this.rating,
  required this.pricePerMonth,
  required this.type,
  required this.amenities,
  this.isFavorite = false,
  this.isDeleted = false,
});

factory Gym.fromJson(Map<String, dynamic>json) {
  return Gym(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    imageUrl: json['imageUrl'] ?? '',
    rating: json['rating'].toDouble(),
    pricePerMonth: json['pricePerMonth'].toDouble(),
    type: json['type'],
    amenities: List<String>.from(json['amenities']),  
  );
}

Map<String, dynamic> toJson() {
  return {
    'id': id,
    'name': name,
    'address': address,
    'imageUrl': imageUrl,
    'rating': rating,
    'pricePerMonth': pricePerMonth,
    'type': type,
    'amenities': amenities
  };
}

}
