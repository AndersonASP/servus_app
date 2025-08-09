import 'package:flutter/material.dart';
import 'package:servus_app/core/models/voluntarios.dart';

class VoluntariosController extends ChangeNotifier {
  final List<Voluntario> _todosVoluntarios = [
    Voluntario(nome: 'Anderson Alves', funcao: 'Baixista', ativo: true),
    Voluntario(nome: 'Samila Costa', funcao: 'Baterista', ativo: false),
    Voluntario(nome: 'Lucas Lima', funcao: 'Guitarrista', ativo: true),
    Voluntario(nome: 'Mariana Souza', funcao: 'Tecladista', ativo: false),
    Voluntario(nome: 'Carlos Pereira', funcao: 'Vocal', ativo: true),
    Voluntario(nome: 'Beatriz Mendes', funcao: 'Backing vocal', ativo: true),
    Voluntario(nome: 'Juliana Rocha', funcao: 'Ministra de louvor', ativo: true),
  ];

  List<Voluntario> voluntariosFiltrados = [];
  String filtro = 'todos';

  VoluntariosController() {
    aplicarFiltro('todos');
  }

  void aplicarFiltro(String novoFiltro) {
    filtro = novoFiltro;
    switch (filtro) {
      case 'ativos':
        voluntariosFiltrados = _todosVoluntarios.where((v) => v.ativo).toList();
        break;
      case 'inativos':
        voluntariosFiltrados = _todosVoluntarios.where((v) => !v.ativo).toList();
        break;
      default:
        voluntariosFiltrados = List.from(_todosVoluntarios);
    }
    notifyListeners();
  }

  void alternarStatus(Voluntario voluntario) {
    voluntario.ativo = !voluntario.ativo;
    aplicarFiltro(filtro);
  }

  void editarVoluntario(Voluntario voluntario) {
    // Navegação ou lógica para edição aqui
  }
} 