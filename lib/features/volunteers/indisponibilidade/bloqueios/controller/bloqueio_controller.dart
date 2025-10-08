import 'package:flutter/material.dart';

class BloqueioController extends ChangeNotifier {
  final TextEditingController motivoController = TextEditingController();
  final Map<String, bool> ministeriosSelecionados = {};
  bool mostrarMensagemInfo = true;

  bool modoEdicao = false;
  String? idBloqueio;
  bool erroMinisterios = false;
  bool _isLoading = false;

  /// Estado de loading para operações de salvamento
  bool get isLoading => _isLoading;

  /// Define o estado de loading
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void inicializar({
    String? motivoInicial,
    List<String>? ministeriosIniciais,
    List<Map<String, dynamic>> todosMinisterios = const [],
  }) {
    motivoController.text = motivoInicial ?? '';

    // Preenche o mapa com todos os ministérios possíveis, marcando como selecionado apenas os que vieram como parâmetro
    ministeriosSelecionados.clear();
    
    for (var m in todosMinisterios) {
      final ministryName = m['name'] ?? 'Ministério';
      ministeriosSelecionados[ministryName] = ministeriosIniciais?.contains(ministryName) ?? false;
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
    
    final resultado = motivoValido && !erroMinisterios;
    
    notifyListeners();
    return resultado;
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
