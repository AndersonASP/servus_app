import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servus_app/core/models/ministerio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class ConvidarMembrosCard extends StatelessWidget {
  final Ministerio ministerio;
  final VoidCallback onGerarNovoCodigo;
  final VoidCallback onFecharPortas;

  const ConvidarMembrosCard({
    super.key,
    required this.ministerio,
    required this.onGerarNovoCodigo,
    required this.onFecharPortas,
  });

  void _compartilharCodigo(BuildContext context) {
    final mensagem =
        "Olá! Entre no ministério *${ministerio.nome}* usando este código: ${ministerio.codigoConvite.isNotEmpty ? ministerio.codigoConvite : 'Não disponível'}";
    Share.share(mensagem, subject: 'Convite para o Ministério');
  }

  @override
  Widget build(BuildContext context) {
    final codigo = ministerio.codigoConvite.isNotEmpty
        ? ministerio.codigoConvite
        : 'Não disponível';
    final portas = ministerio.portasAbertas; // segurança

    return Material(
      color: context.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Convide o ministério:",
              style: context.textStyles.bodyLarge
                  ?.copyWith(color: context.colors.onSurface),
            ),
            Text(
              ministerio.nome.isNotEmpty ? ministerio.nome : "Nome não informado",
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.secondary,
              ),
            ),
            const SizedBox(height: 8),

            // Código e botão copiar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Código:",
                      style: context.textStyles.bodyLarge
                          ?.copyWith(color: context.colors.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      codigo,
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    if (codigo != 'Não disponível') {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Código copiado!'),
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.only(bottom: 80, left: 16, right: 16),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botão: Gerar novo código
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onGerarNovoCodigo,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text("Gerar novo código"),
                  ],
                ),
              ),
            ),

            Divider(
              height: 16,
              thickness: 0.6,
              color: context.colors.onSurface.withOpacity(0.1),
            ),

            // Botão: Convidar Membro
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _compartilharCodigo(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text("Convidar Membro"),
                  ],
                ),
              ),
            ),

            // Status das portas
            // const SizedBox(height: 12),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       portas
            //           ? "Portas abertas"
            //           : "Portas fechadas",
            //       style: context.textStyles.bodyMedium?.copyWith(
            //         color: portas ? Colors.green : Colors.redAccent,
            //         fontWeight: FontWeight.w600,
            //         fontSize: 12
            //       ),
            //     ),
            //     Switch(
            //       value: portas,
            //       onChanged: (_) => onFecharPortas(),
            //       activeColor: Colors.green,
            //       inactiveThumbColor: Colors.redAccent,
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}