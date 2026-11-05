import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// URL padrão por plataforma (pode ser trocada em Configurações).
/// - Web/desktop/iOS simulator: localhost
/// - Emulador Android: 10.0.2.2 aponta para o computador host
String defaultApiUrl() {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5000';
  }
  return 'http://localhost:5000';
}

class AppState extends ChangeNotifier {
  AppState(this.api, this._prefs);

  static const _prefKey = 'api_url';

  final ApiService api;
  final SharedPreferences _prefs;

  List<Equipe> equipes = [];
  List<Jogador> jogadores = [];
  List<Partida> partidas = [];

  bool loading = false;
  bool loaded = false;
  String? error;

  static Future<AppState> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppState(ApiService(prefs.getString(_prefKey) ?? defaultApiUrl()), prefs);
  }

  int get totalGols => partidas.fold(0, (sum, p) => sum + p.totalGols);

  String nomeEquipe(int? id) {
    for (final e in equipes) {
      if (e.id == id) return e.nome;
    }
    return id == null ? '—' : 'Equipe $id';
  }

  String nomeCasa(Partida p) => p.nomeCasa ?? nomeEquipe(p.idCasa);
  String nomeVisitante(Partida p) => p.nomeVisitante ?? nomeEquipe(p.idVisitante);

  Future<void> setBaseUrl(String url) async {
    api.baseUrl = url;
    await _prefs.setString(_prefKey, api.baseUrl);
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.listarEquipes(),
        api.listarJogadores(),
        api.listarPartidas(),
      ]);
      equipes = results[0] as List<Equipe>;
      jogadores = results[1] as List<Jogador>;
      partidas = results[2] as List<Partida>;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Erro inesperado: $e';
    }
    loading = false;
    loaded = true;
    notifyListeners();
  }

  /// Executa uma operação de escrita e recarrega os dados.
  /// Retorna `null` em caso de sucesso, ou a mensagem de erro.
  Future<String?> run(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }
}

/// Dá acesso ao [AppState] para qualquer widget (sem pacotes extras).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
