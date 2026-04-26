%{
title: "Navigating to the same route",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "The same LiveView can have more than one route",
previous_page_id: "v2-query-string",
next_page_id: "v2-function-component"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch query-string-done-done`</code>.
"""
} %% .callout

Sometimes it can be useful for a LiveView to be used on more than one route. Let's recap the route system made in a previous lesson:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
    <input disabled={@tab == "blog"} type="button" value="Open Blog" phx-click="show_blog" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end
```

Despite being simple and working correctly, this system had an UX problem: if you restart the page you will go back to the home tab. We can solve this by saving the current tab in the URL. If the page is refreshed we can read the URL and apply the current tab. Update `router.ex` like this:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/tab/:tab", PageLive, :show
  live "/other", OtherPageLive, :other
  live "/blog/:slug", BlogLive, :index
end
```

Then also update `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

To be able to add parameters to our route, we once again created a `live` route that maps `/tab/:tab` to our LiveView `PageLive`. Visit [http://localhost:4000/tab/home](http://localhost:4000/tab/home) to see your application. It's worth mentioning that we used Live Action `:show` this time as we are showing a single item in each tab.

As we are now working with routes, the buttons were replaced by `<.link>` components. Our `mount/3` receives the initial value from the `params` tab.

## Optional route parameter

You may have noticed that we create a bad experience for new users as the home page does not exist and the user is forced to type `/tab/home`. We can solve this by letting our `mount/3` handle the tab `param` in a different way and also making a new route. Update your `router.ex`:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/", PageLive, :show
  live "/tab/:tab", PageLive, :show
  live "/other", OtherPageLive, :other
  live "/blog/:slug", BlogLive, :index
end
```

And your `PageLive` like so:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

We just add a new route using the same LiveView and changed the way we handle the `params` then our `PageLive` becomes capable of being used in a context with or without a route parameter! It is worth noting that we modified our `<.link>` from Home to send to `/` however `/tab/home` also works normally.

## Optimizing navigation in the same LiveView

When you use `<.link navigate={...}>` LiveView understands that you are changing from one LiveView to a different one and need to create a new context. If you know in beforehand that a transition goes to the same LiveView you can use the alternative `<.link patch={...}>` and the modification between the route will be even more optimized. For this to work correctly we need to introduce a new callback called `handle_params/3`. Update your `PageLive` file:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

The `handle_params/3` callback is very similar to `mount/3` except that the second argument contains the URI of the current page and the return must be `{:noreply, socket}`.

One annoying thing at the moment is the fact that we have duplicated code between our `mount/3` and `handle_params/3`. Fortunately there is a very simple solution for this. Whenever a LiveView is initialized by Phoenix for the first time it executes `mount/3` if it exists and then `handle_params/3` if it exists. This way we can remove `mount/3` completely. Update `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

Now we can optimize the navigation between the same LiveView by simply making links use the `patch` attribute and changing from `mount/3` to `handle_params/3`.

%{
title: "Should I optimize all routes?",
description: ~H"""
Early optimization is terrible. If you identify a LiveView that you want to optimize, go ahead. If you don't want to worry about this simply use <code>`navigate`</code> in all your <code>`.link`</code> components.
"""
} %% .callout

## Recap!

- A LiveView can be used on more than one route.
- We can take advantage of URLs to persist data in cases such as tabs.
- `handle_params/3` is a callback that is executed right after `mount/3`.
- One way to optimize page changes for the same LiveView is to use `patch` in the `<.link>` components.
- Using `patch` we execute `handle_params/3`.
