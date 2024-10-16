import 'package:alioli/models/ingredient.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:alioli/components/components.dart';
import 'package:flutter/services.dart' show rootBundle;

// Carga el archivo json con los ingredientes
Future<List<Map<String, dynamic>>> loadIngredients() async {
  String jsonString = await rootBundle.loadString('assets/ingredients.json');
  return List<Map<String, dynamic>>.from(json.decode(jsonString));
}

class DataBaseHelper {
  final Log = logger(DataBaseHelper);
  static DataBaseHelper? _databaseHelper;
  DataBaseHelper._internal();
  static DataBaseHelper get instance => _databaseHelper ??= DataBaseHelper._internal();

  Database? _db;
  Database get db => _db!;

  Future<void> init() async {
    Log.i('Iniciando base de datos');
    _db = await openDatabase(
        'database.db',
        version: 1,
        onCreate: (db,version) async { // Asegúrate de que onCreate es una función asíncrona
          // Creación de tablas
          Log.i('Creando base de datos');
          db.execute('CREATE TABLE ingredients (id TEXT PRIMARY KEY, name varchar(255), icon varchar(255), unit varchar(255), head BOOLEAN DEFAULT 0)');
          db.execute('CREATE TABLE pantry (idIngredient TEXT PRIMARY KEY, id varchar(255), name varchar(255), icon varchar(255), amount INTEGER, unit varchar(255), date varchar(255), barcode varchar(255),head BOOLEAN DEFAULT 0);');
          db.execute('CREATE TABLE basket (idIngredient TEXT PRIMARY KEY, id varchar(255), name varchar(255), icon varchar(255), amount INTEGER, unit varchar(255), date varchar(255), barcode varchar(255),head BOOLEAN DEFAULT 0);');
          // Llamada a la función para cargar e insertar los ingredientes
          await loadAndInsertIngredients(db); // Espera a que se complete la inserción de datos
        });

    // Inicializa los ingredientes globales
    final data = await _db!.query('ingredients');
    globalIngredients = data.map((e) => Ingredient.fromMap(e)).toList();
  }

  Future<void> reloadIngredients() async {
    Log.i('Recargando ingredientes');

    // Elimina todos los registros de la tabla 'ingredients'
    await _db!.delete('ingredients');

    // Recarga los ingredientes desde el archivo JSON
    var ingredientesIniciales = await loadIngredients();

    for (var ingrediente in ingredientesIniciales) {
      await _db!.insert('ingredients', ingrediente);
    }

    // Actualiza los ingredientes globales
    final data = await _db!.query('ingredients');
    globalIngredients = data.map((e) => Ingredient.fromMap(e)).toList();
  }

  Future<void> loadAndInsertIngredients(Database db) async {
    // Datos iniciales
    var ingredientesIniciales = await loadIngredients();

    for (var ingrediente in ingredientesIniciales) {
      await db.insert('ingredients', ingrediente);
    }
  }
}
