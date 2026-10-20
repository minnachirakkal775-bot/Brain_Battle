import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
DatabaseHelper._privateConstructor();

static final DatabaseHelper instance =
DatabaseHelper._privateConstructor();

static Database? _database;

// ------------------------------------------------------------
// DATABASE
// ------------------------------------------------------------

Future<Database> get database async {
if (_database != null) {
return _database!;
}

_database = await _initDatabase();
return _database!;
}

Future<Database> _initDatabase() async {
final databasesPath = await getDatabasesPath();
final databasePath = join(
databasesPath,
'brain_battle.db',
);

return await openDatabase(
databasePath,
version: 1,
onCreate: _createDatabase,
);
}

// ------------------------------------------------------------
// CREATE TABLES
// ------------------------------------------------------------

Future<void> _createDatabase(
Database db,
int version,
) async {
// ----------------------------------------------------------
// PLAYERS
// ----------------------------------------------------------

await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

// ----------------------------------------------------------
// GAME SESSIONS
// ----------------------------------------------------------

await db.execute('''
      CREATE TABLE game_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        game_type TEXT NOT NULL,
        level INTEGER NOT NULL,
        score INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        duration_seconds INTEGER NOT NULL,
        played_at TEXT NOT NULL,

        FOREIGN KEY (player_id)
          REFERENCES players(id)
      )
    ''');

// ----------------------------------------------------------
// QUESTION RESULTS
// ----------------------------------------------------------

await db.execute('''
      CREATE TABLE question_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        question_id TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        response_time_ms INTEGER NOT NULL,

        FOREIGN KEY (session_id)
          REFERENCES game_sessions(id)
      )
    ''');

// ----------------------------------------------------------
// LEVEL PROGRESS
// ----------------------------------------------------------

await db.execute('''
      CREATE TABLE level_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        game_type TEXT NOT NULL,
        level INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        stars INTEGER NOT NULL DEFAULT 0,
        best_score INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (player_id)
          REFERENCES players(id),

        UNIQUE(
          player_id,
          game_type,
          level
        )
      )
    ''');

// ----------------------------------------------------------
// ACHIEVEMENTS
// ----------------------------------------------------------

await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        achievement_code TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,

        FOREIGN KEY (player_id)
          REFERENCES players(id),

        UNIQUE(
          player_id,
          achievement_code
        )
      )
    ''');

// ----------------------------------------------------------
// PLAYER SETTINGS
// ----------------------------------------------------------

await db.execute('''
      CREATE TABLE player_settings (
        player_id INTEGER PRIMARY KEY,
        sound_enabled INTEGER NOT NULL DEFAULT 1,
        theme TEXT NOT NULL DEFAULT 'system',
        difficulty INTEGER NOT NULL DEFAULT 1,

        FOREIGN KEY (player_id)
          REFERENCES players(id)
      )
    ''');
}

// ============================================================
// PLAYER FUNCTIONS
// ============================================================

Future<int> createPlayer(String name) async {
final db = await database;

return await db.insert(
'players',
{
'name': name,
'created_at': DateTime.now().toIso8601String(),
},
);
}

Future<List<Map<String, dynamic>>> getPlayers() async {
final db = await database;

return await db.query(
'players',
orderBy: 'id ASC',
);
}

// ============================================================
// GAME SESSION FUNCTIONS
// ============================================================

Future<int> saveGameSession({
int? playerId,
required String gameType,
required int level,
required int score,
required double accuracy,
required int durationSeconds,
}) async {
final db = await database;

return await db.insert(
'game_sessions',
{
'player_id': playerId,
'game_type': gameType,
'level': level,
'score': score,
'accuracy': accuracy,
'duration_seconds': durationSeconds,
'played_at': DateTime.now().toIso8601String(),
},
);
}

Future<List<Map<String, dynamic>>> getGameSessions(
String gameType,
) async {
final db = await database;

return await db.query(
'game_sessions',
where: 'game_type = ?',
whereArgs: [gameType],
orderBy: 'played_at DESC',
);
}

Future<List<Map<String, dynamic>>> getAllGameSessions() async {
final db = await database;

return await db.query(
'game_sessions',
orderBy: 'played_at DESC',
);
}

// ============================================================
// QUESTION RESULT FUNCTIONS
// ============================================================

Future<int> saveQuestionResult({
required int sessionId,
required String questionId,
required bool isCorrect,
required int responseTimeMs,
}) async {
final db = await database;

return await db.insert(
'question_results',
{
'session_id': sessionId,
'question_id': questionId,
'is_correct': isCorrect ? 1 : 0,
'response_time_ms': responseTimeMs,
},
);
}

Future<List<Map<String, dynamic>>> getRecentQuestionResults({
required String gameType,
int limit = 10,
}) async {
final db = await database;

return await db.rawQuery(
'''
      SELECT
        qr.id,
        qr.session_id,
        qr.question_id,
        qr.is_correct,
        qr.response_time_ms,
        gs.game_type,
        gs.level
      FROM question_results qr

      INNER JOIN game_sessions gs
        ON qr.session_id = gs.id

      WHERE gs.game_type = ?

      ORDER BY qr.id DESC

      LIMIT ?
      ''',
[
gameType,
limit,
],
);
}

// ============================================================
// LEVEL PROGRESS
// ============================================================

Future<void> saveLevelProgress({
int? playerId,
required String gameType,
required int level,
required bool completed,
required int stars,
required int bestScore,
}) async {
final db = await database;

final existing = await db.query(
'level_progress',
where: '''
        player_id = ?
        AND game_type = ?
        AND level = ?
      ''',
whereArgs: [
playerId,
gameType,
level,
],
limit: 1,
);

if (existing.isEmpty) {
await db.insert(
'level_progress',
{
'player_id': playerId,
'game_type': gameType,
'level': level,
'completed': completed ? 1 : 0,
'stars': stars,
'best_score': bestScore,
'attempts': 1,
},
);
return;
}

final current = existing.first;

final oldBestScore =
(current['best_score'] as int?) ?? 0;

final oldStars =
(current['stars'] as int?) ?? 0;

final oldAttempts =
(current['attempts'] as int?) ?? 0;

await db.update(
'level_progress',
{
'completed':
completed ? 1 : (current['completed'] ?? 0),
'stars': stars > oldStars ? stars : oldStars,
'best_score':
bestScore > oldBestScore
? bestScore
    : oldBestScore,
'attempts': oldAttempts + 1,
},
where: '''
        player_id = ?
        AND game_type = ?
        AND level = ?
      ''',
whereArgs: [
playerId,
gameType,
level,
],
);
}

Future<List<Map<String, dynamic>>> getLevelProgress(
String gameType,
) async {
final db = await database;

return await db.query(
'level_progress',
where: 'game_type = ?',
whereArgs: [gameType],
orderBy: 'level ASC',
);
}

// ============================================================
// ACHIEVEMENTS
// ============================================================

Future<void> saveAchievement({
int? playerId,
required String achievementCode,
}) async {
final db = await database;

await db.insert(
'achievements',
{
'player_id': playerId,
'achievement_code': achievementCode,
'unlocked_at':
DateTime.now().toIso8601String(),
},
conflictAlgorithm:
ConflictAlgorithm.ignore,
);
}

Future<List<Map<String, dynamic>>> getAchievements() async {
final db = await database;

return await db.query(
'achievements',
orderBy: 'unlocked_at DESC',
);
}

// ============================================================
// PLAYER SETTINGS
// ============================================================

Future<void> savePlayerSettings({
required int playerId,
required bool soundEnabled,
required String theme,
required int difficulty,
}) async {
final db = await database;

await db.insert(
'player_settings',
{
'player_id': playerId,
'sound_enabled':
soundEnabled ? 1 : 0,
'theme': theme,
'difficulty': difficulty,
},
conflictAlgorithm:
ConflictAlgorithm.replace,
);
}

Future<Map<String, dynamic>?> getPlayerSettings(
int playerId,
) async {
final db = await database;

final results = await db.query(
'player_settings',
where: 'player_id = ?',
whereArgs: [playerId],
limit: 1,
);

if (results.isEmpty) {
return null;
}

return results.first;
}

// ============================================================
// ADAPTIVE DIFFICULTY SUPPORT
// ============================================================

Future<double> getRecentAccuracy(
String gameType, {
int limit = 10,
}) async {
final results =
await getRecentQuestionResults(
gameType: gameType,
limit: limit,
);

if (results.isEmpty) {
return 0.0;
}

int correct = 0;

for (final result in results) {
if (result['is_correct'] == 1) {
correct++;
}
}

return correct / results.length;
}

// ============================================================
// DATABASE INFORMATION
// ============================================================

Future<String> getDatabasePath() async {
final databasesPath =
await getDatabasesPath();

return join(
databasesPath,
'brain_battle.db',
);
}

// ============================================================
// CLOSE DATABASE
// ============================================================

Future<void> closeDatabase() async {
if (_database != null) {
await _database!.close();
_database = null;
}
}
}