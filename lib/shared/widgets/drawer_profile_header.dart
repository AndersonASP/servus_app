import 'package:flutter/material.dart';

class DrawerProfileHeader extends StatelessWidget {
  final String nome;
  final String email;
  final String picture;          // URL (pode ser vazio)
  final VoidCallback onTapPerfil;
  final bool exibirTrocaModo;    // exibe chip com modo atual, se true
  final String modoAtual;

  const DrawerProfileHeader({
    super.key,
    required this.nome,
    required this.email,
    required this.picture,
    required this.onTapPerfil,
    this.exibirTrocaModo = false,
    required this.modoAtual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTapPerfil,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(profileImgUrl: picture, nome: nome, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (exibirTrocaModo) ...[
                          const SizedBox(height: 6),
                          _ModoChip(texto: modoAtual),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? profileImgUrl;
  final String nome;
  final double size; // diâmetro do avatar

  const _Avatar({
    required this.profileImgUrl,
    required this.nome,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _iniciais(nome);
    final radius = size / 2;
    final scheme = Theme.of(context).colorScheme;

    final hasUrl = profileImgUrl != null && profileImgUrl!.isNotEmpty;

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: scheme.primary, // ✅ fundo quando mostrar iniciais/erro
        child: hasUrl
            ? Image.network(
                profileImgUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackInitials(
                  initials: initials,
                  fontSize: radius * 0.7,
                ),
              )
            : _FallbackInitials(
                initials: initials,
                fontSize: radius * 0.7,
              ),
      ),
    );
  }

  String _iniciais(String nome) {
    if (nome.trim().isEmpty) return '';
    final ignora = {'de','da','do','das','dos','e','di','du'};
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    final uteis = <String>[];
    for (final p in partes) {
      final lower = p.toLowerCase();
      if (uteis.isEmpty || !ignora.contains(lower)) {
        uteis.add(p);
      }
      if (uteis.length == 2) break;
    }

    if (uteis.length == 1) return uteis.first[0].toUpperCase();
    return (uteis[0][0] + uteis[1][0]).toUpperCase();
  }
}

class _FallbackInitials extends StatelessWidget {
  final String initials;
  final double fontSize;

  const _FallbackInitials({
    required this.initials,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          color: scheme.onPrimary, // ✅ contraste correto com fundo primary
        ),
      ),
    );
  }
}

class _ModoChip extends StatelessWidget {
  final String texto;
  const _ModoChip({required this.texto});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}