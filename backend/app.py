"""API do Campeonato Esportivo (Flask + SQLite).

Implementa exatamente as rotas descritas na "Documentação da API —
Campeonato Esportivo" do exercício prático:

    EQUIPES   GET /listaequipes        POST /cadastraequipe
              PUT /atualizaequipe      DELETE /removeequipe
    JOGADORES GET /listajogadores      POST /cadastrajogador
              PUT /atualizajogador     DELETE /removejogador
    PARTIDAS  GET /listapartidas       GET /listapartidasdetalhada
              POST /cadastrapartida    PUT /atualizapartida
              DELETE /removepartida

Observação: os exemplos de resposta do documento não trazem o identificador
dos registros, mas as rotas PUT/DELETE exigem esse identificador. Por isso
as listagens devolvem, além dos campos do documento, o campo ``id``.
"""
import os
import sqlite3
from datetime import date

from flask import Flask, g, jsonify, request
from flask_cors import CORS

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SCHEMA = """
CREATE TABLE IF NOT EXISTS equipes (
    id_equipe INTEGER PRIMARY KEY AUTOINCREMENT,
    nome      TEXT NOT NULL,
    cidade    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS jogadores (
    id_jogador   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome         TEXT NOT NULL,
    posicao      TEXT NOT NULL,
    id_equipe_fk INTEGER NOT NULL REFERENCES equipes(id_equipe)
);

CREATE TABLE IF NOT EXISTS partidas (
    id_partida          INTEGER PRIMARY KEY AUTOINCREMENT,
    data_partida        TEXT NOT NULL,
    placar_casa         INTEGER NOT NULL CHECK (placar_casa >= 0),
    placar_visitante    INTEGER NOT NULL CHECK (placar_visitante >= 0),
    id_equipe_casa      INTEGER NOT NULL REFERENCES equipes(id_equipe),
    id_equipe_visitante INTEGER NOT NULL REFERENCES equipes(id_equipe),
    CHECK (id_equipe_casa <> id_equipe_visitante)
);
"""


class ValidationError(Exception):
    """Erro de validação do corpo da requisição (HTTP 400)."""


# ---------------------------------------------------------------- validação
def _body():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        raise ValidationError("Envie um JSON válido no corpo da requisição.")
    return data


def _text(data, key):
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValidationError(f"O campo '{key}' é obrigatório (texto).")
    return value.strip()


def _int(data, key, minimum=0):
    value = data.get(key)
    # bool é subclasse de int em Python; rejeitamos explicitamente
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValidationError(f"O campo '{key}' é obrigatório (inteiro).")
    if value < minimum:
        raise ValidationError(f"O campo '{key}' deve ser >= {minimum}.")
    return value


def _date(data, key):
    value = _text(data, key)
    try:
        date.fromisoformat(value)
    except ValueError:
        raise ValidationError(f"O campo '{key}' deve estar no formato AAAA-MM-DD.")
    return value


def _match_fields(data):
    fields = {
        "data": _date(data, "dataPartida"),
        "placar_casa": _int(data, "placarEquipeCasa"),
        "placar_visitante": _int(data, "placarEquipeVisitante"),
        "casa": _int(data, "idEquipeCasa", 1),
        "visitante": _int(data, "idEquipeVisitante", 1),
    }
    if fields["casa"] == fields["visitante"]:
        raise ValidationError("A equipe da casa e a visitante devem ser diferentes.")
    return fields


