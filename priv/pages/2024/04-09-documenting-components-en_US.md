%{
title: "Validating components",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "Making it easier to maintain a project for the future",
previous_page_id: "function-component",
next_page_id: "components-from-other-modules"
}

---

Elixir is a language that early on brought incredible documentation tools called ExDoc. The Phoenix team follows the same direction and made documenting LiveView components not only simple but also capable of adding superpowers to your LiveView. Create and run `basic_component_doc.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button color="blue">Welcome</.button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.button color="red">Delete account</.button>
  """
  attr :color, :string, required: true
  slot :inner_block, required: true

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

The first way to document your component is to use ExDoc's `@doc` tag where you briefly explain what the component does and add one or a few examples.

The next new feature is specific to Phoenix. You can use the [`attr/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3) macro to document the component below its call. Each use of `attr` defines an attribute to be received. An extra feature of using `attr/3` is that in Phoenix projects [the compiler will validate](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3-compile-time-validations) that there are no extra, missing or incorrect attributes! By simply documenting your component you already gain extra validation.

%{
title: ~H"Validation of <code>`attr/3`</code> and LiveView Playground",
type: :warning,
description: ~H"""
So far, LiveView Playground is unable to check the validity of components using <code>`attr/3`</code>. Our recommendation is that you continue using them by default because in real Phoenix projects this will be a super power for your codebase.
"""
} %% .callout

Finally, we also document that our component uses slots using [`slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/2). Similar to `attr/3`, `slot/2` also [validates its components at compile time](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/3-compile-time-validations) and serves to document your code.

## Using `attr/3` to generate default values

In our example above we always must pass the color attribute. If you've already worked with other component libraries you'll notice that there is always a default style when you don't choose a specific color. It is useful to have a default color for your design system. You can do this by passing a config via `attr/3` as `default: "blue"`.

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button>Default</.button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.button>Save data</.button>
      <.button color="red">Delete account</.button>
  """
  attr :color, :string, default: "blue"
  slot :inner_block, required: true

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

We not only removed `color="blue"` from our `render/1` function but also added another example in the documentation where we can use the button without passing a `color`. It is worth mentioning that in `attr/3` the `default` and `required` options are mutually exclusive: either you have a default if it is not passed or you ask whoever uses this component to always pass a value.

## Using `attr/3` to define possible values

The `attr/3` function also contains two other mutually exclusive properties: `examples` and `values`. If you are interested in only certain colors being accepted by your component use `values` as follows: `attr :color, :string, default: "blue", values: ~w(blue red yellow green)`. If it is in your interest not to limit it to certain values but to provide some examples simply change `values` to `examples`. It is worth mentioning that this configuration will not prevent the wrong values from being used at run time it will only help you by providing warnings at compile time.

%{
title: ~H"What is this <code>`~w(x y z)`</code> there?",
description: ~H"""
<.link navigate="https://hexdocs.pm/elixir/1.16.2/Kernel.html#sigil_w/2" target="\_blank"><code>`sigil_w`</code></.link> serves as a simplified way to create string lists. Essentially <code>`["blue", "green"]`</code> can be written as <code>`~w(blue green)`</code>. With this sigil we don't need commas or quotation marks, just place the values inside the parentheses.
"""
} %% .callout

## Using `attr/3` to define classes

Our button is currently that customizable. To be able to receive new classes we need to create a new `attr`. Create and run a file called `class_attr.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button class="text-red-500">Default</.button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.button>Save data</.button>
      <.button class="text-blue-500">Save data</.button>
      <.button color="red">Delete account</.button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Using a HEEx feature mentioned in a previous lesson we converted our `class` attribute to receive a list. As the default value of assign `class` is `nil` it will be ignored. We intentionally placed `@class` as the final element because if there are classes that change the same CSS properties as those of the component the new class could take precedence.

## Multiple optional properties

As you can see our button currently just works as `type="button"`. If we want to be able to change the type to `"submit"` or `"reset"` we would have to create a new `attr`. This manual process of creating an `attr` gets repetitive very quickly. If you just want to pass on the other attributes coming from using the component HEEx has a solution. Create and run a file called `global_attrs.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button type="submit" style="color: red">Default</.button>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Save data</.button>
      <.button type="submit" class="text-blue-500">Save data</.button>
      <.button type="submit" color="red">Delete account</.button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  attr :rest, :global, default: %{type: "button"}, include: ~w(type style)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Generally called `:rest` (but any name will do) we can define an attribute of type `:global` using `attr/3`. We could also add its `default` as a map with all the default properties. We could also say which properties will be accepted by our global attribute, in this case, `type="..."` and `style="..."`.

## Recap!

- You can use `@doc` to document your component and show examples.
- Using `attr/3` you can document and enhance your component:
  - You can set a value as `required`.
  - You can set a default value if something is not passed using `default`.
  - You can limit the possible values using `values`.
  - You can exemplify possible values using `examples`.
  - You can capture all extra properties with an `attr` of type `:global`.
