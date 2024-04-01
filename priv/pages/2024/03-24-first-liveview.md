%{
title: "Sua primeira LiveVew",
author: "Lubien",
tags: ~w(getting-started),
section: "Introdução",
description: "Como iniciar programando com LiveView?"
}

---

## Um passo de cada vez

O framework Phoenix trás consigo várias ferramentas configuradas para você não ter que se procupar: envio de emails, sistema de presença em tempo real, clusterização etc. Isso é incrível quando você precisa entregar um produto o mais rápido possível porém pode ser amedrontador quando você está só começando.

Para facilitar o entendimento, construí uma versão do LiveView bem enxuta chamada [LiveView Playground](https://hexdocs.pm/liveview_playground/0.1.1/readme.html). Iremos utilizar ele no início deste curso e gradualmente adicionaremos mais funcionalidades para você entender como as coisas funcionam no Phoenix e LiveView um pouco mais a cada passo.

## A LiveView mais básica de todas

Para scripts simples o comando `elixir` executa brevemente um arquivo. Vamos criar um arquivo chamado `hello_liveview.exs`.

```elixir
# conteúdo do arquivo hello_liveview.exs

Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end

LiveviewPlayground.start()
```

%{
title: ".ex ou .exs?",
description: ~H"""
<CursoWeb.CoreComponents.prose>
A extensão dos arquivos de projetos reais em elixir é <code>.ex</code>, já a extensão <code>.exs</code> é mais usada para denotar que este arquivo é apenas um script separado que não faz parte do projeto principal. Também usamos <code>.exs</code> como extensão dos nossos testes.
</CursoWeb.CoreComponents.prose>
"""
} %% .callout

Em seguida basta executar no seu terminal `elixir hello_liveview.exs` e o servidor irá ligar em http://localhost:4000

## Experimente

Tente colocar um pouco de HTML na sua função `render/1`. Para poder ver as modificações você irá precisar desligar o servidor com `Control+c` duas vezes e rodar novamente o projeto.

## Sucesso!

Agorá que você possui em mãos um playground de LiveView, nos próximos passos iremos entender o que cada pedaço desse código representa.

%{
previousUrl: "/guides/first-liveview",
previousText: "Criando sua primeira LiveView",
nextUrl: "/guides/explain-playground",
nextText: "Anatomia de uma LiveView"
} %% .prev_next_links