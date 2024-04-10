%{
title: "phx-value",
author: "Lubien",
tags: ~w(getting-started),
section: "Eventos",
description: "Como passar dados com eventos",
previous_page_id: "list-rendering",
next_page_id: "js-push"
}

---

Em aulas anteriores apenas vimos como disparar eventos. Na aula de renderização condicional com `cond` nós vimos o seguinte código:

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

    <input type="button" value="Increase" phx-click="increase" />
    <input type="button" value="Decrease" phx-click="decrease" />
    """
  end

  def handle_event("increase", _params, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + 10)
    {:noreply, socket}
  end
  def handle_event("decrease", _params, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius - 10)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Nosso código sempre aumentava ou diminuia a temperatura em 10 graus. E se quisessemos opções de aumentar em valores diferentes? Teríamos que ter um evento para cada caso? Vamos conhecer o binding `phx-value`. Crie e execute o arquivo `phx_value.exs`:

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

Desta vez substituímos os eventos `"increase"` e `"decrease"` por um evento genérico chamado `"add"` que recebe um `phx-value-amount` que é um número. De modo equivalente o seu `handle_event/3` recebe como segundo parâmetro o `%{"amount" => "+10"}` dependendo do botão clicado. É importante notar que os parâmetros vindo do HTML sempre vem em formato de string (pois atributos HTML são strings) então devemos converter o número antes de fazer a soma.

## Resumindo

- O binding `phx-value-*` pode ajudar a generalizar um evento para ele ser reutilizável.
- O dado que você recebe no `handle_event/3` é equivalente ao nome do binding do HEEx: `phx-value-test` gera `%{"test" => value}`.
- Valores vindos de um binding `phx-value-*` são obrigatoriamente strings.
