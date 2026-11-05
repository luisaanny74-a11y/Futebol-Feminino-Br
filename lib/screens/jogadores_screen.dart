import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Posições que aparecem nos exemplos do exercício.
const _posicoesPadrao = ['Goleiro', 'Zagueiro', 'Meio Campo', 'Atacante'];

class JogadoresScreen extends StatelessWidget {
  const JogadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return CrudList(
      banner: const BannerHeader(
        image: 'banner_jogadoras',
        title: 'Jogadoras',
        subtitle: 'Elenco de cada equipe',
        alignment: Alignment(0, -0.1),
        imageLabel: 'Pintura de uma jogadora chutando a bola',
      ),
      itemCount: state.jogadores.length,
      emptyMessage: 'Nenhuma jogadora ainda. Toque em "Nova jogadora" para começar.',
      addLabel: 'Nova jogadora',
      onRefresh: state.refresh,
      onAdd: () => showJogadorForm(context),
      itemBuilder: (context, i) {
        final j = state.jogadores[i];
        return NeonCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const AvatarIcon(Icons.person_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.nome,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${j.posicao} · ${state.nomeEquipe(j.idEquipe)}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              RowActions(
                onEdit: () => showJogadorForm(context, edit: j),
                onDelete: () async {
                  if (j.id == null) {
                    showMessage(context, 'A API não retornou o id desta jogadora.');
                    return;
                  }
                  if (!await confirmDelete(context, '"${j.nome}"')) return;
                  final err = await state.run(() => state.api.removerJogador(j.id!));
                  if (context.mounted) showMessage(context, err ?? 'Jogadora removida.');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showJogadorForm(BuildContext context, {Jogador? edit}) async {
  final state = AppScope.of(context);
  if (state.equipes.where((e) => e.id != null).isEmpty) {
    showMessage(context, 'Cadastre uma equipe antes de adicionar jogadoras.');
    return;
  }
  if (edit != null && edit.id == null) {
    showMessage(context, 'A API não retornou o id desta jogadora.');
    return;
  }
  final msg = await showDialog<String>(
    context: context,
    builder: (_) => _JogadorDialog(state: state, edit: edit),
  );
  if (msg != null && context.mounted) showMessage(context, msg);
}

class _JogadorDialog extends StatefulWidget {
  const _JogadorDialog({required this.state, this.edit});
  final AppState state;
  final Jogador? edit;

  @override
  State<_JogadorDialog> createState() => _JogadorDialogState();
}

class _JogadorDialogState extends State<_JogadorDialog> {
  final _key = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.edit?.nome ?? '');
  late final List<String> _posicoes;
  late final List<Equipe> _equipes;
  String? _posicao;
  int? _idEquipe;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    _posicoes = [..._posicoesPadrao];
    if (edit != null &&
        edit.posicao.isNotEmpty &&
        !_posicoes.contains(edit.posicao)) {
      _posicoes.add(edit.posicao);
    }
    _posicao = (edit != null && edit.posicao.isNotEmpty) ? edit.posicao : null;
    _equipes = widget.state.equipes.where((e) => e.id != null).toList();
    _idEquipe = _equipes.any((e) => e.id == edit?.idEquipe) ? edit!.idEquipe : null;
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final edit = widget.edit;
    final api = widget.state.api;
    final nome = _nome.text.trim();
    final posicao = _posicao!;
    final idEquipe = _idEquipe!;
    final err = await widget.state.run(() => edit == null
        ? api.cadastrarJogador(nome, posicao, idEquipe)
        : api.atualizarJogador(edit.id!, nome, posicao, idEquipe));
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context)
          .pop(edit == null ? 'Jogadora cadastrada.' : 'Jogadora atualizada.');
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.edit == null ? 'Nova jogadora' : 'Editar jogadora',
      formKey: _key,
      saving: _saving,
      error: _error,
      onSave: _save,
      children: [
        TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: requiredField),
        DropdownButtonFormField<String>(
          initialValue: _posicao,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Posição'),
          items: [
            for (final p in _posicoes) DropdownMenuItem(value: p, child: Text(p))
          ],
          onChanged: (v) => _posicao = v,
          validator: (v) => v == null ? 'Escolha a posição' : null,
        ),
        DropdownButtonFormField<int>(
          initialValue: _idEquipe,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Equipe'),
          items: [
            for (final e in _equipes)
              DropdownMenuItem(
                  value: e.id, child: Text(e.nome, overflow: TextOverflow.ellipsis))
          ],
          onChanged: (v) => _idEquipe = v,
          validator: (v) => v == null ? 'Escolha a equipe' : null,
        ),
      ],
    );
  }
}
