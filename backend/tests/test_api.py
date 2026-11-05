import pytest

from app import create_app


@pytest.fixture()
def client(tmp_path):
    app = create_app(str(tmp_path / "teste.db"))
    return app.test_client()


def _equipe(client, nome="Tigres FC", cidade="João Pessoa"):
    return client.post("/cadastraequipe", json={"nomeEquipe": nome, "cidadeEquipe": cidade})


def test_crud_equipe(client):
    r = _equipe(client)
    assert r.status_code == 201
    id_ = r.json["id"]

    lista = client.get("/listaequipes").json
    assert lista == [{"id": id_, "nome": "Tigres FC", "cidade": "João Pessoa"}]

    r = client.put("/atualizaequipe", json={
        "idEquipe": id_, "nomeEquipe": "Tigres Atualizado", "cidadeEquipe": "Recife"})
    assert r.status_code == 200
    assert client.get("/listaequipes").json[0]["cidade"] == "Recife"

    assert client.delete("/removeequipe", json={"idEquipe": id_}).status_code == 200
    assert client.get("/listaequipes").json == []
    assert client.delete("/removeequipe", json={"idEquipe": id_}).status_code == 404


def test_crud_jogador(client):
    eq = _equipe(client).json["id"]
    r = client.post("/cadastrajogador", json={
        "nomeJogador": "Carlos Silva", "posicaoJogador": "Atacante", "idEquipeJogador": eq})
    assert r.status_code == 201
    jid = r.json["id"]
    assert client.get("/listajogadores").json[0]["id_equipe_fk"] == eq

    r = client.put("/atualizajogador", json={
        "idJogador": jid, "nomeJogador": "Carlos Silva",
        "posicaoJogador": "Meio Campo", "idEquipeJogador": eq})
    assert r.status_code == 200
    assert client.get("/listajogadores").json[0]["posicao"] == "Meio Campo"
    assert client.delete("/removejogador", json={"idJogador": jid}).status_code == 200


def test_jogador_com_equipe_inexistente(client):
    r = client.post("/cadastrajogador", json={
        "nomeJogador": "X", "posicaoJogador": "Goleiro", "idEquipeJogador": 99})
    assert r.status_code == 400


def test_crud_partida_e_detalhada(client):
    a = _equipe(client, "Tigres FC", "João Pessoa").json["id"]
    b = _equipe(client, "Leões do Norte", "Recife").json["id"]
    payload = {"dataPartida": "2026-05-20", "placarEquipeCasa": 2,
               "placarEquipeVisitante": 1, "idEquipeCasa": a, "idEquipeVisitante": b}
    r = client.post("/cadastrapartida", json=payload)
    assert r.status_code == 201
    pid = r.json["id"]

    simples = client.get("/listapartidas").json[0]
    assert simples["equipeCasa"] == a and simples["placarCasa"] == 2
    det = client.get("/listapartidasdetalhada").json[0]
    assert det["equipeCasa"] == "Tigres FC" and det["equipeVisitante"] == "Leões do Norte"

    payload.update(idPartida=pid, placarEquipeCasa=3)
    assert client.put("/atualizapartida", json=payload).status_code == 200
    assert client.get("/listapartidas").json[0]["placarCasa"] == 3
    assert client.delete("/removepartida", json={"idPartida": pid}).status_code == 200


def test_validacoes_partida(client):
    a = _equipe(client).json["id"]
    base = {"dataPartida": "2026-05-20", "placarEquipeCasa": 1,
            "placarEquipeVisitante": 0, "idEquipeCasa": a, "idEquipeVisitante": a}
    assert client.post("/cadastrapartida", json=base).status_code == 400  # mesma equipe
    base.update(idEquipeVisitante=a + 1)
    assert client.post("/cadastrapartida", json=base).status_code == 400  # equipe inexistente
    base.update(dataPartida="20/05/2026")
    assert client.post("/cadastrapartida", json=base).status_code == 400  # data inválida


def test_nao_remove_equipe_em_uso(client):
    a = _equipe(client).json["id"]
    client.post("/cadastrajogador", json={
        "nomeJogador": "X", "posicaoJogador": "Goleiro", "idEquipeJogador": a})
    assert client.delete("/removeequipe", json={"idEquipe": a}).status_code == 409


def test_corpo_invalido(client):
    assert client.post("/cadastraequipe", data="nao e json").status_code == 400
    assert client.post("/cadastraequipe", json={"nomeEquipe": ""}).status_code == 400
