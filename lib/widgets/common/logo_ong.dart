import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

/// Foto de perfil (logo) de uma ONG, redonda, com a inicial do nome como
/// reserva.
///
/// Por que busca por URL e não por base64: as listagens do backend devolvem
/// TODAS as ONGs de uma vez (hoje 2.000). Se cada uma carregasse a própria
/// imagem embutida no JSON, a resposta iria de ~2 MB para dezenas de MB só
/// para mostrar meia dúzia de cards. Aqui cada logo é buscado individualmente
/// em `GET /publico/ongs/{id}/logo` (endpoint público, sem token — uma
/// `Image.network` não manda header de autorização) e o Flutter ainda mantém
/// cache em memória, então rolar a lista não repete o download.
///
/// ONG sem logo devolve 404 e o widget cai na inicial, exatamente como era
/// antes de existir logo.
class LogoOng extends StatelessWidget {
  const LogoOng({
    super.key,
    required this.ongId,
    required this.nome,
    this.raio = 20,
    this.corFundo,
  });

  /// Id da ONG. Null (necessidade sem ONG associada) = só a inicial.
  final int? ongId;
  final String nome;
  final double raio;
  final Color? corFundo;

  @override
  Widget build(BuildContext context) {
    final inicial = nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : '?';
    final fundo = corFundo ?? AppColors.primary;

    final reserva = CircleAvatar(
      radius: raio,
      backgroundColor: fundo,
      child: Text(
        inicial,
        style: TextStyle(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: raio * 0.8,
        ),
      ),
    );

    if (ongId == null) return reserva;

    return ClipOval(
      child: SizedBox(
        width: raio * 2,
        height: raio * 2,
        child: Image.network(
          '${ApiService.baseUrl}/publico/ongs/$ongId/logo',
          fit: BoxFit.cover,
          // Enquanto baixa (e se falhar/404) mostra a inicial: a tela nunca
          // fica com buraco nem com o ícone de imagem quebrada.
          loadingBuilder:
              (contexto, filho, progresso) =>
                  progresso == null ? filho : reserva,
          errorBuilder: (contexto, erro, pilha) => reserva,
        ),
      ),
    );
  }
}
