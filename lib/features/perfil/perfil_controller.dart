import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilItem {
  final String title;
  final VoidCallback onTap;

  PerfilItem({required this.title, required this.onTap});
}

class PerfilController extends ChangeNotifier {
  String nome = 'Anderson Alves';
  String email = 'andersonalves.tech@gmail.com';
  String igreja = 'Igreja oceano da graça - campus Águas claras';
  int vezesServiu = 12;

  File? imagemPerfil;

  Future<void> selecionarImagemDaGaleria() async {
    final picker = ImagePicker();
    final imagemSelecionada =
        await picker.pickImage(source: ImageSource.gallery);

    if (imagemSelecionada != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final nomeArquivo = 'foto_perfil.png';
      final caminhoCompleto = '${appDir.path}/$nomeArquivo';
      final imagemSalva =
          await File(imagemSelecionada.path).copy(caminhoCompleto);

      imagemPerfil = imagemSalva;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('caminhoImagemPerfil', imagemSalva.path);

      notifyListeners();
    }
  }

  Future<void> carregarImagemSalva() async {
    final prefs = await SharedPreferences.getInstance();
    final caminho = prefs.getString('caminhoImagemPerfil');

    if (caminho != null) {
      final arquivo = File(caminho);
      if (await arquivo.exists()) {
        imagemPerfil = arquivo;
        notifyListeners();
      }
    }
  }

  void atualizarVezesServiu(int novoValor) {
    vezesServiu = novoValor;
    notifyListeners();
  }

  // Menu dinâmico
  List<PerfilItem> get menuItems => [
        PerfilItem(
          title: 'Informações pessoais',
          onTap: () {
            debugPrint('Abrir Informações pessoais');
          },
        ),
        PerfilItem(
          title: 'Suas funções',
          onTap: () {
            debugPrint('Abrir Suas funções');
          },
        ),
        PerfilItem(
          title: 'Preferências',
          onTap: () {
            debugPrint('Abrir Preferências');
          },
        ),
        PerfilItem(
          title: 'Sobre o aplicativo',
          onTap: () {
            debugPrint('Abrir Sobre o aplicativo');
          },
        ),
      ];

  ImageProvider<Object> get imagemPerfilProvider {
    return imagemPerfil != null
        ? FileImage(imagemPerfil!) as ImageProvider<Object>
        : const NetworkImage('https://picsum.photos/200');
  }
}
