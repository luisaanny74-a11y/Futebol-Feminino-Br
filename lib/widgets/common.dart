import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';

/// Cartão com cantos chanfrados e contorno neon discreto.
class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.highlight = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: chamfer(border: highlight ? AppColors.lime : AppColors.limeDim),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Faixa de imagem no topo das listas, com degradê para o texto ficar legível.
class BannerHeader extends StatelessWidget {
  const BannerHeader({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.alignment = Alignment.center,
    this.imageLabel,
  });

  final String image;
  final String title;
  final String subtitle;
  final Alignment alignment;
  final String? imageLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: chamfer(radius: 18)),
      child: AspectRatio(
        aspectRatio: MediaQuery.sizeOf(context).width < 600 ? 16 / 7 : 16 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ResponsiveAsset(image, alignment: alignment, semanticLabel: imageLabel),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xE60A0D0B), Color(0x000A0D0B)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de erro com botão para tentar de novo.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry, this.onSettings});
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Não foi possível carregar os dados',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar de novo'),
                  ),
                  if (onSettings != null)
                    TextButton.icon(
                      onPressed: onSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Configurar URL da API'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remover registro?'),
      content: Text('Remover $what? Esta ação não pode ser desfeita.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: chamfer(radius: 10, border: AppColors.danger)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Moldura padrão dos formulários: um [Dialog] simples (sem IntrinsicWidth),
/// com largura máxima de 440 px, rolagem e área para mensagem de erro.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
    this.saving = false,
    this.error,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: chamfer(radius: 18),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final c in children)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 14), child: c),
                      ],
                    ),
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(error!,
                      style: const TextStyle(color: AppColors.danger)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? requiredField(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

/// Tela de listagem genérica usada por Equipes, Jogadores e Partidas:
/// banner + grade responsiva de cartões + botão de adicionar.
class CrudList extends StatelessWidget {
  const CrudList({
    super.key,
    required this.banner,
    required this.itemCount,
    required this.itemBuilder,
    required this.onAdd,
    required this.onRefresh,
    required this.emptyMessage,
    required this.addLabel,
    this.itemExtent = 76,
  });

  final Widget banner;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final String addLabel;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.lime,
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: banner),
              ),
              if (itemCount == 0)
                SliverToBoxAdapter(child: EmptyView(message: emptyMessage))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      mainAxisExtent: itemExtent,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(itemBuilder,
                        childCount: itemCount),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

/// Linha padrão dos cartões: avatar, textos e botões editar/remover.
class RowActions extends StatelessWidget {
  const RowActions({super.key, required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Editar',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.lime),
          ),
          IconButton(
            tooltip: 'Remover',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      );
}

class AvatarIcon extends StatelessWidget {
  const AvatarIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: AppColors.surfaceHigh, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.lime, size: 22),
      );
}
