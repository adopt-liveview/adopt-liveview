%{
title: "JS.push/1",
author: "Lubien",
tags: ~w(getting-started),
section: "Events",
description: "How to send data with events in an alternative way",
previous_page_id: "v2-phx-value",
next_page_id: "v2-multiple-pushes"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

In the previous lesson we learned how to use the `phx-value-*` binding to pass values into an event. To recap:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
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
```

However, we talked about how values will be sent strictly as a strings. LiveView also has an alternative way to push events called [`JS.push/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#push/2) which is part of the so-called JS Commands. Update your `page_live.ex` to use `JS.push/2`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
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
```

We simplified our LiveView by using `JS.push/2` directly in the `phx-click` binding and defining that we are pushing the `"add"` event and the value will be `%{amount: INTEGER}`. This `phx-click` will be serialized as JSON so that when the button is clicked the `amount` will be an integer as expected.

## Extra tip: using loops to prevent duplicated code

We could avoid some code duplication by using a simple `:for`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
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

    <input
      :for={value <- [5, 10, -5, -10]}
      type="button"
      value={"Add #{value}"}
      phx-click={JS.push("add", value: %{amount: value})}
    />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end
```

This tip also works for the previous class with `phx-value-amount`. Take it as a home assignment to try out how to do this with the previous lesson code.

## Recap!

- Using JS Commands we can switch from a combo of `phx-click` + `phx-value-*` bindings for just one `phx-click` binding containing a `JS.push/2`.
- `JS.push/2` simplifies the serialization of data that is not strings in values because integers are part of what JSON supports so the pushed data will be an integer as expected.