%{
title: "Navigating to the same route",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "The same LiveView can have more than one route"
}

---

Sometimes it can be useful for a LiveView to be used on more than one route. Let's recap the route system made in a previous class:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Despite being simple and working correctly, this system had a UX problem: if you restart the page you go back to the home tab. We can resolve this by saving the current tab to the URL. This way, if the page is updated we can read the URL and apply the current tab. Create and run a file called `tab_param.exs`:

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

    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(%{"tab" => tab}, _session, socket) do
    socket = assign(socket, tab: tab)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} navigate={~p"/tab/home"}>Go to home</.link>
    <.link :if={@tab != "about"} navigate={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} navigate={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

To be able to add parameters to our route, we once again created a custom Router that maps `/tab/:tab` to our LiveView `TabLive`, so visit [http://localhost:4000/tab/home](http://localhost:4000/tab/home) to see your application. It's worth mentioning that we used Live Action :show this time as we are showing a single item in each tab.

As we are now working with routes, the buttons were replaced by `<.link>` components. Furthermore, our mount receives the initial value from the `params` tab.

## Optional route parameter

You may have noticed that we create a bad experience for new users as the home page does not exist and the user is forced to type `/tab/home`. We can solve this by letting our `mount/3` handle the tab `param` in a different way and a new route. Create and run `tab_param_optional.exs`:

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

    live "/", TabLive, :show
    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(params, _session, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} navigate={~p"/"}>Go to home</.link>
    <.link :if={@tab != "about"} navigate={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} navigate={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

Just add a new route using the same LiveView and change the way we treat the `params` and our `TabLive` becomes capable of being used in a context with or without a route parameter! It is worth noting that we modified our `<.link>` from Home to send to `/` however `/tab/home` also works normally.

## Optimizing navigation in the same LiveView

When you use `<.link navigate={...}>` LiveView understands that you are changing from one LiveView to a different one and need to create a new context. If you know in advance that a transition goes to the same LiveView you can use the alternative `<.link patch={...}>` and the modification between the route will be minimal. For this to work correctly we need to introduce a new callback called `handle_params/3`. Create and run a `tab_param_patch.exs` file:

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

    live "/", TabLive, :show
    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(params, _session, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <.link :if={@tab != "home"} patch={~p"/"}>Go to home</.link>
    <.link :if={@tab != "about"} patch={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} patch={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

The `handle_params/3` callback is very similar to `mount/3` except that the second argument contains the URI of the current page and the return must be `{:noreply, socket}`.

One annoying thing at the moment is the fact that we have duplicate code between our `mount/3` and `handle_params/3`. Fortunately there is a very simple solution for this. Whenever a LiveView is instantiated by Phoenix for the first time it executes `mount/3` if it exists and then `handle_params/3` if it exists. This way we can remove `mount/3` completely. Create and run a file called `tab_param_patch_refactor.exs`

This way we can optimize the exchange between the same LiveView by simply making links use the `patch` attribute and changing from `mount/3` to `handle_params/3`.

%{
title: "Should I optimize all routes then?",
description: ~H"""
Early optimization is terrible. If you identify a LiveView that you want to optimize, go ahead. If you don't want to worry about this simply use <code>`navigate`</code> in all your <code>`.link`</code> components.
"""
} %% .callout

## In short!

- A LiveView can be used on more than one route.
- We can take advantage of URLs to persist data in cases such as tabs.
- `handle_params/3` is a callback that is executed right after `mount/3`.
- One way to optimize page changes for the same LiveView is to use `patch` in the links.
- Using `patch` we execute `handle_params/3`.
