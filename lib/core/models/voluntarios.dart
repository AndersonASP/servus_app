class Voluntario {
  final String nome;
  final String funcao;
  bool ativo;

  Voluntario({
    required this.nome,
    required this.funcao,
    this.ativo = true,
  });
}
