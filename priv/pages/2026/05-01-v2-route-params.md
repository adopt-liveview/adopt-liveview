%{
title: "Parâmetros de rota",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "Recebendo dados da URL",
previous_page_id: "v2-your-second-liveview",
next_page_id: "v2-query-string"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch your-second-liveview-done`</code>.
"""
} %% .callout

Em um sistema dinâmico, é bastante comum que em uma mesma rota você precise tratar variáveis vindas da URL, geralmente conhecidas como parâmetros em muitos frameworks. Vamos explorar como fazer isso com LiveView.

## Router com parâmetros

Vamos construir um blog simples. Nele podemos acessar `/blog/qualquer_coisa` e ler sobre aquele assunto. Adicione a seguinte rota `live` no seu `router.ex`:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/", PageLive, :home
  live "/other", OtherPageLive, :other
  live "/blog/:slug", BlogLive, :index
end
```

Atualize sua `PageLive` para:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

E por fim, vamos adicionar a `BlogLive` em `lib/myapp_web/live/blog_live.ex`:

```elixir
defmodule MyappWeb.BlogLive do
  use MyappWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket = assign(socket, :slug, slug)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Reading about {@slug}</h1>
    """
  end
end
```

Aqui criamos uma rota `/blog/:slug` com uma variável no URL chamada `:slug`. Isso garante que a `BlogLive` receberá no primeiro argumento do callback `mount/3` um mapa no formato `%{"slug" => slug}` e você pode usar essa variável para criar um assign. Você pode usar os links adicionados na página inicial ou tentar URLs diferentes para `/blog/qualquer_coisa`.

%{
title: "Curiosidade",
description: ~H"""
Você está nesse site em uma rota <code>/guides/:id/:locale</code>. Veja o URL no seu navegador.
"""
} %% .callout

## Resumindo!

- O macro `live/4` deixa você criar parâmetros no URL usando o formato `:nome_da_variavel`.
- Qualquer parâmetro definido no router vira uma chave no mapa `params` na sua LiveView.