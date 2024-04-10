%{
title: "Your second LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Navigation",
description: "How to navigate between LiveViews",
previous_page_id: "multiple-pushes",
next_page_id: "route-params"
}

---

All this time we were working with just a single LiveView called PageLive. Choosing this name was actually simple, LiveView Playground checks if the PageLive module exists and makes it the home page of your project.

## Getting to know Phoenix.Router

Every Phoenix application, without exception, requires a Router. When you create a new Phoenix project, it already generates this file with the name `YourProjeto.Router`. Let's see how LiveViewPlayground defines its Router:

```elixir
defmodule LiveviewPlayground.Router do
  use LiveviewPlayground, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", PageLive, :index
  end
end
```

All this time when you were using `LiveviewPlayground.start()` the above module was implicitly used and, as explained previously, the existence of the LiveView module called `PageLive` was mandatory because the default LiveView Playground Router made the assumption that he existed. It's worth mentioning that this example is very close to how a real Phoenix project actually works.

Although many new things have appeared, let's focus on an overview. At another time we will look at each piece in detail. Simply put:

- The line `use LiveviewPlayground, :router` imports functions and macros necessary to create our routes.
- The `pipeline :browser do` block defines a set of plugs (understand them as configurations at the moment) for routes of type `:browser`. In this case we only define that it is a route that uses HTML.
- We use the `scope "/" do` block to represent that the routes within the block are rendered in the root of our website.
- `pipe_through :browser` activates the pipeline called `:browser` in this scope.

Now the most important thing: how to define a LiveView route. Using the [`live/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live/4) macro we define that on the home page (`"/"`) the `PageLive` module will be rendered and its Live Action will be `:index`. At the moment, you don't need to worry about Live Action, we will resume it in the future.

## Building your first Phoenix.Router

Now that we understand the fundamentals of a Router, we will build a new router in practice. Create and run a file called `router.exs`:

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
    live "/other", OtherPageLive, :index
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>IndexLive</h1>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
```

The first module here is called CustomRouter (it could be any name). The only difference from the original Router is that it has two uses of the `live/4` macro for two different LiveViews. Note that this time we named our main route IndexLive just to demonstrate that if you can modify the Router you can call your LiveViews whatever you want.

The last line of our file explicitly passes the router to the Playground. This is a thing specific to LiveView Playground and not actual Phoenix projects.

Each LiveView is very similar to the other, only changing the main text and the navigation button text. What we have new here are two things: the `<.link>` component and the `sigil_p`.

## The `<.link>` component

This is the first time in this course that you will see an HTML tag that starts with `.` at the moment. These tags are known as components, we will talk about them in detail in the future.

The important thing about the [`.link`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#link/1) component is that it is specialized in generating navigation between pages on your Phoenix website. Using the `navigate={...}` attribute, Phoenix can make an optimized transition between two LiveViews whenever possible, so always prefer this component instead of using the `<a>` HTML tag.

## Verified Phoenix Routes

In Phoenix projects whenever you want to write a route you could very well use a string like "/path/of/page". What if this route doesn't exist? We would only know when we click this link and see the bug.

To avoid surprises with routes that don't exist, Phoenix comes with a feature called Verified Routes in which you use the `sigil_p` in the format `~p"/caminho/da/pagina/"` and Phoenix will notify you in warnings if you is using routes that don't exist.

%{
title: "Verified Routes and LiveView Playground",
type: :warning,
description: ~H"""
So far, LiveView Playground is unable to check routes using <code>`sigil_p`</code>. In any case, the recommendation is that you continue using them by default.
"""
} %% .callout

## In short!

- Every Phoenix application has a Router.
- On a Router we can define LiveView routes using the `live/4` macro.
- HTML tags with `.` at the beginning such as `<.link>` indicate that that tag is actually a component.
- We must use the `<.link navigate={~p"/rota"}>` component for our LiveView to navigate efficiently between routes.
- Using `sigil_p` we can write routes so that Phoenix will warn us if they don't exist so we can detect problems at development time.
