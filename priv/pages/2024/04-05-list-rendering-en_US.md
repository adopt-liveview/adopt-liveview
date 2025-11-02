%{
title: "List rendering",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "Let's put some scale in HTML",
previous_page_id: "conditional-rendering",
next_page_id: "phx-value"
}

---

HEEx templates have many ways for you to render multiple elements from a list. Let's study each possibility and when to use each one of them.

## Rendering lists with `for` comprehension

Those who already have experience with Elixir already know `for` list comprehensions. It is completely viable within HEEx. Create and run a file called `classic_for.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

We can render any list into an assign using the format `<%= for item <- @items %>`. It is worth mentioning that the `=` in the tag is necessary for the result to be rendered.

%{
title: ~H"Why doesn't the <code>`food`</code> variable begins with <code>`@`</code>?",
description: ~H"""
Remember that <code>`@`</code> represents <code>`assigns.`</code>, the variable <code>`@foods`</code> comes precisely from assigns but the variable <code>`food`</code> is locally created by the <code>`for`</code> loop so it would not work using <code>`@`</code>.
"""
} %% .callout

Despite its simplicity, this method of rendering lists has two disadvantages:

1. The loop will be executed again every time any assign changes. It doesn't matter if the assign that changed is note related with the loop.
2. The list of elements will be saved in memory in LiveView while LiveView is alived for that user even if you don't need it.

## Avoid processing lists within HEEx

Let's say you don't want to render a specific element in the list. We could simply add a filter to our `for` comprehension. Create and run a file called `classic_for_filter.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods, food != "banana" do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Just by adding `, food != "banana"` we can remove an unwanted element! However, this introduces another problem in the way we render lists: every time an assign changes we will filter and render the list again.

The official recommendation from the Phoenix team is that you avoid doing any type of calculation within your `render/1` as much as possible, process your code before assigning them to your socket. Create and run a file called `classic_for_filter_beforehand.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    foods = Enum.filter(["apple", "banana", "carrot"], fn food -> food != "banana" end)
    socket = assign(socket, foods: foods)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

This time our `render/1` benefits from not having to process the filter over and over again and also from the fact that there are fewer elements to render!

## Simplifying list rendering with the special `:for` attribute

Just as the `if` block has the `:if` version, the `for` comprehension has its special HEEx attribute `:for`. Create and run a file called `special_for.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <li :for={food <- @foods}><%= food %></li>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Our code gained a little more readability and simplicity. However, this format has the same disadvantages as the previous method. How can we have list rendering that doesn't consume memory forever and that doesn't re-render when assigns change?

## Efficient rendering with streams

The Phoenix team added to LiveView an efficient way to manage large or potentially infinite lists called Streams. Create and run a file called `streams.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      stream(socket, :foods, [
        %{id: 1, name: "apple"},
        %{id: 2, name: "banana"},
        %{id: 3, name: "carrot"}
      ])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul id="food-stream" phx-update="stream">
      <li :for={{dom_id, food} <- @streams.foods} id={dom_id}>
        <%= food.name %>
      </li>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

We immediately can spot an increase in complexity in our code. Let's understand it step-by-step.

To define a stream we use the [`stream/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4) function. It receives our socket, the name of the stream as an atom and the initial value. As you can see we had to transform from a simple list of strings to a list of maps. The reason is that streams need an `id` in the stream item to be able to understand which elements have already been rendered on the page. Although it is a bit annoying for simple things, if we were working with a database the `id` would likely be already included.

The next modification happened in our HEEx code. The parent element of the list to be rendered must have a unique `id` attribute so that LiveView knows who contains the rendered elements and we must add a special `phx-update="stream"` attribute to define that children of this element are part of a stream.

Inside our `ul` we kept the special `:for` but this time we read the special assign `@streams.foods`. Every time a stream is created with `:some_name` you generate a special assign `@streams.some_name`. Not only that, our `:for` now loops elements with two variables inside a tuple: a `dom_id` and the `food` itself. The `dom_id` is necessary so that we can update/remove/move elements from our stream efficiently if necessary.

As you can imagine, streams are much more powerful than simple `:for` comprehensions. In the future we will talk more about streams in detail.

%{
title: "Should I always use streams?",
description: ~H"""
Don't let the demon of early optimization defeat you. If you're starting something, go simple and use <code>`for`</code> or <code>`:for`</code>. If you are going to work with many items, consider streams. I understand that storing lists in memory may seem wasteful but in reality we are talking about data that in general can be negligible because it is so small in terms of RAM usage depending on the size of your list.
"""
} %% .callout

## Recap!

- You can use the `for` block comprehension to render lists easily.
- HEEx also has a special attribute version `:for` to make your code simpler and more readable.
- Both `for` and `:for` solutions win in simplicity but require extra memory on the server and are executed again whenever an assign changes.
- LiveView has streams as a solution for efficient rendering of many or infinite data second only to the fact that it requires a slightly larger initial setup (unless you're using a database 😉).
