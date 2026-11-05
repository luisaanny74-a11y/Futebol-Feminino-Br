import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class PartidasScreen extends StatelessWidget {
  const PartidasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return CrudList(
      banner: const BannerHeader(
        image: 'banner_partidas',
        title: 'Partidas',
        subtitle: 'Resultados e calendário',
        imageLabel: 'Estádio visto de cima',
      ),
      itemExtent: 92,
      itemCount: state.partidas.length,
      emptyMessage: 'Nenhuma partida ainda. Toque em "Nova partida" para começar.',
      addLabel: 'Nova partida',
      onRefresh: state.refresh,
      onAdd: () => showPartidaForm(context),
      itemBuilder: (context, i) {
        final p = state.partidas[i];
        return NeonCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const AvatarIcon(Icons.sports_soccer_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${state.nomeCasa(p)} x ${state.nomeVisitante(p)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(formatDate(p.data),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                    color: AppColors.lime,
                    shape: chamfer(radius: 8, border: AppColors.lime)),
                child: Text('${p.placarCasa} x ${p.placarVisitante}',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800)),
              ),
              RowActions(
                onEdit: () => showPartidaForm(context, edit: p),
                onDelete: () async {
                  if (p.id == null) {
                    showMessage(context, 'A API não retornou o id desta partida.');
                    return;
                  }
                  if (!await confirmDelete(context, 'esta partida')) return;
                  final err = await state.run(() => state.api.removerPartida(p.id!));
                  if (context.mounted) showMessage(context, err ?? 'Partida removida.');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showPartidaForm(BuildContext context, {Partida? edit}) async {
  final state = AppScope.of(context);
  if (state.equipes.where((e) => e.id != null).length < 2) {
    showMessage(context, 'Cadastre pelo menos duas equipes antes de criar partidas.');
    return;
  }
  if (edit != null && edit.id == null) {
    showMessage(context, 'A API não retornou o id desta partida.');
    return;
  }
  final msg = await showDialog<String>(
    context: context,
    builder: (_) => _PartidaDialog(state: state, edit: edit),
  );
  if (msg != null && context.mounted) showMessage(context, msg);
}

class _PartidaDialog extends StatefulWidget {
  const _PartidaDialog({required this.state, this.edit});
  final AppState state;
  final Partida? edit;

  @override
  State<_PartidaDialog> createState() => _PartidaDialogState();
}

class _PartidaDialogState extends State<_PartidaDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _golsCasa;
  late final TextEditingController _golsVis;
  late final TextEditingController _dataCtrl;
  late final List<Equipe> _equipes;
  DateTime? _data;
  int? _casa;
  int? _visitante;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    _golsCasa = TextEditingController(text: edit == null ? '' : '${edit.placarCasa}');
    _golsVis =
        TextEditingController(text: edit == null ? '' : '${edit.placarVisitante}');
    _data = edit == null ? null : DateTime.tryParse(edit.data);
    _dataCtrl = TextEditingController(
        text: _data == null ? '' : formatDate(toIsoDate(_data!)));
    _equipes = widget.state.equipes.where((e) => e.id != null).toList();
    _casa = _equipes.any((e) => e.id == edit?.idCasa) ? edit!.idCasa : null;
    _visitante =
        _equipes.any((e) => e.id == edit?.idVisitante) ? edit!.idVisitante : null;
  }

  @override
  void dispose() {
    _golsCasa.dispose();
    _golsVis.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  String? _validaGols(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < 0) ? 'Informe um número inteiro ≥ 0' : null;
  }

  List<DropdownMenuItem<int>> _items() => [
        for (final e in _equipes)
          DropdownMenuItem(
              value: e.id, child: Text(e.nome, overflow: TextOverflow.ellipsis))
      ];

  Future<void> _escolherData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _data = picked;
        _dataCtrl.text = formatDate(toIsoDate(picked));
      });
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final edit = widget.edit;
    final api = widget.state.api;
    final data = toIsoDate(_data!);
    final gc = int.parse(_golsCasa.text);
    final gv = int.parse(_golsVis.text);
    final casa = _casa!;
    final visitante = _visitante!;
    final err = await widget.state.run(() => edit == null
        ? api.cadastrarPartida(
            data: data,
            placarCasa: gc,
            placarVisitante: gv,
            idCasa: casa,
            idVisitante: visitante)
        : api.atualizarPartida(
            id: edit.id!,
            data: data,
            placarCasa: gc,
            placarVisitante: gv,
            idCasa: casa,
            idVisitante: visitante));
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context)
          .pop(edit == null ? 'Partida cadastrada.' : 'Partida atualizada.');
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
      title: widget.edit == null ? 'Nova partida' : 'Editar partida',
      formKey: _key,
      saving: _saving,
      error: _error,
      onSave: _save,
      children: [
        TextFormField(
          controller: _dataCtrl,
          readOnly: true,
          decoration: const InputDecoration(
              labelText: 'Data', suffixIcon: Icon(Icons.calendar_month)),
          validator: (_) => _data == null ? 'Escolha a data' : null,
          onTap: _escolherData,
        ),
        DropdownButtonFormField<int>(
          initialValue: _casa,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Equipe da casa'),
          items: _items(),
          onChanged: (v) => _casa = v,
          validator: (v) => v == null ? 'Escolha a equipe' : null,
        ),
        DropdownButtonFormField<int>(
          initialValue: _visitante,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Equipe visitante'),
          items: _items(),
          onChanged: (v) => _visitante = v,
          validator: (v) {
            if (v == null) return 'Escolha a equipe';
            if (v == _casa) return 'Deve ser diferente da equipe da casa';
            return null;
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _golsCasa,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gols casa'),
                validator: _validaGols,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _golsVis,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gols visitante'),
                validator: _validaGols,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
