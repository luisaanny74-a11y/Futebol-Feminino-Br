"""Popula o banco com os dados de EXEMPLO que aparecem nas telas do PDF.

Uso:  python seed.py
Só insere se as tabelas estiverem vazias. A associação jogador -> equipe
não aparece no PDF; aqui é apenas uma escolha de demonstração.
"""
from app import create_app

TEAMS = [
    ("Tigres FC", "João Pessoa"),
    ("Leões do Norte", "Recife"),
    ("Águias FC", "Natal"),
    ("Lobos United", "Fortaleza"),
]
PLAYERS = [  # nome, posição, id da equipe (demonstração)
    ("Carlos Silva", "Atacante", 1),
    ("João Pedro", "Goleiro", 2),
    ("Marcos Lima", "Zagueiro", 3),
    ("Felipe Souza", "Meio Campo", 4),
]
MATCHES = [  # data, gols casa, gols visitante, casa, visitante (conforme o PDF)
    ("2026-05-12", 2, 1, 1, 2),
    ("2026-05-15", 0, 0, 3, 4),
    ("2026-05-20", 3, 2, 1, 3),
]

if __name__ == "__main__":
    app = create_app()
    with app.test_client() as c:
        if c.get("/listaequipes").json:
            print("Banco já possui dados; nada foi inserido.")
        else:
            for nome, cidade in TEAMS:
                c.post("/cadastraequipe", json={"nomeEquipe": nome, "cidadeEquipe": cidade})
            for nome, pos, eq in PLAYERS:
                c.post("/cadastrajogador", json={
                    "nomeJogador": nome, "posicaoJogador": pos, "idEquipeJogador": eq})
            for d, gc, gv, c1, c2 in MATCHES:
                c.post("/cadastrapartida", json={
                    "dataPartida": d, "placarEquipeCasa": gc, "placarEquipeVisitante": gv,
                    "idEquipeCasa": c1, "idEquipeVisitante": c2})
            print("Dados de exemplo inseridos.")
