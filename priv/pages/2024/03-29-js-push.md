%{
title: "JS.push/1",
author: "Lubien",
tags: ~w(getting-started),
section: "Eventos",
description: "Como passar dados com eventos de uma maneira alternativa",
previous_page_id: "phx-value",
next_page_id: "multiple-pushes"
}

---

Na aula anterior nós aprendermos a usar o binding `phx-value-*` para passar valores em um evento. Recapitulando:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: <%= @temperature_celsius %>C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="+5" phx-click="add" phx-value-amount={+5} />
    <input type="button" value="+10" phx-click="add" phx-value-amount={+10} />
    <input type="button" value="-5" phx-click="add" phx-value-amount={-5} />
    <input type="button" value="-10" phx-click="add" phx-value-amount={-10} />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    amount = String.to_integer(amount)
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Porém comentamos a limitação de que o valor vai ser enviado estritamente como string. Para nos ajudar o LiveView também tem uma alternativa chamada [`JS.push/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#push/2) que faz parte dos chamado JS Commands. Escreva e execute o arquivo `js_push.exs`:

```elixir

Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: <%= @temperature_celsius %>C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="+5" phx-click={JS.push("add", value: %{amount: +5})} />
    <input type="button" value="+10" phx-click={JS.push("add", value: %{amount: +10})} />
    <input type="button" value="-5" phx-click={JS.push("add", value: %{amount: -5})} />
    <input type="button" value="-10" phx-click={JS.push("add", value: %{amount: -10})} />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Podemos simplificar nossa LiveView por utilizar o `JS.push/2` diretamente no binding `phx-click` e definir que estamos fazendo push do evento `"add"` e o valor será `%{amount: INTEIRO}`. Este `phx-click` será serializado em JSON de modo que quando o botão for clicado o valor já irá do jeito que você espera: `amount` como inteiro.

## Dica extra: usando loops para duplicar código

Poderíamos evitar um pouco de duplicação de código usando um simples `:for`:

```elixir

Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: <%= @temperature_celsius %>C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input :for={value <- [5, 10, -5, -10]} type="button" value={"Add #{value}"} phx-click={JS.push("add", value: %{amount: value})} />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Esta dica também funciona para a aula anterior com `phx-value-amount`, fica como dever de casa você experimentar como fazer isso.

## Resumindo!

- Usando JS Commands podemos trocar um combo dos bindings `phx-click` + `phx-value-*` por apenas um binding `phx-click` contendo um `JS.push/2`.
- `JS.push/2` facilita a serialização de dados que não são strings no valor pois inteiros fazem parte do que JSON suporta então no disparo de evento o dado no formato inteiro é enviado.
