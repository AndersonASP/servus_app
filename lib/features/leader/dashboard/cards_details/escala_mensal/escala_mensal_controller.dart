import 'package:flutter/material.dart';

class EscalaMensalController extends ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> escalasPorData = {
    '04/08': [
      {
        'evento': 'Culto Manhã',
        'horario': '09:00',
        'voluntarios': [
          {
            'nome': 'João',
            'funcao': 'Guitarra',
            'foto': 'https://randomuser.me/api/portraits/men/1.jpg',
          },
          {
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },
        ],
      },
    ],
    '11/08': [
      {
        'evento': 'Culto Noite',
        'horario': '18:00',
        'voluntarios': [
          {
            'nome': 'Pedro',
            'funcao': 'Teclado',
            'foto': 'https://randomuser.me/api/portraits/men/2.jpg',
          },
        ],
      },
    ],
    '18/08': [
      {
        'evento': 'Santa Ceia (Manhã)',
        'horario': '09:00',
        'voluntarios': [
          {
            'nome': 'Lucas',
            'funcao': 'Violão',
            'foto': 'https://randomuser.me/api/portraits/men/3.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },
        ],
      },
      {
        'evento': 'Santa Ceia (Noite)',
        'horario': '18:00',
        'voluntarios': [
          {
            'nome': 'Carlos',
            'funcao': 'Guitarra Base',
            'foto': 'https://randomuser.me/api/portraits/men/4.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },
        ],
      },
    ],
    '25/08': [
      {
        'evento': 'Culto Jovem',
        'horario': '19:00',
        'voluntarios': [
          {
            'nome': 'Ana',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/2.jpg',
          },
          {
            'nome': 'Pedro',
            'funcao': 'Cajón',
            'foto': 'https://randomuser.me/api/portraits/men/5.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },{
            'nome': 'Maria',
            'funcao': 'Vocal',
            'foto': 'https://randomuser.me/api/portraits/women/1.jpg',
          },
        ],
      },
    ],
  };
}