%{
title: "Navegando para a mesma rota",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "A mesma LiveView pode ser mais de uma rota",
previous_page_id: "query-string",
next_page_id: "function-component"
}

---

Às vezes pode ser útil uma LiveView ser usada em mais de uma rota. Vamos recapitular o sistema de rotas feito em uma aula anterior:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

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
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Apesar de simples e funcionar corretamente esse sistema tinha um problema de UX: se você reiniciar a página você volta para a aba inicial. Podemos resolver isso salvando a aba atual no URL. Deste modo, se a página for atualizada conseguimos ler o URL e aplicar a aba atual. Crie e execute um arquivo chamado `tab_param.exs`:

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

    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

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

LiveviewPlayground.start(router: CustomRouter)
```

Para poder adicionar parâmetros a nossa routa criamos mais uma vez um Router customizado que mapeia `/tab/:tab` para nossa LiveView `TabLive` portanto acesse [http://localhost:4000/tab/home](http://localhost:4000/tab/home) para ver sua aplicação. Vale mencionar que usamos desta vez a Live Action :show pois estamos mostrando um único item em cada aba.

Como estamos trabalhando agora com rotas os botões foram trocados por componentes de `<.link>`. Alem disso, o nosso mount recebe o valor inicial da aba dos `params`.

## Parâmetro de rota opcional

Você deve ter notado que criamos uma experiência ruim para usuarios novos pois a página inicial não existe e o usuário é forçado a escrever `/tab/home`. Podemos resolver isso deixando nosso `mount/3` tratar o `param` de aba de uma forma diferentee uma nova rota. Crie e execute `tab_param_optional.exs`:

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

    live "/", TabLive, :show
    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

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

LiveviewPlayground.start(router: CustomRouter)
```

Basta adicionar uma nova rota usando a mesma LiveView e mudar a forma com que tratamos os `params` que nossa `TabLive` se torna capaz de ser usada em um contexto com ou sem parâmetro de rota! Vale notar que modificamos nosso `<.link>` da Home para enviar para `/` porém `/tab/home` também funciona normalmente.

## Otimizando navegação na mesma LiveView

Quando você usa `<.link navigate={...}>` o LiveView entende que você está mudando de uma LiveView para outra diferente e precisa criar um novo contexto. Se você souber de antemão que uma transição vai para a mesma LiveView você pode usar a alternativa `<.link patch={...}>` e a modificação entre a rota será mínima. Para isso funcionar corretamente precisamos introduzir um novo callback chamado `handle_params/3`. Crie e execute um arquivo `tab_param_patch.exs`:

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

    live "/", TabLive, :show
    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

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

LiveviewPlayground.start(router: CustomRouter)
```

O callback `handle_params/3` é muito parecido com o `mount/3` exceto que o segundo argumento contém o URI da página atual e o retorno deve ser `{:noreply, socket}`.

Uma coisa chata no momento é o fato que temos código duplicado entre nosso `mount/3` e `handle_params/3`. Felizmente existe uma solução muito simples para isso. Sempre que uma LiveView é instanciada pelo Phoenix pela primeira vez ela executa o `mount/3` se ele existir e, em seguida, o `handle_params/3` se ele existir. Deste modo podemos remover o `mount/3` completamente. Crie e execute um arquivo chamado `tab_param_patch_refactor.exs`:

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

    live "/", TabLive, :show
    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

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

LiveviewPlayground.start(router: CustomRouter)
```

Deste modo conseguimos otimizar a troca entre a mesma LiveView por simplesmente fazer links usarem o atributo `patch` e mudar de `mount/3` para `handle_params/3`.

%{
title: "Devo sair otimizando todas as rotas então?",
description: ~H"""
Otimização precoce é terrível. Se você identificar uma LiveView que queira otimizar, vá em frente. Se não quiser se preocupar com isso simplesmente use <code>`navigate`</code> em todos os seus componentes <code>`.link`</code>.
"""
} %% .callout

## Resumindo!

- Uma LiveView pode ser usada em mais de uma rota.
- Podemos nos aproveitar de URL para persistir dados em casos como abas.
- O `handle_params/3` é um callback que é executado logo após o `mount/3`.
- Uma forma de de otimizar trocas de página para a mesma LiveView é usar `patch` nos links.
- Usando `patch` nós executamos o `handle_params/3`.
