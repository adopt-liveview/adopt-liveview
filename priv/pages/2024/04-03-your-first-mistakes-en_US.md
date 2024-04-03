%{
title: "Your first mistakes",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "Let's learn from mistakes"
}

---

## Preparing for worst-case scenarios

Mistakes happen! Sometimes we type something wrong, sometimes we forget part of the code we already thought about writing. Although frustrating, exceptions in the code are there to help you. In this guide we will learn how to handle some of these exceptions so that when you experience them in real life you are already protected. I chose these errors and decided on them so early in the classes because they are errors that the LiveView beginners that I helped have experienced multiple times.

## I forgot to add an `assign`!

Let's create a LiveView and forget to add an assign in `mount/3` but we will use it in `render/1`. Let's create a file called `missing_assign.exs` and run it:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello <%= @name %>
    """
  end
end

LiveviewPlayground.start()
```

In your browser you should be seeing an "Internal Server Error" and in your terminal several error lines are appearing:

```elixir
08:32:27.589 [error] #PID<0.374.0> running LiveviewPlayground.Endpoint (connection #PID<0.372.0>, stream id 2) terminated
Server: localhost:4000 (http)
Request: GET /
** (exit) an exception was raised:
    ** (KeyError) key :name not found in: %{
  socket: #Phoenix.LiveView.Socket<
    id: "phx-F7_-oDyLb_kqfgAD",
    endpoint: LiveviewPlayground.Endpoint,
    view: PageLive,
    parent_pid: nil,
    root_pid: nil,
    router: LiveviewPlayground.Router,
    assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
    transport_pid: nil,
    ...
  >,
  __changed__: %{},
  flash: %{},
  live_action: :index
}
        priv/examples/your-first-mistakes/missing_assign.exs:14: anonymous fn/2 in PageLive.render/1
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:398: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
        (elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:396: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:252: Phoenix.LiveView.Static.to_rendered_content_tag/4
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:135: Phoenix.LiveView.Static.render/3
```

Let's digest this message step by step! The first useful information here is precisely the first error line:

```elixir
08:32:27.589 [error] #PID<0.374.0> running LiveviewPlayground.Endpoint (connection #PID<0.372.0>, stream id 2) terminated
```

It indicates that the connection to your user's LiveView was suddenly terminated because the process containing the view died. In other words, it makes sense that the error is "Internal Server Error" because something was not handled by the programmer who created the LiveView. The next extremely important information is precisely the exception that caused your LiveView to die (that is, cause an `exit`):

```elixir
** (exit) an exception was raised:
    ** (KeyError) key :name not found in: %{
  socket: #Phoenix.LiveView.Socket<
    id: "phx-F7_-oDyLb_kqfgAD",
    endpoint: LiveviewPlayground.Endpoint,
    view: PageLive,
    parent_pid: nil,
    root_pid: nil,
    router: LiveviewPlayground.Router,
    assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
    transport_pid: nil,
    ...
  >,
  __changed__: %{},
  flash: %{},
  live_action: :index
}
```

In Elixir a `KeyError` means that at a given moment you had a map and tried to access a key that does not exist in it in the format `mapa.chave_inexistente`. Remembering that in our `render/1` we made `@name` which is the same as `assigns.name` it makes sense that it was a `KeyError`. To make the above error message even clearer, we can simplify it as:

```elixir
** (exit) an exception was raised:
    ** (KeyError) key :name not found in: %{
  socket: %Phoenix.LiveView.Socket{},
  __changed__: %{},
  flash: %{},
  live_action: :index
}
```

Remember when we talked about what a `socket` has in the previous class? They have `flash`, `__changed__` and `live_action`. Although the exception was not extremely obvious, we can interpret that this is the lack of an assign. But imagine that you have a giant LiveView project. How to find where this assign is missing? Let's look at the `stack trace`.

```elixir
priv/examples/your-first-mistakes/missing_assign.exs:14: anonymous fn/2 in PageLive.render/1
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:398: Phoenix.LiveView.Diff.traverse/7
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
(elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:396: Phoenix.LiveView.Diff.traverse/7
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
(phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:252: Phoenix.LiveView.Static.to_rendered_content_tag/4
(phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:135: Phoenix.LiveView.Static.render/3
```

A `stack trace` serves to demonstrate the chain of function execution until reaching the exception in your code. Each line has the format `(version_dependency_name) folder/file_name:line: ModuleName.function_name/arity`. Being able to read stack traces will make your day-to-day life as a programmer much simpler. Here's the first tip on how to find out where the code problem is: ignore all lines that are from libraries (those that start as parentheses). With that we are left with:

```elixir
priv/examples/your-first-mistakes/missing_assign.exs:14: anonymous fn/2 in PageLive.render/1
```

Interpreting the trace we have left:

- In the file `priv/examples/your-first-mistakes/missing_assign.exs`.
- On line `14`.
- We have an anonymous function that takes two arguments (`anonymous fn/2`).
- Running inside the PageLive.render function that takes one argument (`PageLive.render/1`).

What is on line 14 of this file? `Hello <%= @name %>`. Diagnosis: assigns `name` does not exist. Solution: add it to our `mount/3`:

```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, name: "Mundo")
  {:ok, socket}
end
```

%{
title: ~H"What was that <code>`anonymous fn/2`</code>?",
description: ~H"""
Remember that we use tags <code>`&lt;%= %&gt;`</code> to interpolate code? Your <code>`@name`</code> is inside the anonymous interpolation function. This is something internal to LiveView, the important thing was to know the file + line + function.
"""
} %% .callout

## Immutability

Let's create a new file called `immutable.exs` like this:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    assign(socket, name: "Immutable")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello <%= @name %>
    """
  end
end

LiveviewPlayground.start()
```

Can you identify the error? Run the file with `elixir immutable.exs` and open your page. You will see the same `KeyError` that we talked about earlier. This time we assigned `name`, shouldn't it work?

To understand this problem we need to briefly talk about immutability. In Elixir you cannot modify variables. See the following example:

```elixir
person = %{name: "Lubien"}
Map.put(person, :name, "João")
dbg(person) # Continua %{name: "Lubien"}
```

This happens because, unlike programming languages with mutable values (such as JavaScript), data in Elixir is immutable. You cannot modify an existing map but you can create a new map with a certain modification.

```elixir
person = %{name: "Lubien"}
person = Map.put(person, :name, "João")
dbg(person) # %{name: "João"}
```

In this case, we create a second map and assign this value to the `person` identifier. If you modify data, you will probably want to store the modification in the original or in another. Returning to our LiveView, the code with the problem is right here:

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
