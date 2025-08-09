import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class Aniversariante {
  final String nome;
  final String fotoUrl;
  final int dia;

  Aniversariante({
    required this.nome,
    required this.fotoUrl,
    required this.dia,
  });
}

class AniversariantesWidget extends StatelessWidget {
  final List<Aniversariante> aniversariantes;
  final bool isLoading;

  const AniversariantesWidget({
    super.key,
    required this.aniversariantes,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎁 Aniversariantes do mês',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ LOADING STATE
          if (isLoading)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 50,
                          height: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 40,
                          height: 8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            )

          // ✅ LISTA REAL
          else
            SizedBox(
              height: 100,
              child: aniversariantes.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum aniversariante encontrado',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: aniversariantes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = aniversariantes[index];
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(item.fotoUrl),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.nome,
                              style: context.textStyles.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                            Text(
                              'dia ${item.dia}',
                              style: context.textStyles.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}