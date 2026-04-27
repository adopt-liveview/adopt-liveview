%{
title: "Components from other modules",
author: "Lubien",
tags: ~w(getting-started),
section: "Components",
description: "How to reuse components in more than one LiveView",
previous_page_id: "v2-documenting-components",
next_page_id: "v2-multiple-slots"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch documenting-components-done`</code>.
"""
} %% .callout

When we create a component as a function in a LiveView we gain access to it in our HEEx using `<.function_name>`. However if you need to use it in another LiveView you need to write the module name too. Open and edit `OtherLive` module:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <MyappWeb.PageLive.my_button color="blue">
      My other button
    </MyappWeb.PageLive.my_button>
    """
  end
end
```

This is not elegant at all. We could, perhaps, `alias` to our HEEx less verbose:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view
  alias MyappWeb.PageLive

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <PageLive.my_button color="blue">
      My other button
    </PageLive.my_button>
    """
  end
end
```

%{
title: ~H"<code>alias</code>",
description: ~H"""
In Elixir you can use alias to simplify references to nested modules. Instead of writting <code>MyApp.Deep.ModuleName.function</code> you can do <code>alias MyApp.Deep.ModuleName</code> so later you can write <code>ModuleName.function</code> instead.
"""
} %% .callout

## Getting to know CoreComponents

In Phoenix projects when we have certain components that are useful in various parts of our system we choose to share them in a module called CoreComponents and import them. Since `CoreComponents` already exists we will be creating `MyCoreComponents` for learning purposes. Create it at `lib/myapp_web/components/my_core_components.ex`:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :inner_block, required: true

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold">{render_slot(@inner_block)}</h1>
        <p class="mt-4 text-lg">My personal website</p>
        <.link
          class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded mr-2"
          navigate={~p"/"}
        >
          Homepage
        </.link>
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

Then update both `PageLive` and `OtherLive` like so:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view
  import MyappWeb.MyCoreComponents

  def render(assigns) do
    ~H"""
    <.hero>PageLive</.hero>
    <.my_button type="submit" style="color: red">Default</.my_button>
    """
  end
end
```

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view
  import MyappWeb.MyCoreComponents

  def render(assigns) do
    ~H"""
    <.hero>OtherPageLive</.hero>
    <my_button color="blue">
      My other button
    </my_button>
    """
  end
end

```

This time we also sneaked in a `<.hero>` component that was used to create pretty titles for each pages. In each of our LiveViews we manually use `import MyappWeb.MyCoreComponents`. Just in case you're wondering we `use Phoenix.Component` so we have access to HEEx related stuff like the `sigil_H`. We also `use MyappWeb, :verified_routes` so we can use `sigil_p` to write routes like `~p"/"` and `~p"/other"` in our `<.hero>` component.

## Meeting `MyappWeb.ex`

The whole point of `CoreComponents` (and in our case `MyCoreComponents`) is that they're components so important to the whole application that they're imported by default. Lets do it for our module just like Phoenix does for its own. Head out to `lib/myapp_web.ex`.

This module is magical. It uses secret incantations known only to the ancient ones as `macros`. Jokes aside, this module uses Elixir mechanism of defining a secret macro called `__using__` so whenever someone `use MyappWeb` they're calling `__using__` behind the scenes. Not that it matters to you though because all you actually need to understand is that `use MyappWeb, :something` will execute whatever it is inside `MyappWeb.something` at compile-time!

* `use MyappWeb, :static_paths` maps to `def static_paths`
* `use MyappWeb, :router` maps to `def router`
* `use MyappWeb, :channel` maps to `def channel`
* `use MyappWeb, :controller` maps to `def controller`
* `use MyappWeb, :live_view` maps to `def live_view`
* `use MyappWeb, :live_component` maps to `def live_component`
* `use MyappWeb, :html` maps to `def html`
* `use MyappWeb, :verified_routes` maps to `def verified_routes`

As you might already have noticed we do `use MyappWeb, :live_view` in all our LiveViews and inside it it will add `html_helpers/0` code at compile-time. Lets add `MyCoreComponents` to `html_helpers/0`:

```elixir
defp html_helpers do
  quote do
    # Translation
    use Gettext, backend: MyappWeb.Gettext

    # HTML escaping functionality
    import Phoenix.HTML
    # Core UI components
    import MyappWeb.CoreComponents
    import MyappWeb.MyCoreComponents

    # Common modules used in templates
    alias Phoenix.LiveView.JS
    alias MyappWeb.Layouts

    # Routes generation with the ~p sigil
    unquote(verified_routes())
  end
end
```

We added `import MyappWeb.MyCoreComponents` just below the actual `import MyappWeb.CoreComponents`. Dont forget to remove `import MyappWeb.MyCoreComponents` from `PageLive` and `OtherPageLive` too.

## Recap!

- You can use components from other modules using the `<MyappWeb.ModuleName.component_name>` syntax.
- You can use aliases to shorten module function calls like `alias MyappWeb.ModuleName` to use `<ModuleName.component_name>` syntax.
- If the component in question is used in a lot of places in the application consider placing it in your `CoreComponents`.
- Behind the scenes `use MyappWeb, :something` just inserts code from `MyappWeb`'s `def somethind() do` into your module so you have access to all tools needed to do your work.
