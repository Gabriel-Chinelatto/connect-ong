import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// UFs do Brasil em ordem alfabética (fonte: IBGE, 26 estados + DF).
const List<String> ufsBrasil = [
  'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
  'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
  'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
];

// Mapa de caracteres acentuados usados em nomes de municípios brasileiros
// (e suas maiúsculas) para o equivalente sem acento.
const Map<String, String> _mapaAcentos = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
  'Ç': 'C', 'Ñ': 'N',
};

/// Remove os acentos de [s] ("São" → "Sao"). Função pura e top-level para
/// poder ser testada sem montar widget nem carregar asset.
String semAcento(String s) {
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    sb.write(_mapaAcentos[c] ?? c);
  }
  return sb.toString();
}

/// Filtra [cidades] pelo [termo], sem diferenciar maiúsculas/minúsculas nem
/// acentos ("sao" encontra "São Paulo"; "MOGI" encontra "Mogi das Cruzes").
/// Busca por "contém" — o que inclui a busca por prefixo. Termo vazio devolve
/// a lista inteira. Função pura para ser testável com lista injetada.
List<String> filtrarCidades(List<String> cidades, String termo) {
  final t = semAcento(termo.trim().toLowerCase());
  if (t.isEmpty) return cidades;
  return cidades
      .where((cidade) => semAcento(cidade.toLowerCase()).contains(t))
      .toList();
}

/// Seletor de localização Estado → Cidade com dados do IBGE embarcados
/// (asset `assets/dados/municipios_por_uf.json`, offline).
///
/// - O dropdown de Estado lista as 27 UFs; a Cidade só habilita depois de
///   escolher a UF e sugere apenas os municípios daquela UF (Autocomplete).
/// - Trocar ou limpar o Estado limpa a Cidade.
/// - A cidade NÃO é validada contra a lista: texto livre legado (perfis
///   antigos) aparece como valor atual sem travar o formulário.
/// - Se o asset falhar ao carregar, o campo Cidade degrada para texto livre.
class SeletorUfCidade extends StatefulWidget {
  /// UF já salva no perfil (ex.: "SP"). Valores fora da lista são ignorados.
  final String? ufInicial;

  /// Cidade já salva no perfil — exibida mesmo que não exista na lista da UF.
  final String? cidadeInicial;

  /// Notificado a cada mudança; `null` significa "sem valor" (campo vazio).
  final void Function(String? uf, String? cidade) onChanged;

  const SeletorUfCidade({
    super.key,
    this.ufInicial,
    this.cidadeInicial,
    required this.onChanged,
  });

  @override
  State<SeletorUfCidade> createState() => _SeletorUfCidadeState();
}

class _SeletorUfCidadeState extends State<SeletorUfCidade> {
  // Cache estático (Future memoizado): o JSON de 5.571 municípios é lido do
  // asset uma única vez por sessão, mesmo abrindo várias telas com o seletor.
  static Future<Map<String, List<String>>>? _futuroMunicipios;

  static Future<Map<String, List<String>>> _carregarMunicipios() {
    return _futuroMunicipios ??= rootBundle
        .loadString('assets/dados/municipios_por_uf.json')
        .then((texto) {
      final Map<String, dynamic> bruto = json.decode(texto);
      return bruto.map(
        (uf, cidades) => MapEntry(uf, (cidades as List).cast<String>()),
      );
    });
  }

  String? _uf;
  String _cidade = '';
  Map<String, List<String>>? _municipios;
  bool _falhaCarga = false;

  // Incrementado ao trocar a UF: muda a Key do Autocomplete, recriando-o com
  // o campo de cidade vazio (jeito simples de "limpar" o controller interno).
  int _geracaoCidade = 0;

  // Controller do fallback de texto livre (só usado quando o asset falha).
  late final TextEditingController _cidadeLivre =
      TextEditingController(text: _cidade);

  @override
  void initState() {
    super.initState();
    final ufBruta = widget.ufInicial?.trim().toUpperCase() ?? '';
    _uf = ufsBrasil.contains(ufBruta) ? ufBruta : null;
    _cidade = widget.cidadeInicial?.trim() ?? '';
    _carregarMunicipios().then((dados) {
      if (mounted) setState(() => _municipios = dados);
    }).catchError((_) {
      // Degrada para texto livre e zera o cache para permitir nova tentativa
      // em outra tela/sessão.
      _futuroMunicipios = null;
      if (mounted) setState(() => _falhaCarga = true);
    });
  }

