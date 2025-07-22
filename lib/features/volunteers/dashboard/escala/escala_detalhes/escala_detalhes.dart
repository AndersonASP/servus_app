import 'package:flutter/material.dart';

class EscalaDetalheScreen extends StatelessWidget {
  const EscalaDetalheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4058DB);
    final statusColor = Colors.red.shade700;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escala'),
          actions: const [Icon(Icons.more_vert)],
          centerTitle: true,
          leading: const Icon(Icons.close),
        ),
        body: Column(
          children: [
            // Cabeçalho fixo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ghhhh',
                      style: TextStyle(
                        color: primary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    '22:11 | Quinta-feira | 24 de julho de 2025',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Text('daqui a 2 dias',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      indicatorColor: primary,
                      labelColor: primary,
                      unselectedLabelColor: Colors.black54,
                      tabs: const [
                        Tab(icon: Icon(Icons.info_outline), text: 'Detalhes'),
                        Tab(icon: Icon(Icons.music_note), text: 'Músicas'),
                        Tab(icon: Icon(Icons.group), text: 'Participantes'),
                        Tab(icon: Icon(Icons.schedule), text: 'Roteiro'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão de status
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.notification_important_rounded),
                      label: const Text('Confirmação pendente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // TabBarView conteúdo
            Expanded(
              child: TabBarView(
                children: [
                  _buildDetalhesTab(context),
                  _buildMusicasTab(),
                  _buildParticipantesTab(),
                  _buildRoteiroTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Observações:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('vbbhh', style: TextStyle(color: Colors.black87)),
        SizedBox(height: 24),
        Divider(),
        ListTile(
          leading: Icon(Icons.edit_note),
          title: Text('Status'),
          subtitle: Text('Rascunho'),
        ),
        ListTile(
          leading: Icon(Icons.thumb_up),
          title: Text('Confirmados'),
          subtitle: Text('1 de 2'),
        ),
        ListTile(
          leading: Icon(Icons.history),
          title: Text('Histórico de alterações'),
          trailing: Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildMusicasTab() {
    return const Center(
      child: Text('Nenhuma música adicionada.'),
    );
  }

  Widget _buildParticipantesTab() {
    return const Center(
      child: Text('Participantes: 1 de 2 confirmados.'),
    );
  }

  Widget _buildRoteiroTab() {
    return const Center(
      child: Text('Nenhum roteiro disponível.'),
    );
  }
}