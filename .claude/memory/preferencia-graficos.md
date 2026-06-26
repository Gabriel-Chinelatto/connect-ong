---
name: preferencia-graficos
description: Preferência do usuário sobre elementos gráficos/ilustrações no Connect ONG
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c6d1da92-9e74-4fa5-be2c-464ffcc31096
---

Onde a UI precisar de **itens gráficos/ilustrações** (não só ícones), o usuário autoriza usar **bases de imagens free** e/ou **arquivos SVG** para o andamento do projeto preliminar.

**Why:** deixar as telas mais profissionais/"com vida" (feedback da banca) sem travar o avanço por falta de assets.

**How to apply:** preferir **SVG** via pacote `flutter_svg` (vetorial, escala bem, livre). Como não dá para baixar binários de forma confiável no ambiente, **autorar SVGs originais** (formas simples nas cores da marca `AppColors`, verde 0xFF0A8449) salvos em `assets/images/` e registrados no pubspec — evita dependência de internet em runtime (importante para a FECITEC) e qualquer problema de licença. Se um dia houver acesso a bancos free (unDraw, etc.), pode usar respeitando a licença. Relacionado: Bloco 21 (polimento visual) está reservado para o final. Ver [[connect-ong-roadmap]].
