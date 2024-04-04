%{
title: "Anatomy of a LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Introduction",
description: "What does each piece of code here mean?"
}

---

## Understanding the parties

Let's return to the code from the previous step:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end

LiveviewPlayground.start()
```

## Understanding `Mix.install`

Mix is the tool that manages and compiles projects in Elixir. For Elixir scripts, the function [`Mix.Install/2`](https://hexdocs.pm/mix/1.12.3/Mix.html#install/2) is used to install dependencies without having to create an entire Mix project . In practice, you will rarely host LiveView projects using `.exs` scripts ([although it is possible](https://fly.io/phoenix-files/single-file-elixir-scripts/) and valid depending on your project) However, for studies this is enough.

%{
title: ~H"Hey, what was that <code>/2</code> you said in <code>Mix.install/2</code>?",
description: ~H"""
In Elixir the functions are different depending on the number of arguments. So just as there is the function <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/1" target="\_blank"><code>Enum.count/1</code></.link> there is also the <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/1" target="\_blank"><code>Enum.count/2</code></.link> which takes two arguments and they are different functions. It is worth mentioning that this number of arguments represents the <strong class="text-white">arity of the function</strong>. A function that accepts one argument is a unary function A function that accepts two arguments is a binary function A function that accepts three arguments is a ternary function.
"""
} %% .callout

## The PageLive module

For convenience, `LiveviewPlayground` always looks for a `PageLive defmodule` to use by default. If you forget to write it you will see an error in the system. We will see later that this name doesn't matter that much and can be called anything when we study Phoenix's `Router`.

The first line of the `use LiveviewPlaygroundWeb, :live_view` module is important to understand and you will see it in all LiveView applications. The `use` macro works behind the scenes as a way to execute code at compile time. Think of it as "by the time this code compiles, things will be added." When we study the `LiveviewPlaygroundWeb` module everything will become clearer but you just need to know now that almost every time you make a LiveView its module will have something like `use WebProjectName, :live_view`.

```elixir
def render(assigns) do
  ~H"""
  Hello World
  """
end
```

Finally, the minimum for you to have a LiveView is, amazingly, the View. That is, a function that explains which HTML code will be shown to your user. Every LiveView (without exception) has a rendering function that exclusively receives an argument called `assigns` (we'll talk about them later). All your `render function` needs to do is return valid HTML using [sigil_H/2](https://hexdocs.pm/phoenix_live_view/0.17.0/Phoenix.LiveView.Helpers.html#sigil_H/2).

%{
title: ~H"<code>sigil_H/2</code>?",
description: ~H"""
In Elixir, <code>sigils</code> are binary functions (take 2 arguments) that are used to transform text into something else. <code>sigil_H/2</code> transforms valid HTML into an optimized data structure for sending HTML to your user. <strong class="text-white">Do we need to know how it works?</strong> No! But we will see in the future only the level of curiosity in advanced topics.
"""
} %% .callout

## Recap!

- Mix is the Elixir project compilation tool.
- `Mix.install/2` is useful for simple projects and is generally not used to host LiveView in production.
- All LiveViews have a `render function` and always receive an argument called `assigns`.
- `use SeuProjetoWeb, :live_view` adds things at compile time to make your LiveView work properly.
