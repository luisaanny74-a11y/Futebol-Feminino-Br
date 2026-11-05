import 'package:flutter_test/flutter_test.dart';
import 'package:futebol_feminino_br/models/models.dart';

void main() {
  test('Equipe aceita id ou idEquipe', () {
    expect(Equipe.fromJson({'id': 3, 'nome': 'Tigres FC', 'cidade': 'João Pessoa'}).id, 3);
    expect(Equipe.fromJson({'idEquipe': '4', 'nome': 'A', 'cidade': 'B'}).id, 4);
    expect(Equipe.fromJson({'nome': 'A', 'cidade': 'B'}).id, isNull);
  });

  test('Partida simples: equipes são ids', () {
    final p = Partida.fromJson({
      'id': 1, 'dataPartida': '2026-05-20', 'placarCasa': 2,
      'placarVisitante': 1, 'equipeCasa': 1, 'equipeVisitante': 2,
    });
    expect(p.idCasa, 1);
    expect(p.nomeCasa, isNull);
    expect(p.totalGols, 3);
  });

  test('Partida detalhada: equipes são nomes', () {
    final p = Partida.fromJson({
      'dataPartida': '2026-05-20', 'equipeCasa': 'Tigres FC',
      'equipeVisitante': 'Leões FC', 'placarCasa': 2, 'placarVisitante': 1,
    });
    expect(p.nomeCasa, 'Tigres FC');
    expect(p.idCasa, isNull);
  });

  test('Datas', () {
    expect(formatDate('2026-05-20'), '20/05/2026');
    expect(toIsoDate(DateTime(2026, 5, 2)), '2026-05-02');
  });
}
