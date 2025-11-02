%{
title: "LiveView Assigns",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "How do variables work in LiveView?",
previous_page_id: "explain-playground",
next_page_id: "your-first-mistakes"
}

---

## Storing state

A very important feature of a frontend framework is being able to store the state of the current application. ReactJS uses hooks, VueJS uses composition/options API and so on. In LiveView we call the state of a view `assigns` (plural form).

`assigns` are just an Elixir map. You can store in the `assigns` map everything that you could store in any variable: lists, maps, structs, etc.

A great place to write `assigns` when your LiveView is generated is in a `callback` called `mount/3`.

Let's create a file called `assigns.exs`:

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
    Hello <%= @name %>
    """
  end
end

LiveviewPlayground.start()
```

Start the server as `elixir assigns.exs` and see the result.

If you're feeling desperate right now, don't be. I know 7 new things were added in just 5 new lines of code compared to `hello_liveview.exs` but let's break down these modifications one at a time!

## The `mount/3` callback

The way in which the LiveView framework sends information so that programmers can process the data is through callbacks. These are nothing more than functions that run when something happens. The `mount/3` callback runs when your LiveView is initialized. Its three arguments are, respectively:

- Parameters coming from the URL. Useful for routes like `/users/:id` where `:id` would be one of the parameters.
- Data from the current browsing session (if configured). Useful for authentication.
- Data from the current connection with the user accessing this LiveView in a data structure called [Phoenix.LiveView.Socket](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Socket.html), better known simply as `socket`.

The first two arguments will be explored in more detail in future guides. Right now we will just ignore them for the sake of simplicity.

## The %Socket{} data structure

Let's get straight to the point: LiveView state management completely revolves around modifying the state of your socket. The function [`assign/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#assign/2) receives your `socket` and the assigns you want to add and applies them generating a new socket. Let's try! Update your code as follows:

```elixir
def mount(_params, _session, socket) do
  socket.assigns |> dbg
  socket = assign(socket, name: "Lubien")
  socket.assigns |> dbg
  {:ok, socket}
end
```

Don't forget to turn the server off and on again to see the changes.

%{
title: ~H"<code>`dbg/2`</code>",
description: ~H"""
The <.link navigate="https://hexdocs.pm/elixir/debugging.html#dbg-2" target="\_blank"><code>`dbg/2`</code></.link> macro is extremely useful for debugging code and we will be using it a lot during classes. In general, it will be used by adding a `pipe` to it like <code>`|> dbg`</code>. It tells you the file name, line, function and variables of the thing you are debugging. Super powerful.
"""
} %% .callout

If you check your terminal you will see information like this:

```elixir
[priv/examples/mount-and-assigns/assigns.exs:9: PageLive.mount/3]
socket.assigns #=> %{__changed__: %{}, flash: %{}, live_action: :index}

[priv/examples/mount-and-assigns/assigns.exs:11: PageLive.mount/3]
socket.assigns #=> %{name: "Lubien", __changed__: %{name: true}, flash: %{}, live_action: :index}
```

As we can see, assigns are just a map with some data about your LiveView. Explaining each one:

- `__changed__`: is a map that LiveView automatically populates when something changes in order to explain to its HTML rendering engine which properties need to be updated to generate the final HTML in an efficient way.
- `flash`: is a map used to send information, success and alert messages to its users. We will use it in the future.
- `live_action`: when we get into the subject of Router we will see that we can use this data to identify where we are in the application.

Furthermore, we can notice that in the second `dbg` we already have new data, the `name` was added.

## Rendering `assigns`

Let's look at our render function once more:

```elixir
def render(assigns) do
  ~H"""
  Hello <%= @name %>
  """
end
```

The way we render assigns in a LiveView is by using `<%= %>`. The documentation calls these tags while I personally prefer to call it interpolation. Furthermore, to access the assign called `name` just use the shortcut `@name`.

Behind the scenes, inside a render function using `@name` is exactly the same as `assigns.name`. Remember that I said that the only argument of a render function was necessarily called `assigns`? See what happens if I rename it to any other name such as `def render(variables) do`:

```sh
$ elixir priv/examples/mount-and-assigns/assigns.exs
** (RuntimeError) ~H requires a variable named "assigns" to exist and be set to a map
    (phoenix_live_view 0.18.18) expanding macro: Phoenix.Component.sigil_H/2
    priv/examples/mount-and-assigns/assigns.exs:16: PageLive.render/1
```

However, if I change my render function to:

```elixir
def render(assigns) do
  ~H"""
  Hello <%= assigns.name %>
  """
end
```

Everything works normally.

## Recap!

- The `mount/3` callback runs when your LiveView is initializing.
- The `socket` data structure contains the state of your LiveView for this user at the moment.
- We were able to add `assigns` using the `assign/2` function passing the `socket` and the new values.
- The `render/1` function has a shortcut for writing assigns using `@name`.