  @override
  void dispose() {
    _cidadeLivre.dispose();
    super.dispose();
  }

  void _aoTrocarUf(String? novaUf) {
    if (novaUf == _uf) return;
    setState(() {
      _uf = novaUf;
      _cidade = '';
      _geracaoCidade++; // recria o Autocomplete já vazio
    });
    _cidadeLivre.clear();
    widget.onChanged(_uf, null);
  }

  void _aoTrocarCidade(String valor) {
    _cidade = valor;
    widget.onChanged(_uf, valor.trim().isEmpty ? null : valor.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campoUf(),
        const SizedBox(height: AppSpacing.md),
        _campoCidade(),
      ],
    );
  }

  // ---- Estado (UF) ----
  Widget _campoUf() {
    return DropdownButtonFormField<String>(
      // `initialValue` substitui o antigo `value` (deprecado no Flutter 3.32+).
      initialValue: _uf,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Estado (UF)',
        prefixIcon: const Icon(Icons.map_outlined),
        // Botão para limpar a UF (que também limpa a cidade).
        suffixIcon: _uf == null
            ? null
            : IconButton(
                tooltip: 'Limpar estado',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _aoTrocarUf(null),
              ),
      ),
      hint: const Text('Selecione o estado'),
      items: [
        for (final uf in ufsBrasil)
          DropdownMenuItem(value: uf, child: Text(uf)),
      ],
      onChanged: _aoTrocarUf,
    );
  }

  // ---- Cidade ----
  Widget _campoCidade() {
    // Asset indisponível: texto livre (não trava a tela).
    if (_falhaCarga) {
      return TextFormField(
        controller: _cidadeLivre,
        maxLength: 60,
        onChanged: _aoTrocarCidade,
        decoration: const InputDecoration(
          labelText: 'Cidade',
          prefixIcon: Icon(Icons.location_city_outlined),
          counterText: '',
        ),
      );
    }

    // Sem UF escolhida (ou lista ainda carregando): campo desabilitado com a
    // dica adequada — mas exibindo o valor legado salvo, se houver.
    final carregando = _municipios == null;
    if (_uf == null || carregando) {
      return TextFormField(
        key: ValueKey('cidade-inativa-$_geracaoCidade'),
        enabled: false,
        initialValue: _cidade,
        decoration: InputDecoration(
          labelText: 'Cidade',
          hintText: _uf == null
              ? 'Escolha primeiro o estado'
              : 'Carregando cidades…',
          prefixIcon: const Icon(Icons.location_city_outlined),
        ),
      );
    }

    final cidadesDaUf = _municipios![_uf] ?? const <String>[];

    // LayoutBuilder só para dar ao painel de opções a mesma largura do campo.
    return LayoutBuilder(builder: (context, constraints) {
      return Autocomplete<String>(
        key: ValueKey('cidade-$_geracaoCidade'),
        // Valor inicial livre: cidade legada aparece mesmo fora da lista.
        initialValue: TextEditingValue(text: _cidade),
        optionsBuilder: (TextEditingValue v) =>
            filtrarCidades(cidadesDaUf, v.text),
        onSelected: _aoTrocarCidade,
        fieldViewBuilder: (context, controller, focusNode, aoSubmeter) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLength: 60,
            onChanged: _aoTrocarCidade,
            onFieldSubmitted: (_) => aoSubmeter(),
            decoration: const InputDecoration(
              labelText: 'Cidade',
              hintText: 'Digite para buscar',
              prefixIcon: Icon(Icons.location_city_outlined),
              counterText: '',
            ),
          );
        },
        optionsViewBuilder: (context, aoEscolher, opcoes) {
          final cs = Theme.of(context).colorScheme;
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: cs.surfaceContainerHigh,
              borderRadius: AppRadius.brMd,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 240,
                  maxWidth: constraints.maxWidth,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: opcoes.length,
                  itemBuilder: (context, i) {
                    final opcao = opcoes.elementAt(i);
                    return InkWell(
                      onTap: () => aoEscolher(opcao),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        child: Text(
                          opcao,
                          style: TextStyle(color: cs.onSurface),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
