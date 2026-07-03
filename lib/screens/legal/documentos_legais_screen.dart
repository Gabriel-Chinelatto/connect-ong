import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Documentos legais da plataforma (LGPD - Lei 13.709/2018).
///
/// Uma unica tela que exibe a Politica de Privacidade ou os Termos de Uso,
/// de acordo com o [tipo] informado. Usada tanto na Central de Configuracoes
/// quanto no fluxo de cadastro (consentimento).
enum DocumentoLegal { privacidade, termos }

class DocumentosLegaisScreen extends StatelessWidget {
  final DocumentoLegal tipo;

  const DocumentosLegaisScreen({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final doc = tipo == DocumentoLegal.privacidade
        ? _politicaPrivacidade
        : _termosDeUso;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.titulo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            doc.titulo,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ultima atualizacao: ${doc.atualizacao}',
            // Cor do tema (funciona no claro e no escuro).
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          for (final s in doc.secoes) ...[
            Text(
              s.titulo,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.texto,
              style: const TextStyle(fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

// =========================================================================
// Conteudo dos documentos (compartilhado pela UI)
// =========================================================================

class _SecaoLegal {
  final String titulo;
  final String texto;
  const _SecaoLegal(this.titulo, this.texto);
}

class _DocumentoConteudo {
  final String titulo;
  final String atualizacao;
  final List<_SecaoLegal> secoes;
  const _DocumentoConteudo(this.titulo, this.atualizacao, this.secoes);
}

const _DocumentoConteudo _politicaPrivacidade = _DocumentoConteudo(
  'Politica de Privacidade',
  'Junho de 2026',
  [
    _SecaoLegal(
      '1. Quem somos',
      'O Connect ONG e uma plataforma que conecta doadores a organizacoes nao '
          'governamentais (ONGs), facilitando doacoes de itens e financeiras. '
          'Esta politica explica como tratamos seus dados pessoais, em '
          'conformidade com a Lei Geral de Protecao de Dados (LGPD - Lei '
          '13.709/2018).',
    ),
    _SecaoLegal(
      '2. Dados que coletamos',
      'Coletamos os dados que voce nos fornece ao criar sua conta e usar o app: '
          'nome, e-mail, telefone, cidade e estado, alem das doacoes, '
          'mensagens e interacoes que voce realiza na plataforma. A senha e '
          'armazenada de forma criptografada e nunca em texto puro.',
    ),
    _SecaoLegal(
      '3. Para que usamos seus dados',
      'Usamos seus dados para autenticar seu acesso, conectar voce a ONGs '
          'compativeis, viabilizar o contato e as doacoes, enviar notificacoes '
          'que voce autorizou e melhorar a experiencia da plataforma. Nao '
          'vendemos seus dados pessoais a terceiros.',
    ),
    _SecaoLegal(
      '4. Compartilhamento',
      'Seus dados de contato so sao exibidos a outras partes quando voce '
          'autoriza nas Configuracoes de Privacidade (exibir telefone, exibir '
          'e-mail, perfil publico). Ao demonstrar interesse em uma necessidade, '
          'a ONG correspondente recebe os dados necessarios para concluir a '
          'doacao.',
    ),
    _SecaoLegal(
      '5. Seus direitos (LGPD)',
      'Voce pode, a qualquer momento, acessar, corrigir ou solicitar a exclusao '
          'dos seus dados, revogar consentimentos e gerenciar suas preferencias '
          'na Central de Configuracoes. Para exercer esses direitos, utilize as '
          'opcoes do app ou entre em contato com nossa equipe.',
    ),
    _SecaoLegal(
      '6. Seguranca',
      'Adotamos medidas tecnicas para proteger seus dados, como criptografia de '
          'senhas e autenticacao por token. Ainda assim, nenhum sistema e '
          'totalmente imune a riscos, e recomendamos que voce mantenha sua '
          'senha em sigilo.',
    ),
    _SecaoLegal(
      '7. Contato',
      'Em caso de duvidas sobre esta politica ou sobre o tratamento dos seus '
          'dados, fale com a equipe do Connect ONG pelos canais oficiais do '
          'projeto.',
    ),
  ],
);

const _DocumentoConteudo _termosDeUso = _DocumentoConteudo(
  'Termos de Uso',
  'Junho de 2026',
  [
    _SecaoLegal(
      '1. Aceitacao',
      'Ao criar uma conta e utilizar o Connect ONG, voce concorda com estes '
          'Termos de Uso e com a Politica de Privacidade. Se voce nao concordar, '
          'nao utilize a plataforma.',
    ),
    _SecaoLegal(
      '2. A plataforma',
      'O Connect ONG e uma ponte entre doadores e ONGs. Nao somos parte das '
          'doacoes em si: facilitamos o encontro e a comunicacao entre as '
          'partes. A responsabilidade pela entrega e pelo uso correto das '
          'doacoes e das partes envolvidas.',
    ),
    _SecaoLegal(
      '3. Responsabilidades do usuario',
      'Voce se compromete a fornecer informacoes verdadeiras, manter sua senha '
          'em sigilo, respeitar as outras pessoas e ONGs e nao utilizar a '
          'plataforma para fins ilegais, fraudulentos ou que violem direitos de '
          'terceiros.',
    ),
    _SecaoLegal(
      '4. Conteudo e conduta',
      'E proibido publicar conteudo ofensivo, enganoso ou que desrespeite a '
          'dignidade de qualquer pessoa ou organizacao. Contas que descumprirem '
          'estas regras podem ser suspensas ou removidas.',
    ),
    _SecaoLegal(
      '5. Doacoes',
      'As doacoes registradas na plataforma sao um compromisso entre doador e '
          'ONG. O Connect ONG nao cobra taxas sobre doacoes e nao se '
          'responsabiliza por acordos firmados fora da plataforma.',
    ),
    _SecaoLegal(
      '6. Alteracoes',
      'Podemos atualizar estes Termos para refletir melhorias ou exigencias '
          'legais. Mudancas relevantes serao comunicadas dentro do app. O uso '
          'continuado apos as mudancas representa concordancia com a nova '
          'versao.',
    ),
  ],
);
