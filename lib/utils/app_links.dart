/// Links públicos compartilháveis do Connect ONG.
///
/// O app web (Flutter web) abre estes links: no arranque, se o fragmento da
/// URL casar com `/ong/<id>`, o perfil público da ONG é aberto por cima do
/// portal institucional (ver `main.dart`).
library;

/// Base pública do app web.
/// TROCAR quando a web for hospedada (hoje aponta para o dev local).
const String baseUrl = 'http://localhost:5100';

/// Link compartilhável do perfil público de uma ONG.
/// Ex.: http://localhost:5100/#/ong/12
String linkPerfilOng(int ongId) => '$baseUrl/#/ong/$ongId';
