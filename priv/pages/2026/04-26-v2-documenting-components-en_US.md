%{
title: "Validating components",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "Making it easier to maintain a project for the future",
previous_page_id: "v2-function-component",
next_page_id: "v2-components-from-other-modules"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch function-component-done`</code>.
"""
} %% .callout

Elixir is a language that early on brought an incredible documentation tool called ExDoc. The Phoenix team followed the same direction and made documenting LiveView components not only simple but also capable of adding superpowers to your LiveView. Update your `page_live.ex` like this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button color="blue">Welcome</.my_button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.my_button color="red">Delete account</.my_button>
  """
  attr :color, :string, required: true
  slot :inner_block, required: true

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

The first way to document your component is to use ExDoc's `@doc` tag where you briefly explain what the component does and add one or more examples.

The next features are specific to Phoenix. You can use the [`attr/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3) macro to document the component below its call. Each use of `attr` defines an attribute to be received. An extra feature of using `attr/3` is that in Phoenix projects [the compiler will validate](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3-compile-time-validations) that there are no extra, missing or incorrect attributes! By simply documenting your component you already gain extra validation.

Last but not least, we also document that our component uses slots using [`slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/2). Similar to `attr/3`, `slot/2` also [validates its components at compile time](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/3-compile-time-validations) and serves to document your code.

## Using `attr/3` to generate default values

In our example above we must always pass the color attribute. If you've already worked with other component libraries, you'll notice that there is always a default style when you don't choose a specific color. It is always useful to have a default color for your design system. You can do this by passing a config via `attr/3` as `default: "blue"`.

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button>Default</.my_button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue"
  slot :inner_block, required: true

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

We not only removed `color="blue"` from our `render/1` function but also added another example in the documentation where we can use the button without passing a `color`. It is worth mentioning that in `attr/3` the `default` and `required` options are mutually exclusive: either you have a default if it is not passed or you ask whoever uses this component to always pass a value.

## Using `attr/3` to define possible values

The `attr/3` function also contains two other mutually exclusive properties: `examples` and `values`. If you are interested in only certain colors being accepted by your component, use `values` as follows: `attr :color, :string, default: "blue", values: ~w(blue red yellow green)`. If it is in your interest not to limit it to certain values but to provide some examples, simply change `values` to `examples`. It is worth mentioning that this configuration will not prevent the wrong values from being used at runtime; it will only help you by providing warnings at compile time.

%{
title: ~H"What is this <code>`~w(x y z)`</code> there?",
description: ~H"""
<.link navigate="https://hexdocs.pm/elixir/1.16.2/Kernel.html#sigil_w/2" target="\_blank"><code>`sigil_w`</code></.link> serves as a simplified way to create string lists. Essentially <code>`["blue", "green"]`</code> can be written as <code>`~w(blue green)`</code>. With this sigil, we don't need commas or quotation marks, just place the values inside the parentheses.
"""
} %% .callout

## Using `attr/3` to define classes

Our button customization is currently limited. To be able to receive new classes, we need to create a new `attr`. Update `page_live.ex` to add a `class` attribute:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button class="text-red-500">Default</.my_button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button class="text-blue-500">Save data</.my_button>
      <.my_button color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def my_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

Using a HEEx feature mentioned in a previous lesson, we converted our `class` attribute to receive a list. As the default value of assign `class` is `nil`, it will be ignored. We intentionally placed `@class` as the final element because if there are classes that change the same CSS properties as those of the component, the new class could take precedence.

## Multiple optional properties

As you can see, our button currently just works as `type="button"`. If we want to be able to change the type to `"submit"` or `"reset"` we would have to create a new `attr`. This manual process of creating an `attr` gets repetitive very quickly. If you just want to pass through all other attributes coming from using the component, HEEx has a solution. Update `page_live.ex` to support global attributes:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button type="submit" style="color: red">Default</.my_button>
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

Generally called `:rest` (but any name will do), we can define an attribute of type `:global` using `attr/3`. We can also add its `default` as a map with all the default properties. We can also say which properties will be accepted by our global attribute, in this case, `type="..."` and `style="..."`.

## Recap!

- You can use `@doc` to document your component and show examples.
- Using `attr/3` you can document and enhance your component:
  - You can set a value as `required`.
  - You can set a default value if something is not passed using `default`.
  - You can limit the possible values using `values`.
  - You can exemplify possible values using `examples`.
  - You can capture all extra properties with an `attr` of type `:global`.
