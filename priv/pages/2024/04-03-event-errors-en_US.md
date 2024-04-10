%{
title: "Problematic events",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "What are common mistakes with events?",
previous_page_id: "events",
next_page_id: "heex-is-not-html"
}

---

## Learning by making mistakes

A problem that happens a lot with people who are starting out in LiveView is an event that was not handled correctly. Let's learn how to debug this scenario. Create a file called `event_error.exs` with the following code and run it:

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

      <input type="button" value="Reverse" phx-click="reverse" >
    </div>
    """
  end
end

LiveviewPlayground.start()
```

When clicking the button, from a UI point of view, we don't see anything! But if you look in your terminal you will see something like this:

%{
title: "Is this the LiveView error UX?!",
description: ~H"""
In this example the user does not have any feedback about the error occurring but the reason is that the <code>liveview_playground</code> library does not (yet) come with the same level of error handling that the full Phoenix contains. In a real LiveView project the user would have feedback with loaders and toasts by default and you can modify them to anything your imagination wants.
"""
} %% .callout

```elixir
08:05:41.576 [error] GenServer #PID<0.377.0> terminating
** (UndefinedFunctionError) function PageLive.handle_event/3 is undefined or private
    PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-F8CaUkZ7G3XHVAAG", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.377.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.371.0>, ...>)
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:401: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.2.1) /Users/lubien/Library/Caches/mix/installs/elixir-1.16.1-erts-14.2.2/df7edc454f95eaecd33200718b6c458a/deps/telemetry/src/telemetry.erl:321: :telemetry.span/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:221: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 5.2) gen_server.erl:1095: :gen_server.try_handle_info/3
    (stdlib 5.2) gen_server.erl:1183: :gen_server.handle_msg/6
    (stdlib 5.2) proc_lib.erl:241: :proc_lib.init_p_do_apply/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-F8CaUkZ7G3XHVAAG", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "8", join_ref: "7"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-F8CaUkZ7G3XHVAAG", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.377.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.371.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-F8CaUkZ7G3XHVAAG", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "7", upload_names: %{}, upload_pids: %{}}
```

Elixir is excellent at telling us exactly what we're missing. At this point, the `UndefinedFunctionError` exception makes it clear that the problem is the lack of the `handle_event/3` callback in your `PageLive` LiveView. What if the problem was that we used the wrong event name? Create a new file called `event_typo.exs` with the following code and run it:

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

      <input type="button" value="Reverse" phx-click="reverse" >
    </div>
    """
  end

  def handle_event("reverse", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

This time the exception is different. When you see `FunctionClauseError` the interpretation you should have is that the function exists but no case of it matched the message sent:

```elixir
08:09:52.096 [error] GenServer #PID<0.379.0> terminating
** (FunctionClauseError) no function clause matching in PageLive.handle_event/3
    priv/examples/event-errors/event_typo.exs:23: PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-F8CajZ4frvLvugAB", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.379.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.377.0>, ...>)
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:401: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.2.1) /Users/lubien/Library/Caches/mix/installs/elixir-1.16.1-erts-14.2.2/df7edc454f95eaecd33200718b6c458a/deps/telemetry/src/telemetry.erl:321: :telemetry.span/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:221: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 5.2) gen_server.erl:1095: :gen_server.try_handle_info/3
    (stdlib 5.2) gen_server.erl:1183: :gen_server.handle_msg/6
    (stdlib 5.2) proc_lib.erl:241: :proc_lib.init_p_do_apply/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-F8CajZ4frvLvugAB", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "6", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-F8CajZ4frvLvugAB", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.379.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.377.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-F8CajZ4frvLvugAB", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", upload_names: %{}, upload_pids: %{}}
```

To simplify your debugging, Elixir already shows exactly the message you received. Let's clear the exception and focus just on the first line of the error message:

```elixir
08:09:52.096 [error] GenServer #PID<0.379.0> terminating
** (FunctionClauseError) no function clause matching in PageLive.handle_event/3
    priv/examples/event-errors/event_typo.exs:23: PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<>)
```

Note that it says that your LiveView received "reverse" as its first parameter. Checking your LiveView code we noticed that your callback expected `"reverse"`. This is the problem.

## In short!

- If you forget to do your `handle_event/3` the LiveView will show the error `UndefinedFunctionError`.
- If you have the callback but do not handle the received case you will see a `FunctionClauseError`.
- Knowing how to interpret these errors in your terminal will help you unlock a new level of debugging in Elixir projects.