def create_app(db_path=None):
    app = Flask(__name__)
    app.json.ensure_ascii = False  # mantém acentos no JSON
    app.config["DB_PATH"] = db_path or os.environ.get(
        "DB_PATH", os.path.join(BASE_DIR, "campeonato.db")
    )
    CORS(app)  # necessário para o app Flutter Web (origem diferente)

    # ------------------------------------------------------------ banco
    def get_db():
        if "db" not in g:
            g.db = sqlite3.connect(app.config["DB_PATH"])
            g.db.row_factory = sqlite3.Row
            g.db.execute("PRAGMA foreign_keys = ON")
        return g.db

    @app.teardown_appcontext
    def close_db(_exc):
        db = g.pop("db", None)
        if db is not None:
            db.close()

    with sqlite3.connect(app.config["DB_PATH"]) as conn:
        conn.executescript(SCHEMA)

    def exists(table, column, value):
        row = get_db().execute(
            f"SELECT 1 FROM {table} WHERE {column} = ?", (value,)
        ).fetchone()
        return row is not None

    def ensure_team(team_id):
        if not exists("equipes", "id_equipe", team_id):
            raise ValidationError(f"A equipe {team_id} não existe.")

    def ok(message, status=200, **extra):
        return jsonify({"mensagem": message, **extra}), status

    def not_found(what):
        return jsonify({"erro": f"{what} não encontrado(a)."}), 404

    # ----------------------------------------------------------- erros
    @app.errorhandler(ValidationError)
    def on_validation(err):
        return jsonify({"erro": str(err)}), 400

    @app.errorhandler(sqlite3.IntegrityError)
    def on_integrity(_err):
        return (
            jsonify({"erro": "Operação bloqueada: o registro está em uso por outro cadastro."}),
            409,
        )

    @app.errorhandler(404)
    def on_404(_err):
        return jsonify({"erro": "Rota não encontrada."}), 404

    @app.errorhandler(405)
    def on_405(_err):
        return jsonify({"erro": "Método não permitido para esta rota."}), 405

    @app.get("/")
    def health():
        return jsonify({"api": "Campeonato Esportivo", "status": "online"})

    # ----------------------------------------------------------- equipes
    @app.get("/listaequipes")
    def lista_equipes():
        rows = get_db().execute(
            "SELECT id_equipe AS id, nome, cidade FROM equipes ORDER BY id_equipe"
        ).fetchall()
        return jsonify([dict(r) for r in rows])

    @app.post("/cadastraequipe")
    def cadastra_equipe():
        data = _body()
        nome, cidade = _text(data, "nomeEquipe"), _text(data, "cidadeEquipe")
        cur = get_db().execute(
            "INSERT INTO equipes (nome, cidade) VALUES (?, ?)", (nome, cidade)
        )
        get_db().commit()
        return ok("Equipe cadastrada com sucesso.", 201, id=cur.lastrowid)

    @app.put("/atualizaequipe")
    def atualiza_equipe():
        data = _body()
        id_ = _int(data, "idEquipe", 1)
        nome, cidade = _text(data, "nomeEquipe"), _text(data, "cidadeEquipe")
        cur = get_db().execute(
            "UPDATE equipes SET nome = ?, cidade = ? WHERE id_equipe = ?",
            (nome, cidade, id_),
        )
        get_db().commit()
        return ok("Equipe atualizada com sucesso.") if cur.rowcount else not_found("Equipe")

    @app.delete("/removeequipe")
    def remove_equipe():
        id_ = _int(_body(), "idEquipe", 1)
        cur = get_db().execute("DELETE FROM equipes WHERE id_equipe = ?", (id_,))
        get_db().commit()
        return ok("Equipe removida com sucesso.") if cur.rowcount else not_found("Equipe")

    # --------------------------------------------------------- jogadores
    @app.get("/listajogadores")
    def lista_jogadores():
        rows = get_db().execute(
            "SELECT id_jogador AS id, nome, posicao, id_equipe_fk "
            "FROM jogadores ORDER BY id_jogador"
        ).fetchall()
        return jsonify([dict(r) for r in rows])

    @app.post("/cadastrajogador")
    def cadastra_jogador():
        data = _body()
        nome, posicao = _text(data, "nomeJogador"), _text(data, "posicaoJogador")
        equipe = _int(data, "idEquipeJogador", 1)
        ensure_team(equipe)
        cur = get_db().execute(
            "INSERT INTO jogadores (nome, posicao, id_equipe_fk) VALUES (?, ?, ?)",
            (nome, posicao, equipe),
        )
        get_db().commit()
        return ok("Jogador cadastrado com sucesso.", 201, id=cur.lastrowid)

    @app.put("/atualizajogador")
    def atualiza_jogador():
        data = _body()
        id_ = _int(data, "idJogador", 1)
        nome, posicao = _text(data, "nomeJogador"), _text(data, "posicaoJogador")
        equipe = _int(data, "idEquipeJogador", 1)
        ensure_team(equipe)
        cur = get_db().execute(
            "UPDATE jogadores SET nome = ?, posicao = ?, id_equipe_fk = ? "
            "WHERE id_jogador = ?",
            (nome, posicao, equipe, id_),
        )
        get_db().commit()
        return ok("Jogador atualizado com sucesso.") if cur.rowcount else not_found("Jogador")

    @app.delete("/removejogador")
    def remove_jogador():
        id_ = _int(_body(), "idJogador", 1)
        cur = get_db().execute("DELETE FROM jogadores WHERE id_jogador = ?", (id_,))
        get_db().commit()
        return ok("Jogador removido com sucesso.") if cur.rowcount else not_found("Jogador")

    # ---------------------------------------------------------- partidas
    @app.get("/listapartidas")
    def lista_partidas():
        rows = get_db().execute(
            "SELECT id_partida AS id, data_partida AS dataPartida, "
            "placar_casa AS placarCasa, placar_visitante AS placarVisitante, "
            "id_equipe_casa AS equipeCasa, id_equipe_visitante AS equipeVisitante "
            "FROM partidas ORDER BY id_partida"
        ).fetchall()
        return jsonify([dict(r) for r in rows])

    @app.get("/listapartidasdetalhada")
    def lista_partidas_detalhada():
        rows = get_db().execute(
            "SELECT p.id_partida AS id, p.data_partida AS dataPartida, "
            "c.nome AS equipeCasa, v.nome AS equipeVisitante, "
            "p.placar_casa AS placarCasa, p.placar_visitante AS placarVisitante "
            "FROM partidas p "
            "JOIN equipes c ON c.id_equipe = p.id_equipe_casa "
            "JOIN equipes v ON v.id_equipe = p.id_equipe_visitante "
            "ORDER BY p.id_partida"
        ).fetchall()
        return jsonify([dict(r) for r in rows])

    @app.post("/cadastrapartida")
    def cadastra_partida():
        f = _match_fields(_body())
        ensure_team(f["casa"])
        ensure_team(f["visitante"])
        cur = get_db().execute(
            "INSERT INTO partidas (data_partida, placar_casa, placar_visitante, "
            "id_equipe_casa, id_equipe_visitante) VALUES (?, ?, ?, ?, ?)",
            (f["data"], f["placar_casa"], f["placar_visitante"], f["casa"], f["visitante"]),
        )
        get_db().commit()
        return ok("Partida cadastrada com sucesso.", 201, id=cur.lastrowid)

    @app.put("/atualizapartida")
    def atualiza_partida():
        data = _body()
        id_ = _int(data, "idPartida", 1)
        f = _match_fields(data)
        ensure_team(f["casa"])
        ensure_team(f["visitante"])
        cur = get_db().execute(
            "UPDATE partidas SET data_partida = ?, placar_casa = ?, "
            "placar_visitante = ?, id_equipe_casa = ?, id_equipe_visitante = ? "
            "WHERE id_partida = ?",
            (f["data"], f["placar_casa"], f["placar_visitante"], f["casa"], f["visitante"], id_),
        )
        get_db().commit()
        return ok("Partida atualizada com sucesso.") if cur.rowcount else not_found("Partida")

    @app.delete("/removepartida")
    def remove_partida():
        id_ = _int(_body(), "idPartida", 1)
        cur = get_db().execute("DELETE FROM partidas WHERE id_partida = ?", (id_,))
        get_db().commit()
        return ok("Partida removida com sucesso.") if cur.rowcount else not_found("Partida")

    return app


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    # host 0.0.0.0 permite acesso pelo emulador/celular na mesma rede
    create_app().run(host="0.0.0.0", port=port, debug=False)
