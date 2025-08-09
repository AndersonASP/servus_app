import 'package:flutter/material.dart';

class BloqueioController extends ChangeNotifier {
  final TextEditingController motivoController = TextEditingController();
  final Map<String, bool> ministeriosSelecionados = {};
  bool mostrarMensagemInfo = true;

  bool modoEdicao = false;
  String? idBloqueio;
  bool erroMinisterios = false;

  void inicializar({
    String? motivoInicial,
    List<String>? ministeriosIniciais,
    List<String> todosMinisterios = const [],
  }) {
    motivoController.text = motivoInicial ?? '';

    // Preenche o mapa com todos os ministérios possíveis, marcando como selecionado apenas os que vieram como parâmetro
    ministeriosSelecionados.clear();
    for (var m in todosMinisterios) {
      ministeriosSelecionados[m] = ministeriosIniciais?.contains(m) ?? false;
    }

    mostrarMensagemInfo = true;
    erroMinisterios = false;
    notifyListeners();
  }

  void toggleMinisterio(String ministerio) {
    if (ministeriosSelecionados.containsKey(ministerio)) {
      ministeriosSelecionados[ministerio] =
          !(ministeriosSelecionados[ministerio] ?? false);
    } else {
      ministeriosSelecionados[ministerio] = true;
    }
    notifyListeners();
  }

  void atualizarMinisterio(String ministerio, bool selecionado) {
    ministeriosSelecionados[ministerio] = selecionado;
    notifyListeners();
  }

  bool validar() {
    erroMinisterios = !ministeriosSelecionados.containsValue(true);
    bool isValid = motivoController.text.trim().isNotEmpty && !erroMinisterios;
    notifyListeners();
    return isValid;
  }

  bool validarFormulario(GlobalKey<FormState> formKey) {
    final form = formKey.currentState;
    erroMinisterios = !ministeriosSelecionados.containsValue(true);
    final motivoValido = form?.validate() ?? false;
    notifyListeners();
    return motivoValido && !erroMinisterios;
  }

  void limparCampos() {
    motivoController.clear();
    ministeriosSelecionados.clear();
    modoEdicao = false;
    idBloqueio = null;
    notifyListeners();
  }

  @override
  void dispose() {
    motivoController.dispose();
    super.dispose();
  }

  String? validarMotivo(String? value) {
    if (value == null || value.trim().isEmpty) {
      mostrarMensagemInfo = false;
      notifyListeners();
      return 'Campo obrigatório';
    }
    mostrarMensagemInfo = true;
    notifyListeners();
    return null;
  }
}
