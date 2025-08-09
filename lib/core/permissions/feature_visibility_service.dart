import 'package:servus_app/core/enums/ministry_module.dart';
import 'package:servus_app/core/models/ministerio.dart';

class FeatureVisibilityService {
  static bool isDisponivelParaUsuario({
    required MinistryModule modulo,
    required List<Ministerio> ministeriosDoUsuario,
  }) {
    return ministeriosDoUsuario.any((m) => m.possuiModulo(modulo));
  }
}