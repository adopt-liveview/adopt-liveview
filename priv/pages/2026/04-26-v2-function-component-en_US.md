%{
title: "Functional components",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "Reusing code in a smart way",
previous_page_id: "v2-navigate-to-the-same-route",
next_page_id: "v2-documenting-components"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch navigate-to-the-same-route-done`</code>.
"""
} %% .callout

Reusing code is the key to building a maintainable system. In LiveView there is more than one way for you to reuse HEEx code. In the following lessons we will explore functional components for your views and, bit by bit, understand how they work and their possibilities.

## Understanding the problem

Update your `page_live.ex` like this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

We will use Tailwind CSS classes for styling — Phoenix already comes with Tailwind installed by default.

Imagine you are developing a large project and the styles above are used for buttons. Every time you need a new button, you would have to copy and paste a ton of classes. Even if there were one or two classes, whenever we needed to change them, you would have to change every corner of your application.

## Creating a functional component

In the previous lesson, we saw the `<.link>` component being used to render our links. To create a new component, simply create a function with any name that receives a single variable called assigns. Update your `page_live.ex` to add a `my_button` component:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button>Default</.my_button>
    <.my_button>Green</.my_button>
    <.my_button>Red</.my_button>
    <.my_button>Yellow</.my_button>
    """
  end

  def my_button(assigns) do
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
```

Just like `render/1`, we have another function that returns HEEx and takes an argument called assigns. To use a component defined in the current file, simply write `<.component_name></.component_name>` in your HEEx.

%{
title: ~H"Why call it <code>.my_button</code> instead of <code>.button</code>?",
description: ~H"""
Phoenix projects will come with a handful of components that are common to many web apps, which includes <code>.button</code> so to prevent conflicts and focus on learning we will be naming this and other components from future lessons as <code>.my_component</code> until we start using the default generated ones.
"""
} %% .callout

%{
title: ~H"Why do components have a <code>.</code> at the beginning?",
description: ~H"""
As you might already know, there is an HTML <code>`button`</code> tag. The <code>.</code> at the beginning of the component makes it obvious that a tag refers to a functional component and not an HTML tag.
"""
} %% .callout

Unlike our first code example, you may have noticed that all buttons now show the same "Default" text despite the fact that each `<.my_button>` has a different text! This happens because at the moment we, as creators of this new component, must teach HEEx how to render the content of its inner block. Update `page_live.ex` to render the inner block:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button>Default</.my_button>
    <.my_button>Green</.my_button>
    <.my_button>Red</.my_button>
    <.my_button>Yellow</.my_button>
    """
  end

  def my_button(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

The only change that happened in our `<.my_button>` was that we added the [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) function by passing an assign called `@inner_block`. This assign is automatically defined in components and is called a `slot` type. It contains the HTML inside your `<.component>`. From now on, anything written inside `<.my_button>` will be rendered there.

## Customizing components with attributes

Originally each button had its own color, whereas now they all have the same style. We can customize our buttons using assigns passed as attributes. Update `page_live.ex` to support a `color` attribute:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button color="blue">Default</.my_button>
    <.my_button color="green">Green</.my_button>
    <.my_button color="red">Red</.my_button>
    <.my_button color="yellow">Yellow</.my_button>
    """
  end

  def my_button(assigns) do
    ~H"""
    <button
      type="button"
      class={"text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800"}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

Now each use of the button has an assign of `color="..."` and we can customize our buttons in a much simpler way without duplicating code.

## Recap!

- You can create components in your LiveViews if you create a function that receives `assigns` and returns HEEx.
- HTML components and tags are separated by the presence of a leading `.` in its name to avoid conflicts.
- In a component you decide where to render the children nodes using `render_slot(@inner_block)`.
- Your components can reuse code efficiently with attributes.
