%{
title: "Route parameters",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "Receiving data from URL",
previous_page_id: "your-second-liveview",
next_page_id: "query-string"
}

---

In a dynamic system, it is quite common that in the same route you need to handle variables coming from the URL, generally known as parameters by many frameworks. Let's explore how to do this with LiveView.

## Router with parameters

Let's build a simple blog. There we can access `/blog/anything` and read these blog posts. Create and run a file called `params.exs`:

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

Here we created a `/blog/:slug` route with a variable in the URL called `:slug`. This ensures that `BlogLive` will receive in its first argument of the `mount/3` callback a map in the format `%{"slug" => slug}` and you can use this variable to create an assign. You can either use the links added on the home page or try different URLs for `/blog/anything`.

%{
title: "Trivia",
description: ~H"""
You are on this site under a route <code>/guides/:id/:locale</code>. Look at the URL in your browser.
"""
} %% .callout

## Recap!

- The `live/4` macro lets you create parameters in the URL using the `:variable_name` format.
- Any parameter defined in the router becomes a key in the `params` map in your LiveView.
