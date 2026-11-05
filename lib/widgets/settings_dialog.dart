import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'common.dart';

/// Permite trocar a URL base da API (ex.: http://191.252.101.12).
Future<void> showSettingsDialog(BuildContext context) async {
  final state = AppScope.of(context);
  final url = await showDialog<String>(
    context: context,
    builder: (_) => _SettingsDialog(initialUrl: state.api.baseUrl),
  );
  if (url != null) await state.setBaseUrl(url);
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.initialUrl});
  final String initialUrl;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  final _key = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialUrl);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Configurações',
      formKey: _key,
      onSave: () {
        if (_key.currentState!.validate()) {
          Navigator.of(context).pop(_controller.text);
        }
      },
      children: [
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL da API',
            hintText: 'http://IP_DO_SERVIDOR',
            helperText:
                'Emulador Android: http://10.0.2.2:5000 · Navegador/desktop: http://localhost:5000',
            helperMaxLines: 3,
          ),
          validator: requiredField,
        ),
      ],
    );
  }
}
