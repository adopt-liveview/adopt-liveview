%{
title: "Parâmetros de rotas",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "Recebendo dados do URL",
previous_page_id: "your-second-liveview",
next_page_id: "query-string"
}

---

Em um sistema dinâmico é bem comum que em uma mesma rota você precise tratar variáveis vindas do URL, geralmente conhecidas como parâmetros por muitos frameworks. Vamos explorar como fazer isso com LiveView.

## Router com parâmetros

Vamos construir um blog simples. Nele podemos acessar `/blog/qualquer_coisa` e ler mais sobre isso. Crie e execute um arquivo chamado `params.exs`:

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
    live "/blog/:slug", BlogLive, :index
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Welcome to my Website!</h1>
    <ul>
      <li><.link navigate={~p"/blog/dolphins"}>Read about dolphins</.link></li>
      <li><.link navigate={~p"/blog/elephants"}>Read about elephants</.link></li>
    </ul>
    """
  end
end

defmodule BlogLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket = assign(socket, :slug, slug)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Reading about <%= @slug %></h1>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

Aqui nós criamos um rota `/blog/:slug` com uma variável no URL chamada `:slug`. Isso garante que a `BlogLive` receberá um mapa no primeiro argumento do seu `mount/3` no formato `%{"slug" => slug}` e você pode usar essa variável para criar um assign. Você pode tanto usar os links adicionados na página inicial quanto tentar URLs diferentes para `/blog/qualquer_coisa`.

%{
title: "Curiosidade",
description: ~H"""
Você está nesse site em uma rota <code>/guides/:id</code>, veja o URL no seu navegador.
"""
} %% .callout

## Resumindo!

- O macro `live/4` deixa você criar parâmetros no URL usando o formato `:nome_da_variavel`.
- Qualquer parâmetro definido no router vira uma chave no mapa `params` na sua LiveView.
