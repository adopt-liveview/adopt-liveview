%{
title: "Multiple slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "A component can have more than one slot",
previous_page_id: "components-from-other-modules",
next_page_id: "slots-with-attributes"
}

---

Let's recap the solution we used in the previous lesson for the Hero component:

```elixir
# ...
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
# ...
```

We use the `@inner_block` slot to render the main text of the page but left two other texts repeated both on the home page and on the `/other` LiveView. This creates even more confusion because you are already on that page, there is no need for you to see this link.

## Custom slots

By default every component will have an `@inner_block` slot if there is any HTML inside its tag. However you can also add more slots as needed. Create and run `custom_slots.exs`:

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

  slot :title
  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold"><%= render_slot(@title) %></h1>
        <p class="mt-4 text-lg"><%= render_slot(@subtitle) %></p>
        <%= render_slot(@inner_block) %>
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
    <.hero>
      <:title>IndexLive</:title>
      <:subtitle>Welcometo my personal website!</:subtitle>
      <.link
        class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
        navigate={~p"/other"}
      >
        Get Started
      </.link>
    </.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>
      <:title>OtherPageLive</:title>
      <:subtitle>You're on the first step!</:subtitle>
    </.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
```

The first modification we made was to add two new `slot` to our component definition. To make things clearer we use the names `:title` and `:subtitle` for the new slots.

Using custom slots is very similar to component syntax except that you must use `:`. When we put text in `<:my_slot>Abc</:my_slot>` the HEEx code inside it will be sent to this named slot as `@my_slot`. Any HTML not within a named slot will be placed in the `@inner_block` slot.

The [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) function can understand when there is nothing in the slot. In the OtherPageLive view we did not add anything outside of named slots and even so there were no problems in the code.

## Recap!

- Components can have more than one slot.
- Named slots can be used as `<:name>Content</:name>` and rendered as `<% render_slot(@name) %>`.
- Any HEEx outside of named slots falls into the `@inner_block` slot.
