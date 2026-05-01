%{
title: "Anatomia de uma LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Introdução",
description: "O que cada pedaço de código aqui significa?",
previous_page_id: "v2-first-liveview",
next_page_id: "v2-mounts-and-assigns"
}

---

## Entendendo cada parte

Vamos voltar ao código do passo anterior:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end
```

## Entendendo o `mix`

O mix é a ferramenta que gerencia e compila projetos em Elixir. Projetos Phoenix podem ser iniciados rodando `mix phx.server` no diretório do projeto. Chamamos esses comandos de tarefas do mix e a tarefa `phx.server` é definida pelo próprio framework Phoenix. Ao longo deste curso vamos conhecer mais tarefas que o Phoenix cria para nos ajudar no dia a dia do desenvolvimento.

Se você usou o método de instalação Phoenix Express pode não ter percebido, mas um dos passos para instalar um projeto Phoenix localmente é rodar `mix setup`. Isso é o que chamamos de `alias` de tarefa — nada mais do que uma tarefa mix que executa uma lista de outras tarefas. Você pode verificar os aliases no seu arquivo `mix.exs`:

```elixir
defmodule MyApp.MixProject do
  #... more stuff

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      # ... more stuff
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind myapp", "esbuild myapp"],
      # ... more stuff
    ]
  end
end
```

A tarefa `mix setup` existe para simplificar uma série de passos necessários para começar a trabalhar. Em projetos Phoenix, rodar `mix setup` e depois `mix phx.server` já deve ser suficiente para você entrar em ação. Em versões mais antigas do Phoenix esse alias pode não estar disponível, então você precisaria ler o README do projeto para saber como começar.

## O módulo PageLive

O mínimo necessário para você ter uma LiveView é, pasmem, a view em si. Ou seja, uma função que explica qual código HTML será exibido para o seu usuário. Toda LiveView (sem exceção) possui uma função `render/1` que recebe exclusivamente um argumento chamado `assigns` (falaremos sobre eles em breve). Tudo que sua função render precisa fazer é retornar HTML válido usando [sigil_H/2](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2).

%{
title: ~H"Ei, o que foi aquele <code>/1</code> que você disse em <code>render/1</code>?",
description: ~H"""
Em Elixir as funções são diferentes dependendo do número de argumentos. Então assim como existe uma função chamada <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/1" target="\_blank"><code>Enum.count/1</code></.link> existe também a função <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/2" target="\_blank"><code>Enum.count/2</code></.link> que recebe dois argumentos e elas são diferentes entre si. Vale mencionar que esse número de argumentos representa a <strong class="text-black dark:text-white">aridade da função</strong>. Uma função que aceita um argumento é unária. Uma que aceita dois é binária. Uma que aceita três é ternária.
"""
} %% .callout


```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end
```

A primeira linha do módulo, `use MyappWeb, :live_view`, é importante e você vai vê-la em todas as aplicações LiveView. O macro `use` funciona nos bastidores como uma forma de executar código em tempo de compilação. Pense nele como: "quando esse código for compilado, algumas coisas serão adicionadas." Quando estudarmos o módulo `MyappWeb` tudo ficará mais claro, mas por enquanto basta saber que quase toda vez que você criar uma LiveView, o módulo dela terá algo como `use MyappWeb, :live_view`.

%{
title: ~H"<code>sigil_H/2</code>?",
description: ~H"""
Em Elixir, <code>sigils</code> são funções binárias (recebem 2 argumentos) usadas para transformar texto em outra coisa. O <code>sigil_H/2</code> transforma HTML válido em uma estrutura de dados otimizada para enviar HTML ao seu usuário. <strong class="text-black dark:text-white">Precisamos saber como ele funciona por dentro?</strong> Não! Mas veremos isso no futuro, apenas por curiosidade, em tópicos avançados.
"""
} %% .callout

## Resumindo!

- O mix é a ferramenta de compilação de projetos Elixir.
- `mix setup` é útil para começar a trabalhar em projetos que você acabou de clonar.
- Toda LiveView tem uma função `render/1` e ela sempre recebe um argumento chamado `assigns`.
- `use MyappWeb, :live_view` adiciona coisas em tempo de compilação para fazer sua LiveView funcionar corretamente.