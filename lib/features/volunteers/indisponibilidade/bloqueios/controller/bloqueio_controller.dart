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
    List<Map<String, String>> todosMinisterios = const [],
  }) {
    print('🔍 [BloqueioController] inicializar chamado');
    print('🔍 [BloqueioController] Motivo inicial: $motivoInicial');
    print('🔍 [BloqueioController] Ministérios iniciais: $ministeriosIniciais');
    print('🔍 [BloqueioController] Todos os ministérios: $todosMinisterios');
    print('🔍 [BloqueioController] Quantidade de ministérios: ${todosMinisterios.length}');
    print('🔍 [BloqueioController] Tipo dos ministérios: ${todosMinisterios.runtimeType}');
    
    motivoController.text = motivoInicial ?? '';

    // Preenche o mapa com todos os ministérios possíveis, marcando como selecionado apenas os que vieram como parâmetro
    ministeriosSelecionados.clear();
    print('🔍 [BloqueioController] Mapa de ministérios limpo');
    
    for (var m in todosMinisterios) {
      final ministryName = m['name'] ?? 'Ministério';
      ministeriosSelecionados[ministryName] = ministeriosIniciais?.contains(ministryName) ?? false;
      print('🔍 [BloqueioController] Ministério adicionado ao mapa: $ministryName (selecionado: ${ministeriosSelecionados[ministryName]})');
    }
    
    print('🔍 [BloqueioController] Mapa de ministérios final: $ministeriosSelecionados');
    print('🔍 [BloqueioController] Chaves do mapa: ${ministeriosSelecionados.keys.toList()}');
    mostrarMensagemInfo = true;
    erroMinisterios = false;
    notifyListeners();
    print('🔍 [BloqueioController] inicializar concluído');
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
    print('🔍 [BloqueioController] validarFormulario chamado');
    final form = formKey.currentState;
    print('🔍 [BloqueioController] Form state: $form');
    
    erroMinisterios = !ministeriosSelecionados.containsValue(true);
    print('🔍 [BloqueioController] Ministérios selecionados: ${ministeriosSelecionados.entries.where((e) => e.value).map((e) => e.key).toList()}');
    print('🔍 [BloqueioController] Erro ministérios: $erroMinisterios');
    
    final motivoValido = form?.validate() ?? false;
    print('🔍 [BloqueioController] Motivo válido: $motivoValido');
    print('🔍 [BloqueioController] Motivo texto: "${motivoController.text}"');
    
    final resultado = motivoValido && !erroMinisterios;
    print('🔍 [BloqueioController] Resultado final: $resultado');
    
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
