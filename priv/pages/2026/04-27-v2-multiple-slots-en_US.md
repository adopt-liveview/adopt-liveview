%{
title: "Multiple slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "A component can have more than one slot",
previous_page_id: "v2-components-from-other-modules",
next_page_id: "v2-slots-with-attributes"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch components-from-other-modules-done`</code>.
"""
} %% .callout

Let's recap the solution we used in the previous lesson for the Hero component:

```elixir
# ...
slot :inner_block, required: true

def hero(assigns) do
  ~H"""
  <div class="bg-gray-800 text-white py-20">
    <div class="container mx-auto text-center">
      <h1 class="text-4xl font-bold">{render_slot(@inner_block)}</h1>
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

By default every component will have an `@inner_block` slot if there is any HTML inside its tag. However you can also add more slots as needed. Start by updating `my_core_components.ex` to give `hero` named slots:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :title
  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold">{render_slot(@title)}</h1>
        <p class="mt-4 text-lg">{render_slot(@subtitle)}</p>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button type="submit" class="text-blue-500">Save data</.my_button>
      <.my_button type="submit" color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  attr :rest, :global, default: %{type: "button"}, include: ~w(type style)
  slot :inner_block, required: true

  def my_button(assigns) do
    ~H"""
    <button
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

Now update your `page_live.ex` to use the new slots:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.hero>
      <:title>IndexLive</:title>
      <:subtitle>Welcome to my personal website!</:subtitle>
      <.link
        class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
        navigate={~p"/other"}
      >
        Get Started
      </.link>
    </.hero>
    This is my homepage
    """
  end
end
```

And update `other_live.ex` as well:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view

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
```

The first modification we made was to add two new slots to our component definition. To make things clearer we use the names `:title` and `:subtitle` for the new slots.

Using custom slots is very similar to component syntax except that you must use `:`. When we put text in `<:my_slot>Abc</:my_slot>` the HEEx code inside it will be sent to this named slot as `@my_slot`. Any HTML not within a named slot will be placed in the `@inner_block` slot.

The [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) function can understand when there is nothing in the slot. In the `OtherPageLive` view we did not add anything outside of named slots and even so there were no problems in the code.

## Recap!

- Components can have more than one slot.
- Named slots can be used as `<:name>Content</:name>` and rendered as `{render_slot(@name)}`.
- Any HEEx outside of named slots falls into the `@inner_block` slot.
