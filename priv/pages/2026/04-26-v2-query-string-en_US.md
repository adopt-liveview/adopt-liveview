%{
title: "Generic parameters with query string",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "Receiving variable data from the URL",
previous_page_id: "v2-route-params",
next_page_id: "v2-navigate-to-the-same-route"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch your-second-liveview-done`</code>.
"""
} %% .callout

The `params` variable passed to `mount/3` is not limited to parameters in the URL path; it can also contain data coming from the query string. Let's create a simple LiveView in which if the user passes the query string like `?admin_mode=secret123`, then they can see something just for admins. Update your `PageLive` to this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

This LiveView reused several things covered in previous lessons. The main thing here is the fact that we received the params argument without specifying any specific param. If the user passes an empty query string, our system will simply leave the assign `admin?` as false. Open `http://localhost:4000/?admin_mode=secret123` to see the admin panel message.

## Recap!

- The `params` variable receives anything in the query string in key-value format like `?x=10&y=12`.
- As the `params` variable is a map, we can use the `params["key"]` syntax to access optional values.
