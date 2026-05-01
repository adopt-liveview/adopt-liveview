%{
title: "Anatomy of a LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Introduction",
description: "What does each piece of code here mean?",
previous_page_id: "v2-first-liveview",
next_page_id: "v2-mounts-and-assigns"
}

---

## Understanding each part

Let's return to the code from the previous step:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end
```

## Understanding `mix`

Mix is the tool that manages and compiles projects in Elixir. Phoenix projects can be started by running `mix phx.server` in the project directory. We call these commands Mix tasks and the `phx.server` task is defined by the Phoenix framework. Over this course we will learn more tasks that Phoenix creates for us to help the day-to-day development workflow.

If you used Phoenix Express installation method you might not have seen but one of the steps to install a Phoenix project locally was running `mix setup`. This is known as a task `alias` which is just a mix task that runs a list of other tasks. You can check aliases in your `mix.exs` file:

```elixir
defmodule MyApp.MixProject do
  #... more stuff

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      # ... more stuff
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind myapp", "esbuild myapp"],
      # ... more stuff
    ]
  end
end
```

The `mix setup` task is meant to simplify a lot of necessary steps to get started. In Phoenix projects `mix setup` then `mix phx.server` should be enough to get you working in that project. In earlier versions of Phoenix you might not see that alias available so you'd want to read the README of that project to see how to get started.

## The PageLive module

The minimum for you to have a LiveView is, shockingly, the view. That is, a function that explains which HTML code will be shown to your user. Every LiveView (without exception) has a `render/1` function that exclusively receives an argument called `assigns` (we'll talk about them later). All your render functions need to do is return valid HTML using [sigil_H/2](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2).

%{
title: ~H"Hey, what was that <code>/1</code> you said in <code>render/1</code>?",
description: ~H"""
In Elixir the functions are different depending on the number of arguments. So just as there's a function called <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/1" target="\_blank"><code>Enum.count/1</code></.link> there is also the <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/2" target="\_blank"><code>Enum.count/2</code></.link> function which takes two arguments and they are different. It is worth mentioning that this number of arguments represents the <strong class="text-black dark:text-white">arity of the function</strong>. A function that accepts one argument is an unary function. A function that accepts two arguments is a binary function. A function that accepts three arguments is a ternary function.
"""
} %% .callout


```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end
```

The first line of the module, `use MyappWeb, :live_view`, is important and you will see it in all LiveView applications. The `use` macro works behind the scenes as a way to execute code at compile time. Think of it as "by the time this code compiles, things will be added." When we study the `MyappWeb` module everything will become clear but you just need to know now that almost every time you make a LiveView, its module will have something like `use MyappWeb, :live_view`.

%{
title: ~H"<code>sigil_H/2</code>?",
description: ~H"""
In Elixir, <code>sigils</code> are binary functions (take 2 arguments) that are used to transform text into something else. <code>sigil_H/2</code> transforms valid HTML into an optimized data structure to send HTML to your user. <strong class="text-black dark:text-white">Do we need to know how it works?</strong> No! But we will see it in the future only for curiosity's sake in advanced topics.
"""
} %% .callout

## Recap!

- Mix is the Elixir project compilation tool.
- `mix setup` is useful to get started on projects you just cloned.
- All LiveViews have a `render/1` function and always receive an argument called `assigns`.
- `use MyappWeb, :live_view` adds things at compile time to make your LiveView work properly.
