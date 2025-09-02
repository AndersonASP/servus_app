// perfil_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilItem {
  final String title;
  final VoidCallback onTap;
  PerfilItem({required this.title, required this.onTap});
}

class PerfilController extends ChangeNotifier {
  // Dados básicos
  String nome = 'Anderson Alves';
  String email = 'andersonalves.tech@gmail.com';
  String igreja = 'Igreja oceano da graça - campus Águas claras';
  int vezesServiu = 12;

  // URL atual da foto (padronizada como `picture`)
  String? pictureUrl;

  // Arquivo local (quando o usuário escolhe da galeria sem upload)
  File? imagemPerfilLocal;

  // Pode ser null -> tela mostra iniciais
  ImageProvider<Object>? _imagemProvider;
  ImageProvider<Object>? get imagemPerfilProvider => _imagemProvider;

  /// Prioridade: URL `picture` > arquivo local `caminhoImagemPerfil`
  Future<void> carregarDadosSalvos() async {
    final prefs = await SharedPreferences.getInstance();

    nome  = prefs.getString('nome')  ?? nome;
    email = prefs.getString('email') ?? email;
    igreja = prefs.getString('igreja') ?? igreja;

    // 1) URL
    final url = prefs.getString('picture');
    if (url != null && url.isNotEmpty) {
      pictureUrl = url;
      imagemPerfilLocal = null;
      _imagemProvider = NetworkImage(url);
      notifyListeners();
      return;
    }

    // 2) Caminho local (⚠️ chave correta)
    final caminho = prefs.getString('caminhoImagemPerfil');
    if (caminho != null && caminho.isNotEmpty) {
      final arquivo = File(caminho);
      if (await arquivo.exists()) {
        imagemPerfilLocal = arquivo;
        pictureUrl = null;
        _imagemProvider = FileImage(arquivo);
        notifyListeners();
        return;
      }
    }

    // 3) Nenhuma imagem -> usa iniciais
    pictureUrl = null;
    imagemPerfilLocal = null;
    _imagemProvider = null;
    notifyListeners();
  }

  /// Seleciona imagem da galeria e salva localmente
  Future<void> selecionarImagemDaGaleria() async {
    final picker = ImagePicker();
    final selecionada = await picker.pickImage(source: ImageSource.gallery);
    if (selecionada == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final caminho = '${appDir.path}/foto_perfil.png';
    final salvo = await File(selecionada.path).copy(caminho);

    imagemPerfilLocal = salvo;
    pictureUrl = null;
    _imagemProvider = FileImage(salvo);

    final prefs = await SharedPreferences.getInstance();
    // ⚠️ salva caminho local na chave certa e limpa a URL
    await prefs.setString('caminhoImagemPerfil', salvo.path);
    await prefs.remove('picture');

    notifyListeners();
  }

  /// Atualiza a foto com uma NOVA URL (ex.: após upload no Storage).
  Future<void> atualizarPictureComNovaUrl(String novaUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picture', novaUrl);
    await prefs.remove('caminhoImagemPerfil'); // não precisamos mais do arquivo local

    pictureUrl = novaUrl;
    imagemPerfilLocal = null;
    _imagemProvider = NetworkImage(novaUrl);
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final auth = context.read<AuthState>();
    await auth.logoutCompleto();
  }

  List<PerfilItem> get menuItems => [
        PerfilItem(title: 'Informações pessoais', onTap: () {}),
        PerfilItem(title: 'Suas funções', onTap: () {}),
        PerfilItem(title: 'Preferências', onTap: () {}),
        PerfilItem(title: 'Sobre o aplicativo', onTap: () {}),
      ];
}