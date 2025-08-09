import 'package:servus_app/core/enums/ministry_module.dart';

class Ministerio {
  final String id;
  final String nome;
  final String? _codigoConvite;
  final bool portasAbertas;
  final List<MinistryModule> modulosAtivos;

  Ministerio({
    required this.id,
    required this.nome,
    String? codigoConvite,
    bool? portasAbertas,
    required this.modulosAtivos,
  })  : _codigoConvite = codigoConvite,
        portasAbertas = portasAbertas ?? true; // garante valor padrão

  /// Getter seguro para o código
  String get codigoConvite => _codigoConvite ?? 'Código não disponível';

  bool possuiModulo(MinistryModule modulo) {
    return modulosAtivos.contains(modulo);
  }
}