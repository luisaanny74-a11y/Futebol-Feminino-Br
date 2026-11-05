import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class EquipesScreen extends StatelessWidget {
  const EquipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return CrudList(
      banner: const BannerHeader(
        image: 'banner_equipes',
        title: 'Equipes',
        subtitle: 'Cadastre e edite os times do campeonato',
        alignment: Alignment(0, 0.4),
        imageLabel: 'Ilustração de uma chuteira vermelha e uma bola',
      ),
      itemCount: state.equipes.length,
      emptyMessage: 'Nenhuma equipe ainda. Toque em "Nova equipe" para começar.',
      addLabel: 'Nova equipe',
      onRefresh: state.refresh,
      onAdd: () => showEquipeForm(context),
      itemBuilder: (context, i) {
        final e = state.equipes[i];
        return NeonCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const AvatarIcon(Icons.groups_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.nome,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(e.cidade,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              RowActions(
                onEdit: () => showEquipeForm(context, edit: e),
                onDelete: () async {
                  if (e.id == null) {
                    showMessage(context, 'A API não retornou o id desta equipe.');
                    return;
                  }
                  if (!await confirmDelete(context, 'a equipe "${e.nome}"')) return;
                  final err = await state.run(() => state.api.removerEquipe(e.id!));
                  if (context.mounted) {
                    showMessage(context, err ?? 'Equipe removida.');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showEquipeForm(BuildContext context, {Equipe? edit}) async {
  final state = AppScope.of(context);
  if (edit != null && edit.id == null) {
    showMessage(context, 'A API não retornou o id desta equipe.');
    return;
  }
  final msg = await showDialog<String>(
    context: context,
    builder: (_) => _EquipeDialog(state: state, edit: edit),
  );
  if (msg != null && context.mounted) showMessage(context, msg);
}

class _EquipeDialog extends StatefulWidget {
  const _EquipeDialog({required this.state, this.edit});
  final AppState state;
  final Equipe? edit;

  @override
  State<_EquipeDialog> createState() => _EquipeDialogState();
}

class _EquipeDialogState extends State<_EquipeDialog> {
  final _key = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.edit?.nome ?? '');
  late final _cidade = TextEditingController(text: widget.edit?.cidade ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nome.dispose();
    _cidade.dispose();
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
    final cidade = _cidade.text.trim();
    final err = await widget.state.run(() => edit == null
        ? api.cadastrarEquipe(nome, cidade)
        : api.atualizarEquipe(edit.id!, nome, cidade));
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context)
          .pop(edit == null ? 'Equipe cadastrada.' : 'Equipe atualizada.');
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
      title: widget.edit == null ? 'Nova equipe' : 'Editar equipe',
      formKey: _key,
      saving: _saving,
      error: _error,
      onSave: _save,
      children: [
        TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome da equipe'),
            validator: requiredField),
        TextFormField(
            controller: _cidade,
            decoration: const InputDecoration(labelText: 'Cidade'),
            validator: requiredField),
      ],
    );
  }
}
