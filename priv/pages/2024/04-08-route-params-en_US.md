%{
title: "Route parameters",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "Receiving data from URL"
}

---

In a dynamic system, it is quite common that in the same route you need to handle variables coming from the URL, generally known as parameters by many frameworks. Let's explore how to do this with LiveView.

## Router with parameters

Let's build a simple blog. There we can access `/blog/anything` and read more about it. Create and run a file called `params.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.3"}
])

defmodule CustomRouter do
  use LiveviewPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/blog/:slug", BlogLive, :index
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Welcome to my Website!</h1>
    <ul>
      <li><.link navigate={~p"/blog/dolphins"}>Read about dolphins</.link></li>
      <li><.link navigate={~p"/blog/elephants"}>Read about elephants</.link></li>
    </ul>
    """
  end
end

defmodule BlogLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket = assign(socket, :slug, slug)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Reading about <%= @slug %></h1>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

Here we create a `/blog/:slug` route with a variable in the URL called `:slug`. This ensures that `BlogLive` will receive a map in the first argument of your `mount/3` in the format `%{"slug" => slug}` and you can use this variable to create an assign. You can either use the links added on the home page or try different URLs for `/blog/anything`.

%{
title: "Curiosity",
description: ~H"""
You are on this site under a route <code>/guides/:id</code>, see the URL in your browser.
"""
} %% .callout

## In short!

- The `live/4` macro lets you create parameters in the URL using the `:variable_name` format.
- Any parameter defined in the router becomes a key in the `params` map in your LiveView.
