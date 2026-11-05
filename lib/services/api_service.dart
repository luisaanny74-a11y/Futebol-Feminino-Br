import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Cliente HTTP da API do campeonato. Uma função por rota do documento.
class ApiService {
  ApiService(String baseUrl) : _baseUrl = _normalize(baseUrl);

  String _baseUrl;
  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 10);

  String get baseUrl => _baseUrl;
  set baseUrl(String v) => _baseUrl = _normalize(v);

  static String _normalize(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'http://$u';
    return u.replaceAll(RegExp(r'/+$'), '');
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body}) async {
    if (_baseUrl.isEmpty) {
      throw ApiException('Informe a URL da API em Configurações.');
    }
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      dynamic decoded;
      if (res.body.isNotEmpty) {
        try {
          decoded = jsonDecode(utf8.decode(res.bodyBytes));
        } catch (_) {
          decoded = null;
        }
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = decoded is Map
            ? (decoded['erro'] ?? decoded['mensagem'] ?? decoded['message'])
            : null;
        throw ApiException(msg?.toString() ?? 'Erro ${res.statusCode} na API.',
            status: res.statusCode);
      }
      return decoded;
    } on TimeoutException {
      throw ApiException('Tempo esgotado ao falar com $_baseUrl.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Não foi possível conectar em $_baseUrl. Verifique a URL e se o servidor está ligado.');
    }
  }

  List<Map<String, dynamic>> _list(dynamic data) => data is List
      ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];

  // ----------------------------------------------------------- Equipes
  Future<List<Equipe>> listarEquipes() async =>
      _list(await _send('GET', '/listaequipes')).map(Equipe.fromJson).toList();

  Future<void> cadastrarEquipe(String nome, String cidade) => _send(
      'POST', '/cadastraequipe',
      body: {'nomeEquipe': nome, 'cidadeEquipe': cidade});

  Future<void> atualizarEquipe(int id, String nome, String cidade) =>
      _send('PUT', '/atualizaequipe', body: {
        'idEquipe': id,
        'nomeEquipe': nome,
        'cidadeEquipe': cidade,
      });

  Future<void> removerEquipe(int id) =>
      _send('DELETE', '/removeequipe', body: {'idEquipe': id});

  // --------------------------------------------------------- Jogadores
  Future<List<Jogador>> listarJogadores() async =>
      _list(await _send('GET', '/listajogadores')).map(Jogador.fromJson).toList();

  Future<void> cadastrarJogador(String nome, String posicao, int idEquipe) =>
      _send('POST', '/cadastrajogador', body: {
        'nomeJogador': nome,
        'posicaoJogador': posicao,
        'idEquipeJogador': idEquipe,
      });

  Future<void> atualizarJogador(
          int id, String nome, String posicao, int idEquipe) =>
      _send('PUT', '/atualizajogador', body: {
        'idJogador': id,
        'nomeJogador': nome,
        'posicaoJogador': posicao,
        'idEquipeJogador': idEquipe,
      });

  Future<void> removerJogador(int id) =>
      _send('DELETE', '/removejogador', body: {'idJogador': id});

  // ---------------------------------------------------------- Partidas
  /// Combina `/listapartidas` (ids e placares) com `/listapartidasdetalhada`
  /// (nomes das equipes). A junção usa `id` quando existe; senão, a posição.
  Future<List<Partida>> listarPartidas() async {
    final simples =
        _list(await _send('GET', '/listapartidas')).map(Partida.fromJson).toList();
    List<Partida> detalhadas = [];
    try {
      detalhadas = _list(await _send('GET', '/listapartidasdetalhada'))
          .map(Partida.fromJson)
          .toList();
    } on ApiException {
      // Sem a rota detalhada, os nomes são resolvidos pela lista de equipes.
    }
    final byId = {
      for (final d in detalhadas)
        if (d.id != null) d.id!: d
    };
    final result = <Partida>[];
    for (var i = 0; i < simples.length; i++) {
      final s = simples[i];
      Partida? d = s.id != null ? byId[s.id] : null;
      d ??= (i < detalhadas.length && detalhadas.length == simples.length)
          ? detalhadas[i]
          : null;
      result.add(s.withNames(d?.nomeCasa, d?.nomeVisitante));
    }
    return result;
  }

  Map<String, dynamic> _partidaBody({
    int? id,
    required String data,
    required int placarCasa,
    required int placarVisitante,
    required int idCasa,
    required int idVisitante,
  }) =>
      {
        if (id != null) 'idPartida': id,
        'dataPartida': data,
        'placarEquipeCasa': placarCasa,
        'placarEquipeVisitante': placarVisitante,
        'idEquipeCasa': idCasa,
        'idEquipeVisitante': idVisitante,
      };

  Future<void> cadastrarPartida({
    required String data,
    required int placarCasa,
    required int placarVisitante,
    required int idCasa,
    required int idVisitante,
  }) =>
      _send('POST', '/cadastrapartida',
          body: _partidaBody(
              data: data,
              placarCasa: placarCasa,
              placarVisitante: placarVisitante,
              idCasa: idCasa,
              idVisitante: idVisitante));

  Future<void> atualizarPartida({
    required int id,
    required String data,
    required int placarCasa,
    required int placarVisitante,
    required int idCasa,
    required int idVisitante,
  }) =>
      _send('PUT', '/atualizapartida',
          body: _partidaBody(
              id: id,
              data: data,
              placarCasa: placarCasa,
              placarVisitante: placarVisitante,
              idCasa: idCasa,
              idVisitante: idVisitante));

  Future<void> removerPartida(int id) =>
      _send('DELETE', '/removepartida', body: {'idPartida': id});
}
