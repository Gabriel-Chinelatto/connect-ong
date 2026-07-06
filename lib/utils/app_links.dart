/// Links públicos compartilháveis do Connect ONG + helper para abrir URLs
/// externas.
///
/// O app web (Flutter web) abre estes links: no arranque, se o fragmento da
/// URL casar com `/ong/<id>`, o perfil público da ONG é aberto por cima do
/// portal institucional (ver `main.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/feedback/app_snackbar.dart';

/// Base pública do app web.
/// TROCAR quando a web for hospedada (hoje aponta para o dev local).
const String baseUrl = 'http://localhost:5100';

/// Link compartilhável do perfil público de uma ONG.
/// Ex.: http://localhost:5100/#/ong/12
String linkPerfilOng(int ongId) => '$baseUrl/#/ong/$ongId';

/// Abre uma URL externa de forma robusta em TODAS as plataformas.
///
/// Regras (importantes principalmente no Flutter web/Chrome):
/// - NUNCA usa `canLaunchUrl` antes (retorna falso-negativo na web/desktop);
/// - chama `launchUrl` direto dentro de try/catch;
/// - se lançar exceção OU retornar false (ex.: popup bloqueado no Chrome),
///   NÃO trata como erro fatal: copia o link para a área de transferência e
///   avisa o usuário — degradação graciosa em vez de um erro seco.
///
/// Use este helper em TODOS os pontos do app que abrem links externos.
Future<void> abrirLink(BuildContext context, Uri uri) async {
  bool abriu = false;
  try {
    abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    abriu = false;
  }
  if (abriu) return;

  // Fallback: copia o link e orienta o usuário (nunca falha "no seco").
  await Clipboard.setData(ClipboardData(text: uri.toString()));
  if (context.mounted) {
    AppSnackbar.sucesso(context, 'Link copiado — abra no navegador');
  }
}
