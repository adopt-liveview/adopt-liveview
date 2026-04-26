%{
title: "Your second LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "How to navigate between LiveViews",
previous_page_id: "v2-multiple-pushes",
next_page_id: "v2-route-params"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

All this time we were working with just a single LiveView called PageLive. Today we are gonna change that.

## Getting to know Phoenix.Router

Every Phoenix application, without exception, requires a Router. When you create a new Phoenix project, it already generates this file with the name `YourProject.Router`. Open `lib/myapp_web/router.ex`:

```elixir
defmodule MyappWeb.Router do
  use MyappWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyappWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyappWeb do
    pipe_through :browser

    live "/", PageLive, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MyappWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:myapp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MyappWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
```

## Anatomy of a router module

### The `use` macro

Phoenix will always add to router modules something like `use MyappWeb, :router`. Behind the scenes it imports router functions like `get/4`, `post/4` and `live/4` so you can define routes.

### Pipelines

Think of pipelines as reusable router settings for multiple route groups. At this point all you need to care about is that `:browser` pipeline works, well, on browsers. They're used inside `scope` blocks like `pipe_through :pipeline_name`.

### Dev routes

Using `if Application.compile_env(:myapp, :dev_routes) do` we can ensure routes are only compiled in develoipment environments and skip prod altogether. This is useful for our fake Mailbox to test mailing without setting SMTP or APIs plus our [Live Dashboard](https://github.com/phoenixframework/phoenix_live_dashboard/) route. Got curious? Open [http://localhost:4000/dev/dashboard](http://localhost:4000/dev/dashboard)

### Scope block

`scope/4` blocks are often used to group routes that have similar requirements. You'd often see in Phoenix projects a scope for unauthenticated routes, another one for authenticated routes, one or more scopes for API routes. Later on we will be seeing those in more depth.

## Adding our second LiveView

Using the [`live/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live/4) macro we define that on the home page (`"/"`) the `PageLive` module will be rendered and its Live Action will be `:index`. Don't need to worry about Live Action, we will go back to it in future lessons.

Edit `router.ex` to add a second route like this:

```elixir
...
scope "/" do
  pipe_through :browser

  live "/", PageLive, :home
  live "/other", OtherPageLive, :other
end
...
```

Then create a file under `lib/myapp_web/live/other_live.ex`:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end
```

And finally edit your `PageLive` like this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>PageLive</h1>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end
```

The `OtherPageLive` is very similar to the first one. We only changed the main text and the navigation button text.

The new things here are: the `<.link>` component and the `sigil_p`.

## The `<.link>` component

This is the first time in this course that you've seen an HTML tag that starts with `.`. These tags are known as components, we will talk about them in detail in the future.

The important thing about the [`.link`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#link/1) component is that it is specialized in providing navigation between pages on your Phoenix website. Using the `navigate={...}` attribute, Phoenix can make an optimized transition between two LiveViews whenever possible so always prefer this component instead of using the `<a>` HTML tag.

## Verified Phoenix Routes

In Phoenix projects whenever you want to write a route you could very well use a string like "/path/to/page". What if this route doesn't exist? We would only know when we click this link and see the issue.

To avoid surprises with routes that don't exist Phoenix comes with a feature called Verified Routes in which you use the `sigil_p` in the format `~p"/path/to/page/"` and Phoenix will warn you if there are using routes that doesn't exist.

## Recap!

- Every Phoenix application has a Router.
- Routers will use pipelines and `scope` blocks to define how certain routes behave.
- On a Router we can define LiveView routes using the `live/4` macro.
- HTML tags with `.` at the beginning such as `<.link>` indicate that this tag is actually a component.
- We must use the `<.link navigate={~p"/route"}>` component in our LiveViews to navigate efficiently between routes.
- Using `sigil_p` we can write routes so that Phoenix will warn us if they doesn't exist so we can detect problems at development time.
