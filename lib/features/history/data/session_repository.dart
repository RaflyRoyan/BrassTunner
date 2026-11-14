import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../tuner/domain/instrument.dart';
import '../domain/practice_session.dart';

/// Stores practice sessions on the device.
abstract interface class SessionRepository {
  /// Saves [session] and returns it with its id.
  Future<PracticeSession> insert(PracticeSession session);

  /// Sessions newest first, optionally for one instrument.
  Future<List<PracticeSession>> list({Instrument? instrument});

  Future<void> delete(int id);
  Future<void> clear();
}

/// In-memory store for tests and as a fallback when the database cannot
/// be opened.
class MemorySessionRepository implements SessionRepository {
  final _sessions = <PracticeSession>[];
  int _nextId = 1;

  @override
  Future<PracticeSession> insert(PracticeSession session) async {
    final saved = session.withId(_nextId++);
    _sessions.add(saved);
    return saved;
  }

  @override
  Future<List<PracticeSession>> list({Instrument? instrument}) async =>
      _sessions
          .where((s) => instrument == null || s.instrument == instrument)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  @override
  Future<void> delete(int id) async => _sessions.removeWhere((s) => s.id == id);

  @override
  Future<void> clear() async => _sessions.clear();
}

/// SQLite-backed store: one row per session plus one per note.
class SqliteSessionRepository implements SessionRepository {
  SqliteSessionRepository(this._db);

  static const fileName = 'practice.db';
  static const _version = 1;

  final Database _db;

  /// Opens (and creates) the database in the app's database directory.
  static Future<SqliteSessionRepository> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              started_at INTEGER NOT NULL,
              duration_ms INTEGER NOT NULL,
              instrument TEXT NOT NULL,
              a4 REAL NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE session_notes (
              session_id INTEGER NOT NULL
                REFERENCES sessions(id) ON DELETE CASCADE,
              midi INTEGER NOT NULL,
              samples INTEGER NOT NULL,
              mean_cents REAL NOT NULL,
              sharp INTEGER NOT NULL,
              flat INTEGER NOT NULL,
              PRIMARY KEY (session_id, midi)
            )''');
          await db.execute(
            'CREATE INDEX sessions_instrument ON sessions(instrument, started_at)',
          );
        },
      ),
    );
    return SqliteSessionRepository(db);
  }

  Future<void> close() => _db.close();

  @override
  Future<PracticeSession> insert(PracticeSession session) =>
      _db.transaction((txn) async {
        final id = await txn.insert('sessions', {
          'started_at': session.startedAt.millisecondsSinceEpoch,
          'duration_ms': session.duration.inMilliseconds,
          'instrument': session.instrument.name,
          'a4': session.a4,
        });
        final batch = txn.batch();
        for (final n in session.notes) {
          batch.insert('session_notes', {
            'session_id': id,
            'midi': n.midi,
            'samples': n.samples,
            'mean_cents': n.meanCents,
            'sharp': n.sharp,
            'flat': n.flat,
          });
        }
        await batch.commit(noResult: true);
        return session.withId(id);
      });

  @override
  Future<List<PracticeSession>> list({Instrument? instrument}) async {
    final rows = await _db.query(
      'sessions',
      where: instrument == null ? null : 'instrument = ?',
      whereArgs: instrument == null ? null : [instrument.name],
      orderBy: 'started_at DESC',
    );
    final notes = await _db.query(
      'session_notes',
      where: instrument == null
          ? null
          : 'session_id IN (SELECT id FROM sessions WHERE instrument = ?)',
      whereArgs: instrument == null ? null : [instrument.name],
      orderBy: 'midi',
    );
    final bySession = <int, List<NoteStat>>{};
    for (final r in notes) {
      (bySession[r['session_id']! as int] ??= []).add(
        NoteStat(
          midi: r['midi']! as int,
          samples: r['samples']! as int,
          meanCents: (r['mean_cents']! as num).toDouble(),
          sharp: r['sharp']! as int,
          flat: r['flat']! as int,
        ),
      );
    }
    final instruments = Instrument.values.asNameMap();
    return [
      for (final r in rows)
        // Skip rows from an instrument a future version removed.
        if (instruments[r['instrument']] case final instrument?)
          PracticeSession(
            id: r['id']! as int,
            startedAt: DateTime.fromMillisecondsSinceEpoch(
              r['started_at']! as int,
            ),
            duration: Duration(milliseconds: r['duration_ms']! as int),
            instrument: instrument,
            a4: (r['a4']! as num).toDouble(),
            notes: bySession[r['id']! as int] ?? const [],
          ),
    ];
  }

  @override
  Future<void> delete(int id) =>
      _db.delete('sessions', where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> clear() => _db.delete('sessions');
}
