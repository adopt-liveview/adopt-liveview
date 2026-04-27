%{
title: "Slots with attributes",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "How to customize slots with attributes",
previous_page_id: "v2-multiple-slots",
next_page_id: "v2-lists-with-slots"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch multiple-slots-done`</code>.
"""
} %% .callout

In the previous lesson we used the `<.hero>` component twice. Let's say that on the home page we would like the title to be more eye-catching. How to pass attributes to slots?

## Really understanding what slots are

To understand what we are about to do first you need to understand how slots work internally. You may have already noticed that since we render slots using `@slot_name` assigns this means that slots are nothing more than special assigns. Every `@slot_name` is necessarily a list. If you go to your component and use `{inspect(@slot_name)}` you will see something like:

```elixir
[%{inner_block: #Function<2.32079264/2 in MyappWeb.PageLive.render/1>, __slot__: :slot_name}]
```

Secretly, slots are lists of maps that contain a HEEx render function in the `__inner_block__` property and the slot name in the `__slot__` property. That being said nothing prevents you from using the same slot multiple times on the same component.

```heex
<.hero>
  <:title class="text-red-500">IndexLive</:title>
  <:title class="text-red-500">IndexLive</:title>
  <:subtitle>Welcome to my personal website!</:subtitle>
</.hero>
```

In the example above when inspecting the `@title` slot we will see:

```elixir
[%{inner_block: #Function<2.32079264/2 in MyappWeb.PageLive.render/1>, __slot__: :title},
%{inner_block: #Function<3.32079264/2 in MyappWeb.PageLive.render/1>, __slot__: :title}]
```

## Rendering attributes with slots

Why did we go through this whole brainstorming session about understanding that slots are lists of maps in Elixir if our goal is to render slot classes? Simple: if slots are lists we can do loops and if each slot is a map, we can get properties from them!

Start by updating `my_core_components.ex` to add a `class` attribute to the `:title` slot and loop through it in the template:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :title do
    attr :class, :string
  end

  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 :for={title_slot <- @title} class={["text-4xl font-bold", Map.get(title_slot, :class)]}>
          {render_slot(title_slot)}
        </h1>
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

Now update your `page_live.ex` to pass a `class` to the `:title` slot:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.hero>
      <:title class="text-red-500">IndexLive</:title>
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

And keep `other_live.ex` as is — it uses the slot without a class, which is perfectly valid:

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

Our slot has gained something new in its definition! Using a `do` block we can declare which attributes are important to that specific slot. In this case, just `class`.

Additionally we changed the way we render the slot to use a `:for={title_slot <- @title}` loop so that we can look at each use of `<:title>` individually to get its classes. Inside the `class` attribute we use a list to be able to apply the optional attributes that we can extract using `Map.get(title_slot, :class)` (which will be `nil` by default, resulting in no class being applied). Finally, inside our loop we modify the use of `render_slot/2` so that it uses the current loop variable `{render_slot(title_slot)}`.

Great! Now your slots can have attributes in them. We managed to solve the original problem: on the home page we would like the slot title to have a different attribute than the other page!

## Recap!

- Each slot is actually a list of map assign.
- Slots can be given attributes and we can document this using `slot/2` with a `do` block.
- To access slot attributes we need to loop through `@slot_name` then use `Map.get(loop_item, :attribute_name)`.
