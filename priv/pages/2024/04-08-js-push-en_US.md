%{
title: "JS.push/1",
author: "Lubien",
tags: ~w(getting-started),
section: "Events",
description: "How to pass data with events in an alternative way",
previous_page_id: "phx-value",
next_page_id: "multiple-pushes"
}

---

In the previous class we learned how to use the `phx-value-*` binding to pass values into an event. To recap:

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

However, we commented on the limitation that the value will be sent strictly as a string. To help us, LiveView also has an alternative called [`JS.push/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#push/2) which is part of the so-called JS Commands. Write and run the `js_push.exs` file:

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

We can simplify our LiveView by using `JS.push/2` directly in the `phx-click` binding and defining that we are pushing the `"add"` event and the value will be `%{amount: INTEGER}`. This `phx-click` will be serialized in JSON so that when the button is clicked the value will be as you expect: `amount` as an integer.

## Extra Tip: Using Loops to Duplicate Code

We could avoid some code duplication by using a simple `:for`:

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

This tip also works for the previous class with `phx-value-amount`, it's your homework to try out how to do this.

## Recap!

- Using JS Commands we can exchange a combo of the `phx-click` + `phx-value-*` bindings for just one `phx-click` binding containing a `JS.push/2`.
- `JS.push/2` facilitates the serialization of data that is not strings in value because integers are part of what JSON supports, so in the event trigger the data in integer format is sent.
