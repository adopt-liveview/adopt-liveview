%{
title: "Route parameters",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "Receiving data from URL",
previous_page_id: "v2-your-second-liveview",
next_page_id: "v2-query-string"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch your-second-liveview-done`</code>.
"""
} %% .callout

In a dynamic system, it is quite common that in the same route you need to handle variables coming from the URL, generally known as parameters by many frameworks. Let's explore how to do this with LiveView.

## Router with parameters

Let's build a simple blog. There we can access `/blog/anything` and read these blog posts. Add the following `live` route to your `router.ex`:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/", PageLive, :home
  live "/other", OtherPageLive, :other
  live "/blog/:slug", BlogLive, :index
end
```

Update your `PageLive` to:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

Then finally lets add `BlogLive` under `lib/myapp_web/live/blog_live.ex`:

```elixir
defmodule MyappWeb.BlogLive do
  use MyappWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket = assign(socket, :slug, slug)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Reading about {@slug}</h1>
    """
  end
end
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
