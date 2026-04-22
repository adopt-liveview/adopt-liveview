%{
title: "Problematic events",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "What are common mistakes with events?",
previous_page_id: "v2-events",
next_page_id: "heex-is-not-html"
}

---

## Learning by making mistakes

A problem that happens a lot with people who are starting out in LiveView is an event that was not handled correctly. Let's learn how to debug this scenario. Comment your handle_event/3 like this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}

    <input type="button" value="Reverse" phx-click="reverse" />
    """
  end

  # def handle_event("reverse", _params, socket) do
  #   socket = assign(socket, name: String.reverse(socket.assigns.name))
  #   {:noreply, socket}
  # end
end
```

When clicking the button, from a UI point of view, we don't see anything other than a loading bar. But if you look in your terminal you will see something like this:

```elixir
debug] HANDLE EVENT "reverse" in MyappWeb.PageLive
  Parameters: %{"value" => "Reverse"}
[error] GenServer #PID<0.937.0> terminating
** (UndefinedFunctionError) function MyappWeb.PageLive.handle_event/3 is undefined or private
    (myapp 0.1.0) MyappWeb.PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-GH-g8OXkVBmy2AOC", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.937.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.929.0>, sticky?: false, ...>)
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:528: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.3.0) /Users/joaoferreira/workspace/adopt-liveview-apps/myapp/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:260: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 7.0.1) gen_server.erl:2434: :gen_server.try_handle_info/3
    (stdlib 7.0.1) gen_server.erl:2420: :gen_server.handle_msg/3
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
Process Label: {Phoenix.LiveView, MyappWeb.PageLive, "lv:phx-GH-g8OXkVBmy2AOC"}
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GH-g8OXkVBmy2AOC", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "12", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-GH-g8OXkVBmy2AOC", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.937.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.929.0>, sticky?: false, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-GH-g8OXkVBmy2AOC", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", fingerprints: {334685504655270794193411719397220261095, %{}}, redirect_count: 0, upload_names: %{}, upload_pids: %{}}
```

Elixir is excellent at telling us exactly what we're missing. At this point, the `UndefinedFunctionError` exception makes it clear that the problem is the lack of the `handle_event/3` callback in your `PageLive` LiveView. What if the problem was that we used the wrong event name? Uncomment your handle_event/3 but change the event name like this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}

    <input type="button" value="Reverse" phx-click="reverse" />
    """
  end

  def handle_event("wrong-reverse", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end
```

This time the exception is different. When you see `FunctionClauseError` the interpretation you should have is that the function exists but no case of it matched the message sent:

```elixir
[debug] HANDLE EVENT "reverse" in MyappWeb.PageLive
  Parameters: %{"value" => "Reverse"}
[error] GenServer #PID<0.691.0> terminating
** (FunctionClauseError) no function clause matching in MyappWeb.PageLive.handle_event/3
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:17: MyappWeb.PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-GH-hE0FkiPoKpgAJ", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.691.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.683.0>, sticky?: false, ...>)
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:528: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.3.0) /Users/joaoferreira/workspace/adopt-liveview-apps/myapp/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:260: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 7.0.1) gen_server.erl:2434: :gen_server.try_handle_info/3
    (stdlib 7.0.1) gen_server.erl:2420: :gen_server.handle_msg/3
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
Process Label: {Phoenix.LiveView, MyappWeb.PageLive, "lv:phx-GH-hE0FkiPoKpgAJ"}
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GH-hE0FkiPoKpgAJ", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "12", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-GH-hE0FkiPoKpgAJ", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.691.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.683.0>, sticky?: false, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-GH-hE0FkiPoKpgAJ", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", fingerprints: {334685504655270794193411719397220261095, %{}}, redirect_count: 0, upload_names: %{}, upload_pids: %{}}
```

To simplify your debugging, Elixir already shows exactly the message you received. Let's clear the exception and focus just on the first line of the error message:

```elixir
[error] GenServer #PID<0.691.0> terminating
** (FunctionClauseError) no function clause matching in MyappWeb.PageLive.handle_event/3
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:17: MyappWeb.PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-GH-hE0FkiPoKpgAJ", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.691.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.683.0>, sticky?: false, ...>)
```

Look, it says that your LiveView received "reverse" as its first parameter. Checking your LiveView code we noticed that your callback expected `"wrong-reverse"`. This is the problem.

## Recap!

- If you forget to do your `handle_event/3` the LiveView will show the error `UndefinedFunctionError`.
- If you have the callback but do not handle the received case you will see a `FunctionClauseError`.
- Knowing how to interpret these errors in your terminal will help you unlock a new level of debugging in Elixir projects.
