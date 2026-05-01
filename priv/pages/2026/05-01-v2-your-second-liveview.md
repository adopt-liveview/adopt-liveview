%{
title: "Sua segunda LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "Como navegar entre LiveViews",
previous_page_id: "v2-multiple-pushes",
next_page_id: "v2-route-params"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

Todo esse tempo trabalhamos com apenas uma única LiveView chamada PageLive. Hoje vamos mudar isso.

## Conhecendo o Phoenix.Router

Toda aplicação Phoenix, sem exceção, necessita de um Router. Quando você cria um novo projeto Phoenix, ele já gera esse arquivo com o nome `SeuProjeto.Router`. Abra o `lib/myapp_web/router.ex`:

```elixir
defmodule MyappWeb.Router do
  use MyappWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyappWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyappWeb do
    pipe_through :browser

    live "/", PageLive, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MyappWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:myapp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MyappWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
```

## Anatomia de um módulo de router

### O macro `use`

O Phoenix sempre adiciona nos módulos de router algo como `use MyappWeb, :router`. Por baixo dos panos, ele importa funções de router como `get/4`, `post/4` e `live/4` para que você possa definir rotas.

### Pipelines

Pense nas pipelines como configurações reutilizáveis do router para múltiplos grupos de rotas. Por ora, tudo que você precisa saber é que a pipeline `:browser` funciona, bem, em navegadores. Elas são usadas dentro de blocos `scope` como `pipe_through :pipeline_name`.

### Rotas de desenvolvimento

Usando `if Application.compile_env(:myapp, :dev_routes) do` conseguimos garantir que certas rotas sejam compiladas apenas em ambiente de desenvolvimento, sendo ignoradas em produção. Isso é útil para nosso Mailbox fake (para testar envio de e-mails sem configurar SMTP ou APIs) e para a rota do [Live Dashboard](https://github.com/phoenixframework/phoenix_live_dashboard/). Ficou curioso? Abra [http://localhost:4000/dev/dashboard](http://localhost:4000/dev/dashboard)

### Bloco de scope

Blocos `scope/4` são frequentemente usados para agrupar rotas com requisitos similares. Em projetos Phoenix é comum ver um scope para rotas não autenticadas, outro para rotas autenticadas e um ou mais scopes para rotas de API. Mais adiante, veremos tudo isso com mais detalhes.

## Adicionando nossa segunda LiveView

Usando o macro [`live/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live/4), definimos que na página inicial (`"/"`) o módulo `PageLive` será renderizado e sua Live Action será `:home`. Não se preocupe com a Live Action por enquanto; voltaremos a ela em aulas futuras.

Edite o `router.ex` para adicionar uma segunda rota assim:

```elixir
...
scope "/" do
  pipe_through :browser

  live "/", PageLive, :home
  live "/other", OtherPageLive, :other
end
...
```

Em seguida, crie um arquivo em `lib/myapp_web/live/other_live.ex`:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end
```

E por fim, edite sua `PageLive` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>PageLive</h1>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end
```

A `OtherPageLive` é bem parecida com a primeira. Mudamos apenas o texto principal e o texto do botão de navegação.

As novidades aqui são duas: o componente `<.link>` e a `sigil_p`.

## O componente `<.link>`

Esta é a primeira vez neste curso que você vê uma tag HTML que começa com `.`. Essas tags são conhecidas como componentes; falaremos sobre elas em detalhes no futuro.

O importante do componente [`.link`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#link/1) é que ele é especializado em gerar navegação entre páginas do seu site Phoenix. Usando o atributo `navigate={...}`, o Phoenix consegue fazer uma transição otimizada entre duas LiveViews sempre que possível, portanto sempre prefira este componente ao invés de usar a tag `<a>` do HTML.

## Rotas Verificadas do Phoenix

Em projetos Phoenix, sempre que você quiser escrever uma rota poderia muito bem usar uma string como "/caminho/da/pagina". E se essa rota não existir? Só saberíamos ao clicar nesse link e ver o problema.

Para evitar surpresas com rotas que não existem, o Phoenix traz uma funcionalidade chamada Rotas Verificadas, onde você usa a `sigil_p` no formato `~p"/caminho/da/pagina/"` e o Phoenix avisará se você estiver usando rotas que não existem.

## Resumindo!

- Toda aplicação Phoenix tem um Router.
- Os Routers usam pipelines e blocos `scope` para definir como certas rotas se comportam.
- Em um Router podemos definir rotas LiveView usando o macro `live/4`.
- Tags HTML com `.` no início, como `<.link>`, indicam que aquela tag é na verdade um componente.
- Devemos usar o componente `<.link navigate={~p"/rota"}>` nas nossas LiveViews para navegar de forma eficiente entre rotas.
- Usando a `sigil_p`, conseguimos escrever rotas de modo que o Phoenix nos avise se elas não existirem, detectando problemas em tempo de desenvolvimento.