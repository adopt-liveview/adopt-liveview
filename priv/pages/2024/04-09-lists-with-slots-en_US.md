%{
title: "Rendering lists with slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "Using slots to make loops",
previous_page_id: "slots-with-attributes",
next_page_id: "forms"
}

---

Imagine you are building an application that lists boxing terms. Your initial implementation looks a lot like the code below:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    boxing_terms = [
      %{term: "Jab", definition: "A quick, straight punch thrown with the lead hand."},
      %{
        term: "Hook",
        definition:
          "A punch thrown in a circular motion targeting the side of the opponent's head or body."
      },
      %{
        term: "Cross",
        definition:
          "A powerful punch thrown with the rear hand across the body, traveling straight toward the opponent."
      }
    ]

    socket = assign(socket, boxing_terms: boxing_terms)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @boxing_terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold"><%= item.term %></dt>
          <dd class="text-gray-600"><%= item.definition %></dd>
        </div>
      </div>
    </dl>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

So far nothing you haven't seen. There's an assign to define the list of terms, a loop using the special `:for` attribute and each item is being rendered. However, due to the previous lessons, you might notice that you could simplify this code a little more by generating a component to hide all these classes and, at the same time, have greater reusability in your `<dl>`.

## Mixing slots and lists

So farour slots only have rendered a single element. Whether it was a title or a subtitle per `<:slot_name>` usage. Let's learn how to combine lists and slots. Create and run a file called `rendering_slot_list.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  attr :terms, :list, required: true
  slot :dt, required: true
  slot :dd, required: true

  def dl(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold"><%= render_slot(@dt, item) %></dt>
          <dd class="text-gray-600"><%= render_slot(@dd, item) %></dd>
        </div>
      </div>
    </dl>
    """
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def mount(_params, _session, socket) do
    boxing_terms = [
      %{term: "Jab", definition: "A quick, straight punch thrown with the lead hand."},
      %{
        term: "Hook",
        definition:
          "A punch thrown in a circular motion targeting the side of the opponent's head or body."
      },
      %{
        term: "Cross",
        definition:
          "A powerful punch thrown with the rear hand across the body, traveling straight toward the opponent."
      }
    ]

    socket = assign(socket, boxing_terms: boxing_terms)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.dl terms={@boxing_terms}>
      <:dt :let={item}><%= item.term %></:dt>
      <:dd :let={item}><%= item.definition %></:dd>
    </.dl>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Once again using the idea of `CoreComponents` we created a component called `<.dl>` to make it clear that this is our version of the `<dl>` HTML tag. We also chose the name of our slots to mimick HTML's: `<:dt>` (description term) and `<:dd>` (description detail).

The component itself isn't much different from what you've seen before. We use a loop with `:for`. For each element we use the `render_slot/2` function. The difference is that this time we passed a second argument to that function: the current item in the loop.

When a second argument is passed to `render_slot/2` we can use the special attribute `:let={var}` at the slot definition to store the current looped element in `var`. That way we managed to simplify a component that works with loops and made our LiveView `render/1` extremely clean.

## Recap!

- You can simplify loops by creating components.
- Slots can receive loop variables by passing them in the second argument of `render_slot/2` and receiving them in the slot with `:let={var_name}`.
- Using slots and components makes LiveViews code cleaner.
