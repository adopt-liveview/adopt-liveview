%{
title: "Sua segunda LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "Como navegar entre LiveViews"
}

---

Todo esse tempo estivamos trabalhando apenas com uma única LiveView chamada PageLive. A escolha desse nome foi simples na verdade, o LiveView Playground verifica se o módulo PageLive existe e faz ele ser a página inicial do seu projeto.

## Conhecendo o Phoenix.Router

Toda aplicação Phoenix, sem exceção, necessita de um Router. Quando você cria um novo projeto Phoenix ele já gera esse arquivo com o nome `SeuProjeto.Router`. Vamos ver como o LiveViewPlayground define o Router dele:

```elixir
defmodule LiveviewPlayground.Router do
  use LiveviewPlayground, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", PageLive, :index
  end
end
```

Todo esse tempo em que você estava usando `LiveviewPlayground.start()` o módulo acima era implicitamente usado e, como explicado anteriormente, a existência do módulo LiveView chamado `PageLive` era obrigatório pois o Router padrão do LiveView Playground fazia a suposição de que ele existia. Vale mencionar que este exemplo é muito próximo de como um projeto real Phoenix realmente funciona.

Apesar de muitas coisas novas terem aparecido vamos focar numa visão geral. Em outro momento iremos ver com detalhes cada pedaço. Simplificando:

- A linha `use LiveviewPlayground, :router` importa funções e macros necessários para criarmos nossas rotas.
- O bloco `pipeline :browser do` define um conjunto de plugs (entenda eles como configurações no momento) para rotas do tipo `:browser`. Neste cásido só definimos que é uma rota que usa HTML.
- Usamos o bloco `scope "/" do` para representar que as rotas dentro do bloco são renderizadas na raiz do nosso site.
- `pipe_through :browser` ativa a pipeline chamada `:browser` neste escopo.

Agora o mais importante: como definit uma rota LiveView. Usando o macro [`live/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live/4) nós definimos que na página inicial (`"/"`) o módulo `PageLive` será renderizado e sua Live Action será `:index`. No momento, você não precisa se preocupar com a Live Action, retomaremos ela no futuro.

## Construindo seu primeiro Phoenix.Router

Agora que entendemos o fundamental de um Router iremos construir um novo router na prática. Crie e execute um arquivo chamado `router.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.3"}
])

defmodule CustomRouter do
  use LiveviewPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/other", OtherPageLive, :index
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>IndexLive</h1>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

O primeiro módulo aqui se chama CustomRouter (poderia ser qualquer nome). A única diferença do Router original é que ele possui duas utilizações do macro `live/4` para duas LiveViews diferentes. Note que dessa vez nomeamos nossa rota principal como IndexLive só para demonstrar que se você puder modificar o Router você pode chamar suas LiveViews como quiser.

A última linha do nosso arquivo passa explicitamente o router para o Playground. Isto é uma coisa específica do LiveView Playground e não de projetos Phoenix reais.

Cada LiveView é bem parecida com a outra mudando apenas o texto principal e o texto do botão de navegação. O que temos de novo aqui são duas coisas: o component `<.link>` e a `sigil_p`.

## O componente `<.link>`

Esta é a primeira vez neste curso que você vê uma tag HTML que começa com `.` no momento. Estas tags são conhecidas como componentes, iremos falar sobre eles em detalhes no futuro.

O importante do componente [`.link`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#link/1) é que ele é especializado em gerar navegação entre páginas do seu site Phoenix. Usando o atributo `navigate={...}` o Phoenix consegue fazer uma transição otimizada entre duas LiveViews sempre que possível portanto sempre prefira este componente ao invés de usar a tag `<a>` do HTML.

## Rotas verificadas do Phoenix

Em projetos Phoenix sempre que você quiser escrever uma rota você poderia muito bem usar uma string como "/caminho/da/pagina". E se essa rota não existir? Só saberíamos quando clicarmos neste link e vermos o bug.

Para evitar surpresas com rotas que não existe o Phoenix vem com uma funcionalidade chamada Rotas Verificadas em que você usa a `sigil_p` no formato `~p"/caminho/da/pagina/"` e o Phoenix vai lhe avisar em warnings se você está usando rotas que não existem.

%{
title: "Rotas Verificadas e LiveView Playground",
type: :warning,
description: ~H"""
Até o momento o LiveView Playground não consegue checar rotas usando a <code>`sigil_p`</code>. De todo modo, a recomendação é que você continue usando elas por padrão.
"""
} %% .callout

## Resumindo!

- Toda aplicação Phoenix tem um Router.
- Em um Router podemos definir rotas LiveView usando o macro `live/4`.
- Tag HTML com `.` no início como `<.link>` indicam que aquela tag na verdade é um componente.
- Devemos usar o componente `<.link navigate={~p"/rota"}>` para nossa LiveView navegar de modo eficiente entre rotas.
- Usando a `sigil_p` nós conseguimos escrever rotas de modo que o Phoenix irá nos avisar se elas não existirem para que possamos detectar problemas em tempo de desenvolvimento.
