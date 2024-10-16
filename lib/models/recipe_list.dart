import 'package:alioli/models/models.dart';

class RecipeList {
  final String idList;
  final String name;
  final String emailUser;
  final String iconId;
  final List<Recipe> recipes;
  final bool visible;
  final String descripcion;
  final List<String> likes;

  RecipeList({
    required this.idList,
    required this.name,
    required this.emailUser,
    required this.iconId,
    required this.recipes,
    required this.visible,
    required this.descripcion,
    required this.likes,
  });

  RecipeList copyWith({
    String? idList,
    String? name,
    String? emailUser,
    String? iconId,
    List<Recipe>? recipes,
    bool? visible,
    String? descripcion,
    List<String>? likes,
  }) {
    return RecipeList(
      idList: idList ?? this.idList,
      name: name ?? this.name,
      emailUser: emailUser ?? this.emailUser,
      iconId: iconId ?? this.iconId,
      recipes: recipes ?? this.recipes,
      visible: visible ?? this.visible,
      descripcion: descripcion ?? this.descripcion,
      likes: likes ?? this.likes,
    );
  }

  // Método para convertir una instancia de RecipeList a un mapa
  Map<String, dynamic> toMap() {
    return {
      'idList': idList,
      'name': name,
      'emailUser': emailUser,
      'iconId': iconId,
      'recipes': recipes.map((recipe) => recipe.toMap()).toList(),
      'visible': visible,
      'descripcion': descripcion,
      'likes': likes, // nuevo campo
    };
  }

  // Método para crear una instancia de RecipeList a partir de un mapa
  factory RecipeList.fromMap(Map<String, dynamic> map) {
    return RecipeList(
      idList: map['idList'] ?? '',
      name: map['name'] ?? '',
      emailUser: map['emailUser'] ?? '',
      iconId: map['iconId'] ?? '',
      recipes: (map['recipes'] as List).map((recipe) => Recipe.fromMap(recipe)).toList() ?? [],
      visible: map['visible'] ?? false,
      descripcion: map['descripcion'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  @override
  String toString() {
    return 'RecipeList{idList: $idList, name: $name, descripcion: $descripcion, likes: $likes}';
  }

  void addRecipe(Recipe recipe) {
    this.recipes.add(recipe);
  }
}