class SolicitacaoTroca {
  final String voluntario;
  final String substituto;
  final String escala;
  final String motivo;
  String status; // 'pendente', 'aceito', 'recusado'

  SolicitacaoTroca({
    required this.voluntario,
    required this.substituto,
    required this.escala,
    required this.motivo,
    this.status = 'pendente',
  });
}