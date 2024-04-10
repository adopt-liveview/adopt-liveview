%{
title: "Modifying state with events",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "How to manage state using events",
previous_page_id: "your-first-mistakes",
next_page_id: "event-errors"
}

---

## Welcome to the dynamic world

In a modern front-end framework you don't want a view that shows something and is never modified again. We will learn the first way to modify state in LiveView: events.

We're going to build a simple button that reverses the current user's name. Create an `events.exs` file with the following code:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Hello <%= @name %>

      <input type="button" value="Reverse" >
    </div>
    """
  end
end

LiveviewPlayground.start()
```

We don't have anything very different here except the button. So far just basic HTML. Let's do some magic now. Edit the input and add a handle_event as in the code below:

```elixir
defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Hello <%= @name %>

      <input type="button" value="Reverse" phx-click="reverse" >
    </div>
    """
  end

  def handle_event("reverse", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end
```

With this small modification we see the first example of reactivity in Phoenix: `phx-click`. When clicked, this input generates an event for your LiveView with the name you chose, in this case `"reverse"`. Run the server one more time and see that when you click the button, your name is reverted!

## How do they work?

Let's talk about [`handle_event/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_event/3). This function is a callback that is only necessary if your LiveView has an event. For each event in your HTML code you need a `def handle_event("your_event", _params, socket) of the corresponding `. The three arguments that this callback receives are, respectively:

%{
title: "Reminder about callbacks!",
description: ~H"""
Callbacks are simply functions that are executed when a certain thing happens.
"""
} %% .callout

- The name of the event you defined.
- Event parameters (we will explore more in another class, at the moment we are just ignoring this argument).
- The state of the Socket for the current user.

Just like the `mount/3` callback you receive the `socket` so you can modify it however you want. The expected return of the function is `{:noreply, socket}`.

%{
title: ~H"<code>:ok</code> or <code>:noreply</code>?",
description: ~H"""
You must be wondering why in the callback <code>`mount/3`</code> we respond with <code>`{:ok, socket}`</code> while in <code>`handle_event/3`</code> we use <code>`{:noreply, socket}`</code>. <br><br>O <code>`mount/3`</code> It's just a function that LiveView executes while it's preparing its view, so it follows the Elixir pattern of saying "everything is OK, here's the initial socket". <br><br>Already <code>`handle_event/3`</code> internally uses an Erlang/Elixir standard called <code>`GenServer`</code> ("Generic Server") and in the future we will see that we can also return a value for the element that generated the event with <code>`{:reply, map(), socket}`</code>!
"""
} %% .callout

## In short!

- By adding `phx-click="nome_do_evento"` to an element you trigger an event when the button is clicked.
- For each event in your HTML you need an equivalent `handle_event("event_name", _params, socket)` callback.
- The `mount/3` callback returns `{:ok, socket}` while the `handle_event/3` returns `{:noreply, socket}`.
