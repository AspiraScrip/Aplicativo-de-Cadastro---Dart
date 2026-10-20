import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final caminho = join(await getDatabasesPath(), 'gerenciador_pessoas.db');

    _database = await openDatabase(
      caminho,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL COLLATE NOCASE UNIQUE,
            senha TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE pessoas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            nome TEXT NOT NULL,
            email TEXT NOT NULL,
            telefone TEXT NOT NULL,
            FOREIGN KEY (usuario_id)
              REFERENCES usuarios(id)
              ON DELETE CASCADE
          )
        ''');
      },
    );

    return _database!;
  }

  // CADASTRAR USUÁRIO
  Future<int> cadastrarUsuario(String nome, String email, String senha) async {
    final db = await database;

    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();

    if (nomeLimpo.isEmpty || emailLimpo.isEmpty || senha.isEmpty) {
      throw Exception('PREENCHA_TODOS_OS_CAMPOS');
    }

    final existentes = await db.query(
      'usuarios',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [emailLimpo],
      limit: 1,
    );

    if (existentes.isNotEmpty) {
      throw Exception('EMAIL_DUPLICADO');
    }

    try {
      return await db.insert('usuarios', {
        'nome': nomeLimpo,
        'email': emailLimpo,
        'senha': senha,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } catch (erro) {
      // Também protege contra uma inserção duplicada concorrente.
      if (erro.toString().toLowerCase().contains('unique constraint')) {
        throw Exception('EMAIL_DUPLICADO');
      }

      rethrow;
    }
  }

  // LOGIN
  Future<Map<String, Object?>?> login(String email, String senha) async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email.trim().toLowerCase(), senha],
      limit: 1,
    );

    return resultado.isEmpty ? null : resultado.first;
  }

  // LISTAR PESSOAS DO USUÁRIO LOGADO
  Future<List<Map<String, Object?>>> listarPessoas(int usuarioId) async {
    final db = await database;

    return db.query(
      'pessoas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'nome COLLATE NOCASE',
    );
  }

  // CADASTRAR PESSOA
  Future<int> inserirPessoa(
    int usuarioId,
    String nome,
    String email,
    String telefone,
  ) async {
    final db = await database;

    return db.insert('pessoas', {
      'usuario_id': usuarioId,
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone.trim(),
    });
  }

  // ATUALIZAR PESSOA
  Future<int> atualizarPessoa(
    int id,
    int usuarioId,
    String nome,
    String email,
    String telefone,
  ) async {
    final db = await database;

    return db.update(
      'pessoas',
      {'nome': nome.trim(), 'email': email.trim(), 'telefone': telefone.trim()},
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }

  // EXCLUIR PESSOA
  Future<int> excluirPessoa(int id, int usuarioId) async {
    final db = await database;

    return db.delete(
      'pessoas',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }
}
