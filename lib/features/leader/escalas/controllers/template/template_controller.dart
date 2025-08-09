import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';

class TemplateController extends ChangeNotifier {
  final List<TemplateModel> _templates = [];

  List<TemplateModel> get todos => List.unmodifiable(_templates);

  void adicionarTemplate(TemplateModel template) {
    _templates.add(template);
    notifyListeners();
  }

  void atualizarTemplate(TemplateModel templateAtualizado) {
    final index = _templates.indexWhere((t) => t.id == templateAtualizado.id);
    if (index != -1) {
      _templates[index] = templateAtualizado;
      notifyListeners();
    }
  }

  void removerTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  TemplateModel? buscarPorId(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  void limparTemplates() {
    _templates.clear();
    notifyListeners();
  }
}