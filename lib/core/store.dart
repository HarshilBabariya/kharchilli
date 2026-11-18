import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// One document table for every entity kind plus a preferences entry for [Settings].
class Store {
  Store._(this._db, this._prefs);

  final Database _db;
  final SharedPreferences _prefs;
  static const _settingsKey = 'settings';

  static Future<Store> open() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'gharcha.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE docs (id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, body TEXT NOT NULL)');
        await db.execute('CREATE INDEX docs_kind ON docs(kind)');
      },
    );
    return Store._(db, await SharedPreferences.getInstance());
  }

  Future<List<T>> load<T extends Doc>(String kind, T Function(Json) decode) async {
    final rows = await _db.query('docs', where: 'kind = ?', whereArgs: [kind], orderBy: 'id');
    return [
      for (final row in rows) decode((jsonDecode(row['body'] as String) as Map).cast<String, dynamic>())..id = row['id'] as int,
    ];
  }

  Future<void> save(Doc doc) async {
    final body = jsonEncode(doc.toJson());
    if (doc.id == 0) {
      doc.id = await _db.insert('docs', {'kind': doc.kind, 'body': body});
    } else {
      await _db.update('docs', {'body': body}, where: 'id = ?', whereArgs: [doc.id]);
    }
  }

  Future<void> remove(Doc doc) => _db.delete('docs', where: 'id = ?', whereArgs: [doc.id]);

  Settings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    return raw == null ? Settings() : Settings.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  Future<void> saveSettings(Settings settings) => _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

  /// Everything in the store as one JSON document, for a backup file.
  Future<String> dump() async => jsonEncode({
        'app': 'gharcha',
        'version': 1,
        'settings': _prefs.getString(_settingsKey),
        'docs': await _db.query('docs', orderBy: 'id'),
      });

  /// Replaces everything with a document made by [dump]. Returns false, changing nothing, when it is not one.
  Future<bool> restore(String backup) async {
    final Object? data;
    try {
      data = jsonDecode(backup);
    } on FormatException {
      return false;
    }
    if (data is! Map || data['app'] != 'gharcha' || data['docs'] is! List || data['settings'] is! String) return false;
    final rows = [for (final row in data['docs'] as List) (row as Map).cast<String, Object?>()];
    if (rows.any((r) => r['id'] is! int || r['kind'] is! String || r['body'] is! String)) return false;
    await _db.transaction((txn) async {
      await txn.delete('docs');
      for (final row in rows) {
        await txn.insert('docs', {'id': row['id'], 'kind': row['kind'], 'body': row['body']});
      }
    });
    await _prefs.setString(_settingsKey, data['settings'] as String);
    return true;
  }

  Future<void> wipe() async {
    await _db.delete('docs');
    await _prefs.remove(_settingsKey);
  }
}
