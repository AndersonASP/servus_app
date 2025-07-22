import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'perfil_controller.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PerfilController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 24),
              // Foto de perfil
              GestureDetector(
                onTap: () => controller.selecionarImagemDaGaleria(),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: controller.imagemPerfil != null
                      ? FileImage(controller.imagemPerfil!)
                      : const NetworkImage('https://picsum.photos/200')
                          as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(4),
                      child:
                          const Icon(Icons.edit, size: 16, color: Colors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nome
              Text(
                controller.nome,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: context.colors.primary,
                ),
              ),

              // Email
              // Text(
              //   controller.email,
              //   style: theme.textTheme.bodyLarge?.copyWith(
              //     color: context.colors.onSecondary,
              //     fontSize: 12,
              //   ),
              // ),

              const SizedBox(height: 4),

              // Igreja e campus
              Text(
                controller.igreja,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: context.colors.onSecondary, fontSize: 14),
              ),

              const SizedBox(height: 20),

              // Card de vezes que serviu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4058DB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Uau! Você já serviu '),
                      TextSpan(
                        text: '${controller.vezesServiu}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const TextSpan(text: ' vezes este ano 🏆'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de opções
              ...controller.menuItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEEFF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        collapsedBackgroundColor: const Color(0xFFEBEEFF),
                        backgroundColor: const Color(0xFFEBEEFF),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          item.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSecondary,
                            fontSize: 15,
                          ),
                        ),
                        children: [
                          if (item.title == 'Informações pessoais') ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nome: ${controller.nome}'),
                                  Text('Email: ${controller.email}'),
                                  Text('Igreja: ${controller.igreja}'),
                                  // Outros campos...
                                ],
                              ),
                            ),
                          ] else if (item.title == 'Suas funções') ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    // children: () => {}
                                    // .map((f) => Chip(label: Text(f)))
                                    // .toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    // controller: controller.novaFuncaoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nova função',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => {},
                                    child: const Text('Adicionar função'),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Informações detalhadas...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.onSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ]
                        ],
                        onExpansionChanged: (expanded) {
                          if (expanded) item.onTap?.call();
                        },
                      ),
                    ),
                  )),

              Align(
                alignment: Alignment.center,
                child: Text(
                  'Versão 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
