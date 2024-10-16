
class Ingredient {
  final String id;
  final String idIngredient;
  final String name;
  final String icon;
  final int amount;
  final String unit;
  final DateTime date;
  final String barcode;
  final bool head;

  Ingredient({
    required this.id,
    required this.idIngredient,
    required this.name,
    required this.icon,
    required this.amount,
    required this.unit,
    required this.date,
    required this.barcode,
    this.head = false
  });

  // Constructor copia con capacidad de recibir parámetros nulos
  Ingredient copyConstructor({String? id,String? idIng, String? name, String? icon,int? amount, DateTime? date,String? barcode,bool? head}) {
    return Ingredient(
      id: id ?? this.id,
      idIngredient: idIng ?? this.idIngredient,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      date: date?? this.date,
      barcode: this.barcode,
      head: head ?? this.head,
    );
  }

  // Constructor factoría, crea instancia de ingredient a partir de un map de un DataBase
  factory Ingredient.fromMap(Map<String,dynamic> map){
    return Ingredient(
        id: map['id'],
        idIngredient: map['idIngredient'] ?? '0',
        name: map['name'] ?? 'Ingrediente',
        icon: map['icon'] ?? 'ingredient',
        unit: map['unit'] ?? 'und',
        amount: map['amount'] ?? 0,
        date: map['date'] != null ? DateTime.parse(map['date']) : DateTime(3000, 1, 1),
        barcode: map['barcode'] ?? '0',
        head: map['head'] == 1 ? true : false
    );
  }

  // Crea un map para poder ser ingresado en la base de datos
  Map<String,dynamic> toMap() => {
    'id': id,
    'idIngredient': idIngredient,
    'name': name,
    'icon': icon,
    'unit': unit,
    'amount' : amount,
    'head': head ? 1 : 0,
    'barcode' : barcode,
    'date': date.toIso8601String(),
  };

  @override
  String toString() {
    return '$name -> {id: $id, idIngredient: $idIngredient, icon: $icon, amount: $amount, unit: $unit, date: $date, barcode: $barcode,head: $head}\n\n';
  }
}
