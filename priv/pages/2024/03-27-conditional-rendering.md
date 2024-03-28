%{
title: "Renderização condicional",
author: "Lubien",
tags: ~w(getting-started),
section: "Estruturas de Controle",
description: "Renderizar ou não renderizar, eis a questão"
}

---

Vamos aprender algumas formas de renderizar HTML dependendo de certas condições. Crie e execute um arquivo chamado `toggle.exs`:

## Usando `if-else` para casos simples

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% else %>
        <p>You can't see this message!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Vamos destrinchar este código. O único assign que temos aqui se chama `show_information?` com valor inicial de falso. O evento `"toggle"` enviado pelo input simplesmente reverte o valor entre `true` e `false`. O que realmente é novo aqui é nosso bloco de `if-else`.

%{
title: "Interrogação no meio do código? Pode isso, Arnaldo?",
description: ~H"""
Em Elixir a interrogação é válida em átomos e variáveis quando adicionada no final. Isso é bem útil para denotar booleanos. Vai dizer que <code>`if @show_information?`</code> não fica elegante?
"""
} %% .callout

Dentro de uma LiveView você pode fazer um `if-else` da seguinte maneira:

- Adicione um `<%= if condition do %>`. É importante você usar a tag que contém `=` senão o HEEx vai entender que isso não deve ser renderizado!
- Escreva qualquer HTML que estará no caso que deve ser renderizado.
- Adicione um `<% else %>`. Note que não há um `=` desta vez. Se você adicionar ele o código continua a funcionar porém um warning lhe avisará para removê-lo.
- Escreva qualquer HTML para o caso `else`.
- Adicione um `<% ende %>`. Mais uma vez, sem `=`.

Se você não desejar mostrar um caso de `else` existem dua maneiras de fazer isso. A primeira é simples: apenas remova o `<% else %>` e o conteúdo dele! Crie e execute um arquivo chamado `toggle_without_else.ex`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

## O atributo especial `:if`

Para casos em que você só possui o `if` o HEEx possui um atributo especial chamado `:if` em que você pode colocar diretamente na tag HTML. Crie e execute um arquivo chamado `toggle_special_if.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={@show_information?}>You're an amazing person!</p>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

No momento não existe um attributo especial para `else` então como recomendação se você precisa apenas de `if` é recomendado usar `:if` se você puder colocar em uma tag pai das coisas que entram na condição, caso contrário utilize o primeiro exemplo com `if-else` demonstado aqui.

## Usando `case` para casos complexos

É só uma questão de tempo até você chegar em uma situação em que existe mais de duas possibilidades de renderizar algo. Elixir não possui suporte para `else if` e com motivo: a preferência é `case` que é muito mais poderoso!

Vamos criar um sistema simples de abas em LiveView. Crie e execute um arquivo chamado `case.exs`:

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

Desta vez nosso assign virou `tab`
