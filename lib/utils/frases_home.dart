import 'dart:math';

/// Frases motivacionais exibidas no cabeçalho da aba Início.
///
/// A frase é sorteada UMA vez por sessão (campo estático inicializado de forma
/// preguiçosa na primeira leitura): muda a cada entrada no app, mas fica
/// estável enquanto o usuário navega — sem "piscar" a cada rebuild.
class FrasesHome {
  FrasesHome._();

  static const List<String> frases = [
    'Veja onde você pode ajudar hoje.',
    'Uma pequena doação, um grande impacto.',
    'Alguém perto de você precisa da sua ajuda.',
    'Sua generosidade transforma histórias.',
    'Hoje é um ótimo dia para fazer o bem.',
    'Cada gesto de carinho conta.',
    'Juntos, a gente muda uma realidade.',
    'Doar é multiplicar esperança.',
    'Tem uma causa esperando por você.',
    'O bem que você faz volta em sorrisos.',
    'Comece pequeno, transforme muito.',
    'Solidariedade também é um superpoder.',
    'Uma ONG perto de você precisa de reforço.',
    'Que tal espalhar gentileza agora?',
    'Você faz parte da mudança.',
    'Ajudar faz bem para quem recebe — e para você.',
    'O mundo melhora quando alguém decide agir.',
    'Sua próxima doação pode chegar na hora certa.',
    'Pequenas atitudes constroem grandes causas.',
    'Tem gente contando com você hoje.',
    'Compartilhe o que você tem de melhor.',
    'A bondade é contagiante: comece a corrente.',
  ];

  /// Frase da sessão atual (sorteio estável por execução do app).
  static final String daSessao = frases[Random().nextInt(frases.length)];
}
