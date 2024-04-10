%{
title: "Components from other modules",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "How to reuse components in more than one LiveView",
previous_page_id: "documenting-components",
next_page_id: "multiple-slots"
}

---

When we create a component as a function in a LiveView we gain access to it in our HEEx using `<.function_name>`. However, if you need to use it in another LiveView you need to say the module name too. Create and run `shared_component.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
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
    <.hero>IndexLive</.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end

  slot :inner_block, required: true

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold"><%= render_slot(@inner_block) %></h1>
        <p class="mt-4 text-lg">My personal website</p>
        <.link
          class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
          navigate={~p"/other"}
        >
          Get Started
        </.link>
      </div>
    </div>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <IndexLive.hero>OtherPageLive</IndexLive.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
```

For this example we created a simple Hero component (a component generally used to draw attention) and, to be able to use it in OtherPageLive we had to use the syntax `<IndexLive.hero>OtherPageLive</IndexLive.hero>`.

## Getting to know CoreComponents

In Phoenix projects when we have certain components that are useful in various parts of our system we choose to share them in a module called CoreComponents and import them. Create and run a file called `core_components.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
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

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  slot :inner_block, required: true

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold"><%= render_slot(@inner_block) %></h1>
        <p class="mt-4 text-lg">My personal website</p>
        <.link
          class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
          navigate={~p"/other"}
        >
          Get Started
        </.link>
      </div>
    </div>
    """
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>IndexLive</.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>OtherPageLive</.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
```

Now our `hero` component lives in a module dedicated to useful application components. It is worth mentioning that our CoreComponents have a `use LiveviewPlaygroundWeb, :html` call to import several functions such as HEEx support and `sigil_p` for routes.

In each of our LiveViews we manually use `import CoreComponents`. In Elixir when you import a module you get all its functions so we can use `<.hero>` (instead of `<CoreComponents.hero>`) because the `hero/1` function is available in each LiveView at the moment.

%{
title: "CoreComponents in the real world",
description: ~H"""
In this example we are creating a module called <code>`CoreComponents`</code> but in real Phoenix projects it would be called <code>`YourWebApp.CoreComponents`</code> and it would already be automatically generated and imported automatically. We are just doing this manual exercise so you can better understand what advantages this organization has.
"""
} %% .callout

## In short!

- You can use components from other modules using the `<ModuleName.component_name>` syntax.
- If the component in question is used commonly in the application, consider placing it in your `CoreComponents`.
- During classes we will manually build and import our `CoreComponents` but in the real world Phoenix already does this for you.
