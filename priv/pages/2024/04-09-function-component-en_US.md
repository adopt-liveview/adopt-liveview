%{
title: "Functional components",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "Reusing code intelligently",
previous_page_id: "navigate-to-the-same-route",
next_page_id: "documenting-components"
}

---

Reusing code is the key to building a maintainable system. In LiveView there is more than one way for you to reuse HEEx code. In this and the next classes we will explore functional components for your views and, step by step, understand how they work and their possibilities.

## Understanding the problem

Create and run a `duplicated_code.exs` file:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      Default
    </button>
    <button
      type="button"
      class="focus:outline-none text-white bg-green-700 hover:bg-green-800 focus:ring-4 focus:ring-green-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800"
    >
      Green
    </button>
    <button
      type="button"
      class="focus:outline-none text-white bg-red-700 hover:bg-red-800 focus:ring-4 focus:ring-red-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-red-600 dark:hover:bg-red-700 dark:focus:ring-red-900"
    >
      Red
    </button>
    <button
      type="button"
      class="focus:outline-none text-white bg-yellow-400 hover:bg-yellow-500 focus:ring-4 focus:ring-yellow-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:focus:ring-yellow-900"
    >
      Yellow
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

In this example we introduce the `scripts` property in our `LiveviewPlayground.start/1` which accepts a list of JavaScript scripts and adds them to our HTML. We will use Tailwind instead of writing CSS directly because nowadays Phoenix already comes with this library installed.

Imagine you are developing a large project and the styles above are used for buttons. Every time you need a new button you would have to copy and paste a ton of classes. Even if there were one or two classes, if one day they changed you would have to change them in every corner of your application.

## Creating a functional component

In previous classes we saw the `<.link>` component being used to render our links. To create a new component, simply create a function with any name and that receives a single variable called assigns. Create and run `first_component.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button>Default</.button>
    <.button>Green</.button>
    <.button>Red</.button>
    <.button>Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      Default
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Just like `render/1`, we have another function that returns HEEx and takes an argument called assigns. To use a component defined in the current file, simply write `<.component_name></.component_name>` in your HEEx.

%{
title: ~H"Why do components have a <code>.</code> at the beginning?",
description: ~H"""
We chose this example precisely because there is an HTML <code>`button`</code> tag. The <code>.</code> at the beginning of the component serves to make it obvious that this tag refers to a functional component and not an HTML tag.
"""
} %% .callout

Unlike our first code you can notice that all buttons now show the same text: "Default" despite the fact that `<.button>` has a different text! This happens because at the moment we are the creators of the new component, we must teach HEEx one the content of the internal block to be rendered. Create and run `component_inner_block.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button>Default</.button>
    <.button>Green</.button>
    <.button>Red</.button>
    <.button>Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

The only change happened in our `<.button>`.
We added the [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) function by passing an assign `@inner_block`. The assign in question is automatically defined in components and is of the slot type, as the HTML passed within your `<.componente>` is called. From now on, anything sent within `<.button>` will be rendered there.

## Customizing components with attributes

Originally each button had its own color whereas now they all have the same style. We can customize our buttons using passed assigns. Create and run `custom_button_colors.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button color="blue">Default</.button>
    <.button color="green">Green</.button>
    <.button color="red">Red</.button>
    <.button color="yellow">Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class={"text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800"}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Now each use of the button has an assign of `color="..."` and we can customize our buttons in a much simpler way and without duplicating code.

## In short!

- You can create components in your LiveViews if you create a function that receives `assigns` and returns HEEx.
- HTML components and tags are differentiated by the presence of a `.` at the beginning of the tag to avoid conflicts.
- In a component you decide where to render the child slot using `render_slot(@inner_block)`.
- With attributes, your components can reuse code efficiently.
