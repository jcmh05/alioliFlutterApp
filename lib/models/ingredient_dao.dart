import 'package:sqflite/sqflite.dart';

import 'models.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/database/database_helper.dart';

// Clase para manejar la tabla ingrediente en SQLite
class IngredientDao {
  final Log = logger(IngredientDao);

  // Método para obtener la base de datos de forma segura
  Future<Database> get _database async => DataBaseHelper.instance.db;

  // Método para leer todos los registros de la base de datos
  Future<List<Ingredient>> readAll(String table) async {
    Log.i('readAll');
    final db = await _database; // Asegura el acceso asíncrono a la base de datos
    final data = await db.query(table);
    return data.map((e) => Ingredient.fromMap(e)).toList();
  }

  // Método para insertar ingrediente
  Future<int> insert(Ingredient ingredient, String table) async {
    final db = await _database; // Asegura el acceso asíncrono a la base de datos
    Log.i('insert');
    return await db.insert(table, ingredient.toMap());
  }

  // Método para actualizar ingrediente
  Future<void> update(Ingredient ingredient, String table) async {
    final db = await _database; // Asegura el acceso asíncrono a la base de datos
    Log.i('update');
    await db.update(table, ingredient.toMap(), where: 'idIngredient = ?', whereArgs: [ingredient.idIngredient]);
  }

  // Método para borrar ingrediente
  Future<void> delete(String id, String table) async {
    final db = await _database; // Asegura el acceso asíncrono a la base de datos
    Log.i('delete');
    await db.delete(table, where: 'idIngredient = ?', whereArgs: [id]);
  }
}
