%{
title: "LiveView Assigns",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentals",
description: "How do variables work in LiveView?",
previous_page_id: "v2-anatomy-of-a-liveview",
next_page_id: "v2-your-first-mistakes"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch first-liveview-done`</code>.
"""
} %% .callout

## Storing state

A very important feature of a frontend framework is being able to store the state of the current application. ReactJS uses hooks, VueJS uses composition/options API and so on. In LiveView we call the state of a view `assigns` (plural form).

`assigns` are just an Elixir map. You can store in the `assigns` map everything that you could store in any variable: lists, maps, structs, etc.

A great place to write `assigns` when your LiveView is generated is in a `callback` called `mount/3`.

Let's edit our `page_live.ex` just a bit:

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
    """
  end
end
```

Start the server with `mix phx.server` in case you haven't yet.

If you're feeling desperate right now, don't be. I know 7 new things were added in just 5 new lines of code compared to before but let's break down these modifications one at a time!

## The `mount/3` callback

The way in which the LiveView framework sends information so that programmers can process the data is through callbacks. These are nothing more than functions that run when something happens. The `mount/3` callback runs when your LiveView is initialized. Its three arguments are, respectively:

- Parameters coming from the URL. Useful for routes like `/users/:id` where `:id` would be one of the parameters.
- Data from the current browsing session (if configured). Useful for authentication.
- Data from the current connection with the user accessing this LiveView in a data structure called [Phoenix.LiveView.Socket](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Socket.html), better known simply as `socket`.

The first two arguments will be explored in more detail in future guides. Right now we will just ignore them for the sake of simplicity.

## The %Socket{} data structure

Let's get straight to the point: LiveView state management is essentially modifying the state of your socket. The function [`assign/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#assign/2) receives your `socket` and the assigns you want to add and applies them generating a new socket. Let's try! Update your code as follows:

```elixir
def mount(_params, _session, socket) do
  socket.assigns |> dbg
  socket = assign(socket, name: "Lubien")
  socket.assigns |> dbg
  {:ok, socket}
end
```

%{
title: ~H"<code>`dbg/2`</code>",
description: ~H"""
The <.link navigate="https://hexdocs.pm/elixir/debugging.html#dbg-2" target="\_blank"><code>`dbg/2`</code></.link> macro is extremely useful for debugging code and we will be using it a lot during classes. In general, it will be used by adding a `pipe` to it like <code>`|> dbg`</code>. It tells you the file name, line, function and variables of the thing you are debugging. Super powerful.
"""
} %% .callout

If you check your terminal, you will see information like this:

```elixir
[(myapp 0.1.0) lib/myapp_web/live/page_live.ex:5: MyappWeb.PageLive.mount/3]

socket.assigns #=> %{flash: %{}, __changed__: %{}, live_action: :home}


[(myapp 0.1.0) lib/myapp_web/live/page_live.ex:7: MyappWeb.PageLive.mount/3]

socket.assigns #=> %{name: "Lubien", flash: %{}, __changed__: %{name: true}, live_action: :home}
```

As we can see, assigns are just a map with some data about your LiveView. Explaining each one:

- `__changed__`: is a map that LiveView automatically populates when something changes in order to explain to its HTML rendering engine which properties need to be updated to generate the final HTML in an efficient way.
- `flash`: is a map used to send information, success and alert messages to its users. We will use it in the future.
- `live_action`: when we get into the subject of Router we will see that we can use this data to identify where we are in the application.

Furthermore, we can notice that in the second `dbg` we already had new data, the `name` assign was added.

## Rendering `assigns`

Let's look at our render function once more:

```elixir
def render(assigns) do
  ~H"""
  Hello {@name}
  """
end
```

The way we render assigns in a LiveView is by using `{something}`. The documentation calls these tags while I personally prefer to call it interpolation. Furthermore, to access the assign called `name`, just use the shortcut `@name`. Another way we render assigns in a LiveView is by using `<%= %>`, but you should prefer the shortcut `{}` whenever possible. We will see cases where `<%= %>` syntax is needed in the future. Old LiveView projects used `<%= %>` before `{}` was introduced, but upgrading LiveView should convert most of them to the new syntax using the formatter.

Behind the scenes, inside a render function using `@name` is exactly the same as `assigns.name`. Remember that I said that the only argument of a render function was necessarily called `assigns`? See what happens if I rename it to any other name such as `def render(variables) do`:

```sh
== Compilation error in file lib/myapp_web/live/page_live.ex ==
** (RuntimeError) ~H requires a variable named "assigns" to exist and be set to a map
    (phoenix_live_view 1.1.16) expanding macro: Phoenix.Component.sigil_H/2
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: MyappWeb.PageLive.render/1
```

However, if I change my render function back to:

```elixir
def render(assigns) do
  ~H"""
  Hello {@name}
  """
end
```

Everything works normally.

## Recap!

- The `mount/3` callback runs when your LiveView is initializing.
- The `socket` data structure contains the state of your LiveView for this user at the moment.
- We were able to add `assigns` using the `assign/2` function passing the `socket` and the new values.
- The `render/1` function has a shortcut for writing assigns using `@name` instead of `assigns.name`.
