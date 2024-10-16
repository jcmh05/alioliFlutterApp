import 'dart:typed_data';
import 'dart:ui';

class Recipe{
  final String id;
  final String emailUser;
  final String name;
  final String description;
  final String createdAt;
  final List<String> instructions;
  final List<double> quantities;
  final List<String> ingredients;
  final List<String> units;
  final int numPersons;
  final Uint8List image;
  final List<String> likes;
  final int minutes;
  final List<String> mealtime; // breakfast, lunch, dinner, snack, appetizer, dessert
  final List<String> tags; // vegan, vegetarian, high-protein, healthy, low-carb, low-fat, low-calories, high-fiber, halal
  final String? region; // american, chinese, spanish, french, indian, italian, japanese, mexican, thai, turkish, argentine, greek
  final bool visible;
  // Enlaces a vídeos
  final String? youtubeUrl;
  final String? tiktokUrl;
  final String? instagramUrl;
  final String? otherUrl;

  Recipe({
    required this.id,
    required this.emailUser,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.instructions,
    required this.quantities,
    required this.ingredients,
    required this.units,
    required this.numPersons,
    required this.image,
    required this.likes,
    required this.minutes,
    required this.mealtime,
    required this.tags,
    required this.visible,
    this.region,
    this.youtubeUrl,
    this.tiktokUrl,
    this.instagramUrl,
    this.otherUrl,
  });



  // Método para convertir una instancia de Recipe a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emailUser': emailUser,
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'instructions': instructions,
      'quantities': quantities,
      'ingredients': ingredients,
      'units': units,
      'numPersons': numPersons,
      'image': image,
      'likes': likes,
      'minutes': minutes,
      'mealtime': mealtime,
      'tags': tags,
      'visible': visible,
      'region': region,
      'youtubeUrl': youtubeUrl,
      'tiktokUrl': tiktokUrl,
      'instagramUrl': instagramUrl,
      'otherUrl': otherUrl,
    };
  }

  // Método para crear una instancia de Recipe a partir de un mapa
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      emailUser: map['emailUser'],
      name: map['name'],
      description: map['description'],
      createdAt: map['createdAt'],
      instructions: List<String>.from(map['instructions']),
      quantities: (map['quantities'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      ingredients: List<String>.from(map['ingredients']),
      units: List<String>.from(map['units']),
      numPersons: map['numPersons'] ?? 1,
      image: map['image'] is Uint8List ? map['image'] : Uint8List.fromList(List<int>.from(map['image'])),
      likes: List<String>.from(map['likes']),
      minutes: map['minutes'],
      mealtime: List<String>.from(map['mealtime']),
      tags: List<String>.from(map['tags']),
      visible: map['visible'],
      region: map['region'],
      youtubeUrl: map['youtubeUrl'],
      tiktokUrl: map['tiktokUrl'],
      instagramUrl: map['instagramUrl'],
      otherUrl: map['otherUrl'],
    );
  }

  @override
  String toString() {
    return 'Recipe{id: $id, name: $name}';
  }
}