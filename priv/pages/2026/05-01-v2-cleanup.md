%{
title: "Limpando as coisas",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Vamos remover código morto e ver o que temos",
previous_page_id: "v2-my-first-liveview-project",
next_page_id: "v2-saving-data"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git`</code>.
"""
} %% .callout

Antes de prosseguirmos, vamos fazer uma faxina! Abra `lib/lineup_web/router.ex` para mudarmos nossa rota raiz de uma view morta (apenas uma forma elegante de dizer Controller Action) para uma LiveView.

```elixir
scope "/", LineupWeb do
  pipe_through :browser

  # Delete this
  get "/", PageController, :home
  # Add this
  live "/tickets", TicketLive.Index, :index
end
```

Agora precisamos criar nossa primeira LiveView em `lib/lineup_web/live/ticket_live/index.ex`:

```elixir
defmodule LineupWeb.TicketLive.Index do
  use LineupWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Tickets")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tickets
      </.header>
      List tickets here
    </Layouts.app>
    """
  end
end
```

Temos coisas novas para conversar aqui!

## O assign `@page_title`

Este é um assign especial que será usado para preencher a tag `<title>content</title>` da sua LiveView. Vá até `lib/lineup_web/components/layouts/root.html.heex` e vamos modificá-lo um pouco!

```diff
- <.live_title default="Lineup" suffix=" · Phoenix Framework">
-   {assigns[:page_title]}
- </.live_title>
+ <.live_title default="Lineup" suffix=" · LineUp App" phx-no-format>{assigns[:page_title]}</.live_title>
```

Agora temos um sufixo adequado para nossa aplicação. Não se esqueça de adicionar `page_title` em todas as suas LiveViews!

## O componente `Layouts.app`

Novos projetos Phoenix agora vêm com componentes de layout dentro de `YouappWeb.Layouts` para que você possa ajustá-los facilmente ou adicionar mais. Como você deve esperar, `use LineupWeb, :live_view` já tem aliases para `alias LineupWeb.Layouts` para que você possa usar `<Layouts.app flash={@flash}>`. Por enquanto, ignore o assign `@flash` — vamos analisá-lo em breve.

Vamos ajustar nosso template principal! Vá até `lib/lineup_web/components/layouts.ex` e altere seu `def app(assigns) do` assim:

```elixir
def app(assigns) do
  ~H"""
  <header class="navbar px-4 sm:px-6 lg:px-8">
    <div class="flex-1">
      <a href="/" class="flex-1 flex w-fit items-center gap-2">
        <span class="text-2xl font-bold tracking-tight text-primary">
          Line<span class="text-base-content">Up</span>
        </span>
        <span class="text-xs font-medium text-base-content/60 -ml-1">App</span>
      </a>
    </div>
    <div class="flex-none">
      <ul class="flex flex-column px-1 space-x-4 items-center">
        <li>
          <.theme_toggle />
        </li>
      </ul>
    </div>
  </header>

  <main class="px-4 py-20 sm:px-6 lg:px-8">
    <div class="mx-auto max-w-2xl space-y-4">
      {render_slot(@inner_block)}
    </div>
  </main>

  <.flash_group flash={@flash} />
  """
end
```

Apenas editamos o logo para usar um texto e removemos algumas referências ao Phoenix para que a aplicação comece a parecer nossa. Não removemos o alternador de tema, pois é bem útil para nossos usuários. Com o Tailwind já configurado para ter alternância de tema, podemos adicionar classes com `dark:nome-da-classe` que funcionam apenas no tema escuro.

## Deletando código morto

Como não vamos mais usar esses arquivos, vamos removê-los:

```sh
rm priv/static/images/logo.svg
rm lib/lineup_web/controllers/page_html/home.html.heex
```

Também podemos remover nossa action de controller morta em `lib/lineup_web/controllers/page_controller.ex`:

```diff
defmodule LineupWeb.PageController do
  use LineupWeb, :controller

-  def home(conn, _params) do
-    render(conn, :home)
-  end
end
```

## Resumindo!

- O assign `@page_title` é um assign mágico para atualizar a tag de título do HTML.
- Não se esqueça de atualizar seu `<.live_title>` no template raiz para corresponder ao nome do seu projeto quando começar.
- `YouappWeb.Layouts` é onde os layouts serão criados para serem usados junto com suas LiveViews.
- Delete seu código morto. Seus colegas de trabalho vão te agradecer.