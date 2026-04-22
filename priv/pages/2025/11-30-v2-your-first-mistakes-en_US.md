%{
title: "Your first mistakes",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "Let's learn from mistakes",
previous_page_id: "v2-mounts-and-assigns",
next_page_id: "v2-events"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch mounts-and-assigns-done`</code>.
"""
} %% .callout

## Preparing for worst-case scenarios

Mistakes happen! Sometimes we type something wrong, sometimes we forget part of the code we already thought about writing. Although frustrating, exceptions in the code are there to help you. In this guide we will learn how to handle some of these exceptions so that when you experience them in real life you already know what to do. I chose these errors and decided to talk about them so early in this course because they are errors that LiveView beginners that I helped have experienced multiple times.

## I forgot to add an `assign`!

Let's go back to `page_live.ex` and forget to add an assign in `mount/3` but use it in `render/1`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    # Oops, forgot to assign this one
    # socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}
    """
  end
end

```

In production your user would be seeing an "Internal Server Error" and in your terminal several error lines should appear:

```elixir
[info] Sent 500 in 22ms
[error] ** (KeyError) key :name not found in:

    %{
      socket: #Phoenix.LiveView.Socket<
        id: "phx-GHzLG4kXVF0LYQUC",
        endpoint: MyappWeb.Endpoint,
        view: MyappWeb.PageLive,
        parent_pid: nil,
        root_pid: nil,
        router: MyappWeb.Router,
        assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
        transport_pid: nil,
        sticky?: false,
        ...
      >,
      __changed__: %{},
      flash: %{},
      live_action: :home
    }

    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:420: Phoenix.LiveView.Diff.traverse/6
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:146: Phoenix.LiveView.Diff.render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:291: Phoenix.LiveView.Static.to_rendered_content_tag/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:171: Phoenix.LiveView.Static.do_render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/controller.ex:39: Phoenix.LiveView.Controller.live_render/3
    (phoenix 1.8.1) lib/phoenix/router.ex:416: Phoenix.Router.__call__/5
    (myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
    (myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
    (myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
    (phoenix 1.8.1) lib/phoenix/endpoint/sync_code_reload_plug.ex:22: Phoenix.Endpoint.SyncCodeReloadPlug.do_call/4
    (bandit 1.8.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2
    (bandit 1.8.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5
    (bandit 1.8.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3
    (bandit 1.8.0) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3
    (bandit 1.8.0) lib/bandit/delegating_handler.ex:8: Bandit.DelegatingHandler.handle_continue/2
    (stdlib 7.0.1) gen_server.erl:2424: :gen_server.try_handle_continue/3
    (stdlib 7.0.1) gen_server.erl:2291: :gen_server.loop/4
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
```

Let's digest this message step by step! The first useful information here is precisely the first error line:

```elixir
[info] Sent 500 in 22ms
```

It indicates that the connection to your user's LiveView was suddenly terminated because the process containing the view died. In other words, it makes sense that the error is "Internal Server Error" because something was not handled by the programmer who created the LiveView. The next extremely important information is precisely the exception that caused your LiveView to die:

```elixir
[error] ** (KeyError) key :name not found in:

    %{
      socket: #Phoenix.LiveView.Socket<
        id: "phx-GHzLG4kXVF0LYQUC",
        endpoint: MyappWeb.Endpoint,
        view: MyappWeb.PageLive,
        parent_pid: nil,
        root_pid: nil,
        router: MyappWeb.Router,
        assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
        transport_pid: nil,
        sticky?: false,
        ...
      >,
      __changed__: %{},
      flash: %{},
      live_action: :home
    }
```

In Elixir a `KeyError` means that at a given moment you had a map and tried to access a key that does not exist in it such as `my_map.key_that_does_not_exist`. Recall that in our `render/1` we used `@name` which is the same as `assigns.name` it makes sense that it was a `KeyError`. To make the above error message even clearer, we can simplify it as:

```elixir
[error] ** (KeyError) key :name not found in:

    %{
      socket: #Phoenix.LiveView.Socket<>,
      __changed__: %{},
      flash: %{},
      live_action: :home
    }
```

Remember when we talked about what a `socket` has in the previous guide? They have `flash`, `__changed__` and `live_action`. Although the exception was not extremely obvious, we can interpret that this is the lack of an assign. But imagine that you have a giant LiveView project. How to find where this assign is missing? Let's look at the `stack trace`.

```elixir
(myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
(phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:420: Phoenix.LiveView.Diff.traverse/6
(phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:146: Phoenix.LiveView.Diff.render/4
(phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:291: Phoenix.LiveView.Static.to_rendered_content_tag/4
(phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:171: Phoenix.LiveView.Static.do_render/4
(phoenix_live_view 1.1.16) lib/phoenix_live_view/controller.ex:39: Phoenix.LiveView.Controller.live_render/3
(phoenix 1.8.1) lib/phoenix/router.ex:416: Phoenix.Router.__call__/5
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
(myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
(phoenix 1.8.1) lib/phoenix/endpoint/sync_code_reload_plug.ex:22: Phoenix.Endpoint.SyncCodeReloadPlug.do_call/4
(bandit 1.8.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2
(bandit 1.8.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5
(bandit 1.8.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3
(bandit 1.8.0) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3
(bandit 1.8.0) lib/bandit/delegating_handler.ex:8: Bandit.DelegatingHandler.handle_continue/2
(stdlib 7.0.1) gen_server.erl:2424: :gen_server.try_handle_continue/3
(stdlib 7.0.1) gen_server.erl:2291: :gen_server.loop/4
(stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
```

A `stack trace` demonstrates the chain of function calls until reaching the exception in your code (call stack). Each line has the format `(version_dependency_name) folder/file_name:line: ModuleName.function_name/arity`. Being able to read stack traces will make your day-to-day life as a programmer much simpler. Here's the first tip on how to find out where issue is: ignore all lines that are from libraries (those that start as parentheses and name is not your project). With that we are left with:

```elixir
(myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
# ...
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
(myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
```

Interpreting the trace we have left:

- In the file `lib/myapp_web/live/page_live.ex`.
- On line `12`.
- We have an anonymous function that takes two arguments (`anonymous fn/2`).
- Running inside the PageLive.render function that takes one argument (`PageLive.render/1`).

What is on line 12 of this file? `Hello {@name}`. Diagnosis: assigns `name` does not exist. Solution: add it to our `mount/3`:

```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, name: "Mundo")
  {:ok, socket}
end
```

%{
title: ~H"What was that <code>`anonymous fn/2`</code>?",
description: ~H"""
Remember that we use tags <code>`{}`</code> to interpolate code? Your <code>`@name`</code> is inside the anonymous interpolation function. This is something internal to LiveView, the important thing was to know the file + line + function information.
"""
} %% .callout

## Immutability

Let's update `page_live.ex` temporarily like this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}
    """
  end
end
```

Can you identify the error? Open your page. You will see the same `KeyError` that we talked about earlier. This time we assigned `name`, shouldn't it work?

To understand this problem we need to briefly talk about immutability. In Elixir you cannot modify variables. See the following example:

```elixir
person = %{name: "Lubien"}
Map.put(person, :name, "João")
dbg(person) # Still %{name: "Lubien"}
```

This happens because, unlike programming languages with mutable values (such as JavaScript), data in Elixir is immutable. You cannot modify an existing map but you can create a new map with something modified.

```elixir
person = %{name: "Lubien"}
person = Map.put(person, :name, "João")
dbg(person) # %{name: "João"}
```

In this case we create a second map and assign its value to the `person` identifier. If you modify data you will probably want to store the modification in the original or in another variable. Returning to our LiveView, the code with the problem is right here:

```elixir
assign(socket, name: "Immutable")
{:ok, socket}
```

The solution is quite simple. Just as Map.put returns a new map with the new data, the `assign/2` function returns a new socket with the added assign:

```elixir
socket = assign(socket, name: "Immutable")
{:ok, socket}
```

## In short

- If you see a `KeyError` saying that it was not possible to access a property of a map that has `live_action`, `socket` and `flash`, suspect that you forgot to assign it.
- Remember that Elixir is an immutable programming language so you need to store the result of function calls somewhere.
