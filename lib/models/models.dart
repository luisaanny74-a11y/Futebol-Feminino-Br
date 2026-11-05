int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

String _asString(dynamic v) => v == null ? '' : '$v';

/// Converte "2026-05-20" em "20/05/2026" (sem depender de `intl`).
String formatDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final day = p[2].length > 2 ? p[2].substring(0, 2) : p[2];
  return '$day/${p[1]}/${p[0]}';
}

/// Converte DateTime em "AAAA-MM-DD" (formato exigido pela API).
String toIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Equipe {
  const Equipe({this.id, required this.nome, required this.cidade});

  /// Os PUT/DELETE exigem `idEquipe`. O documento não mostra o id na listagem,
  /// então aceitamos `id`, `idEquipe` ou `id_equipe`.
  final int? id;
  final String nome;
  final String cidade;

  factory Equipe.fromJson(Map<String, dynamic> j) => Equipe(
        id: _asInt(j['id'] ?? j['idEquipe'] ?? j['id_equipe']),
        nome: _asString(j['nome'] ?? j['nomeEquipe']),
        cidade: _asString(j['cidade'] ?? j['cidadeEquipe']),
      );
}

class Jogador {
  const Jogador({
    this.id,
    required this.nome,
    required this.posicao,
    this.idEquipe,
  });

  final int? id;
  final String nome;
  final String posicao;
  final int? idEquipe;

  factory Jogador.fromJson(Map<String, dynamic> j) => Jogador(
        id: _asInt(j['id'] ?? j['idJogador'] ?? j['id_jogador']),
        nome: _asString(j['nome'] ?? j['nomeJogador']),
        posicao: _asString(j['posicao'] ?? j['posicaoJogador']),
        idEquipe: _asInt(j['id_equipe_fk'] ?? j['idEquipe'] ?? j['idEquipeJogador']),
      );
}

class Partida {
  const Partida({
    this.id,
    required this.data,
    required this.placarCasa,
    required this.placarVisitante,
    this.idCasa,
    this.idVisitante,
    this.nomeCasa,
    this.nomeVisitante,
  });

  final int? id;
  final String data; // AAAA-MM-DD
  final int placarCasa;
  final int placarVisitante;
  final int? idCasa;
  final int? idVisitante;
  final String? nomeCasa;
  final String? nomeVisitante;

  /// Funciona para `/listapartidas` (equipeCasa = id) e para
  /// `/listapartidasdetalhada` (equipeCasa = nome).
  factory Partida.fromJson(Map<String, dynamic> j) {
    final casa = j['equipeCasa'];
    final visitante = j['equipeVisitante'];
    final casaId = _asInt(j['idEquipeCasa'] ?? (casa is String ? null : casa));
    final visId =
        _asInt(j['idEquipeVisitante'] ?? (visitante is String ? null : visitante));
    return Partida(
      id: _asInt(j['id'] ?? j['idPartida'] ?? j['id_partida']),
      data: _asString(j['dataPartida']),
      placarCasa: _asInt(j['placarCasa'] ?? j['placarEquipeCasa']) ?? 0,
      placarVisitante:
          _asInt(j['placarVisitante'] ?? j['placarEquipeVisitante']) ?? 0,
      idCasa: casaId,
      idVisitante: visId,
      nomeCasa: casa is String && _asInt(casa) == null ? casa : null,
      nomeVisitante:
          visitante is String && _asInt(visitante) == null ? visitante : null,
    );
  }

  Partida withNames(String? casa, String? visitante) => Partida(
        id: id,
        data: data,
        placarCasa: placarCasa,
        placarVisitante: placarVisitante,
        idCasa: idCasa,
        idVisitante: idVisitante,
        nomeCasa: casa ?? nomeCasa,
        nomeVisitante: visitante ?? nomeVisitante,
      );

  int get totalGols => placarCasa + placarVisitante;
}
