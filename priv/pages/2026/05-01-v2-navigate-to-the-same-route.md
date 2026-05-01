%{
title: "Navegando para a mesma rota",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "A mesma LiveView pode ter mais de uma rota",
previous_page_id: "v2-query-string",
next_page_id: "v2-function-component"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch query-string-done-done`</code>.
"""
} %% .callout

Às vezes pode ser útil uma LiveView ser usada em mais de uma rota. Vamos recapitular o sistema de rotas criado em uma aula anterior:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    <input disabled={@tab == "blog"} type="button" value="Open Blog" phx-click="show_blog" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end
```

Apesar de simples e funcionar corretamente, esse sistema tinha um problema de UX: se você reiniciar a página, volta para a aba inicial. Podemos resolver isso salvando a aba atual na URL. Desse modo, se a página for atualizada, conseguimos ler a URL e aplicar a aba atual. Atualize o `router.ex` assim:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/tab/:tab", PageLive, :show
  live "/other", OtherPageLive, :other
  live "/blog/:slug", BlogLive, :index
end
```

Em seguida, atualize também a `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(%{"tab" => tab}, _session, socket) do
    socket = assign(socket, tab: tab)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} navigate={~p"/tab/home"}>Go to home</.link>
    <.link :if={@tab != "about"} navigate={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} navigate={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end
```

Para poder adicionar parâmetros à nossa rota, criamos mais uma vez uma rota `live` que mapeia `/tab/:tab` para nossa LiveView `PageLive`. Acesse [http://localhost:4000/tab/home](http://localhost:4000/tab/home) para ver sua aplicação. Vale mencionar que usamos a Live Action `:show` desta vez, pois estamos mostrando um único item em cada aba.

Como agora estamos trabalhando com rotas, os botões foram substituídos por componentes `<.link>`. Nosso `mount/3` recebe o valor inicial da aba dos `params`.

## Parâmetro de rota opcional

Você deve ter notado que criamos uma experiência ruim para usuários novos, pois a página inicial não existe e o usuário é forçado a digitar `/tab/home`. Podemos resolver isso deixando nosso `mount/3` tratar o `param` de aba de uma forma diferente e também criando uma nova rota. Atualize seu `router.ex`:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/", PageLive, :show
  live "/tab/:tab", PageLive, :show
  live "/other", OtherPageLive, :other
  live "/blog/:slug", BlogLive, :index
end
```

E sua `PageLive` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(params, _session, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} navigate={~p"/"}>Go to home</.link>
    <.link :if={@tab != "about"} navigate={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} navigate={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end
```

Basta adicionar uma nova rota usando a mesma LiveView e mudar a forma com que tratamos os `params` para que nossa `PageLive` se torne capaz de ser usada em um contexto com ou sem parâmetro de rota! Vale notar que modificamos nosso `<.link>` da Home para enviar para `/`; porém, `/tab/home` também funciona normalmente.

## Otimizando a navegação na mesma LiveView

Quando você usa `<.link navigate={...}>`, o LiveView entende que você está mudando de uma LiveView para outra diferente e precisa criar um novo contexto. Se você souber de antemão que uma transição vai para a mesma LiveView, pode usar a alternativa `<.link patch={...}>` e a mudança entre rotas será ainda mais otimizada. Para isso funcionar corretamente, precisamos introduzir um novo callback chamado `handle_params/3`. Atualize seu arquivo `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(params, _session, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} patch={~p"/"}>Go to home</.link>
    <.link :if={@tab != "about"} patch={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} patch={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end
```

O callback `handle_params/3` é muito parecido com o `mount/3`, exceto que o segundo argumento contém o URI da página atual e o retorno deve ser `{:noreply, socket}`.

Uma coisa chata no momento é o fato de termos código duplicado entre nosso `mount/3` e `handle_params/3`. Felizmente, existe uma solução muito simples para isso. Sempre que uma LiveView é inicializada pelo Phoenix pela primeira vez, ela executa o `mount/3` se ele existir e, em seguida, o `handle_params/3` se ele existir. Desse modo, podemos remover o `mount/3` completamente. Atualize a `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} patch={~p"/"}>Go to home</.link>
    <.link :if={@tab != "about"} patch={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} patch={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end
```

Agora conseguimos otimizar a navegação entre a mesma LiveView simplesmente fazendo os links usarem o atributo `patch` e trocando de `mount/3` para `handle_params/3`.

%{
title: "Devo otimizar todas as rotas então?",
description: ~H"""
Otimização precoce é terrível. Se você identificar uma LiveView que queira otimizar, vá em frente. Se não quiser se preocupar com isso, simplesmente use <code>`navigate`</code> em todos os seus componentes <code>`.link`</code>.
"""
} %% .callout

## Resumindo!

- Uma LiveView pode ser usada em mais de uma rota.
- Podemos nos aproveitar de URLs para persistir dados em casos como abas.
- `handle_params/3` é um callback que é executado logo após o `mount/3`.
- Uma forma de otimizar trocas de página para a mesma LiveView é usar `patch` nos componentes `<.link>`.
- Usando `patch` nós executamos o `handle_params/3`.