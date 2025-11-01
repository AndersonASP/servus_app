import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/escalas/models/escala.dart';
import 'package:servus_app/features/leader/escalas/repositories/escalas_repository.dart';

class ModalPublicacao extends StatefulWidget {
  final List<Escala> escalas;
  final EscalasRepository repository;

  const ModalPublicacao({super.key, required this.escalas, required this.repository});

  @override
  State<ModalPublicacao> createState() => _ModalPublicacaoState();
}

class _ModalPublicacaoState extends State<ModalPublicacao> {
  late List<Escala> _escalas;
  bool _publicando = false;

  @override
  void initState() {
    super.initState();
    _escalas = widget.escalas
        .map((e) => e.copyWith(selecionadaParaPublicar: e.selecionadaParaPublicar ?? true))
        .toList();
  }

  int get _totalVoluntariosSelecionados {
    int total = 0;
    for (final e in _escalas.where((x) => x.selecionadaParaPublicar == true)) {
      total += e.funcoes.length; // simplificado: 1 voluntário por função
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Publicar Escalas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Os voluntários serão notificados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _escalas.length,
                  itemBuilder: (context, index) {
                    final e = _escalas[index];
                    return CheckboxListTile(
                      value: e.selecionadaParaPublicar ?? true,
                      onChanged: (v) {
                        setState(() {
                          _escalas[index] = e.copyWith(selecionadaParaPublicar: v ?? true);
                        });
                      },
                      title: Text(e.eventoNome),
                      subtitle: Text(
                        '${e.eventoData.day.toString().padLeft(2, '0')}/${e.eventoData.month.toString().padLeft(2, '0')}/${e.eventoData.year}',
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text('${e.funcoes.length}'),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$_totalVoluntariosSelecionados voluntários serão notificados',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _publicando ? null : _confirmarPublicacao,
                          icon: _publicando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.notifications_active),
                          label: const Text('Confirmar e Notificar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarPublicacao() async {
    setState(() => _publicando = true);
    try {
      final ids = _escalas
          .where((e) => (e.selecionadaParaPublicar ?? true))
          .map((e) => e.id)
          .toList();
      await widget.repository.publicarEscalas(ids);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ids.length} escalas publicadas!')),
      );
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }
}
