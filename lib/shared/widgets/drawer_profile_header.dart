import 'package:flutter/material.dart';

class DrawerProfileHeader extends StatelessWidget {
  final String nome;
  final String email;
  final String picture;
  final VoidCallback onTapPerfil;
  final bool exibirTrocaModo;
  final String modoAtual;

  const DrawerProfileHeader({
    super.key,
    required this.nome,
    required this.email,
    required this.picture,
    required this.onTapPerfil,
    this.exibirTrocaModo = false,
    this.modoAtual = 'Voluntário',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTapPerfil,
        child: Row(
          children: [
            _Avatar(profileImgUrl: picture, nome: nome),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
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

  const _Avatar({required this.profileImgUrl, required this.nome});

  @override
  Widget build(BuildContext context) {
    final initials = _iniciais(nome);

    // Se não tem URL, mostra as iniciais
    if (profileImgUrl == null || profileImgUrl!.isEmpty) {
      return CircleAvatar(
        radius: 28,
        child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    // Com URL: usa NetworkImage e trata erro de carregamento
    return CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundImage: NetworkImage(profileImgUrl!),
      onForegroundImageError: (_, __) {
        // Se falhar o carregamento, o CircleAvatar cai pro child
      },
      child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}