%{
title: "Generic parameters with query string",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "Receiving data from the URL without knowing what it is",
previous_page_id: "route-params",
next_page_id: "navigate-to-the-same-route"
}

---

The `params` variable passed to `mount/3` is not limited to parameters in the URL path, it can also contain data coming from the query string. Let's create a simple LiveView in which if the user passes the query string `?admin_mode=secret123` he can see something just for admins. Create and run `query_string.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.3"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(params, _session, socket) do
    admin? = params["admin_mode"] == "secret123"
    socket = assign(socket, :admin?, admin?)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome to my Website!</h1>
    <.link :if={@admin?} navigate={~p"/admin"}>Go to admin panel</.link>
    """
  end
end

LiveviewPlayground.start()
```

This LiveView reused several things covered in previous classes. The main thing here is the fact that we receive the params variable without specifying any specific param. This way, if the user passes an empty query string, our system will simply leave the assign `admin?` as false.

## In short!

- The `params` variable receives anything in the query string in key-value format like `?x=10&y=12`.
- As the `params` variable is a map, we can use the `params["key"]` syntax to access optional values.
