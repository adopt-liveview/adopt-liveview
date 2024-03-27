%{
title: "HEEx não é HTML",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "O que diabos é HEEx?"
}

---

Deixa eu lhe contar um segredo. Até agora eu ficava chamando o resultado de render function de HTML. A história não é bem assim! A `sigil_H` retorna na verdade uma estrutura de dados chamada HEEx. Esta estrutura é otimizada para saber quando algo foi modificado baseado em seus assigns e enviar o mínimo de dados do cliente para o servidor.

%{
title: "Como pronunciar HEEx?",
description: ~H"""
A prunúncia oficial do criador é "hiccs" como pode ser visto
<.link navigate="https://www.youtube.com/watch?v=FADQAnq0RpA&t=1420s" target="\_blank">neste vídeo</.link> que introduz a estrutura.
"""
} %% .callout

Nas próximas aulas iremos aprender um pouco mais sobre os super poderes do HEEx. Na realidade, você já aprendeu pelo menos uma: os `assigns` são parte do leque de funcionalidades do HEEx.
