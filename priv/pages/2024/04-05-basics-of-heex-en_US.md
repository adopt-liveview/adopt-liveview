%{
title: "HEEx Basics",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "Learn how HEEx understands HTML in a different way",
previous_page_id: "heex-is-not-html",
next_page_id: "conditional-rendering"
}

---

To make your future easier on LiveView, let's learn some simple things about how HEEx works that will make your daily life more productive.

## Elixir rendering

Create and run a file called `elixir_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= "Lubien" %></h2>
    <h2>Hello <%= 1 + 1 %></h2>
    <h2>Hello <%= "Chris" <> " " <> "McCord" %></h2>
    <h2>Hello <% "King Crimson" |> IO.puts() %></h2>
    """
  end
end

LiveviewPlayground.start()
```

In this file we have 4 HEEx tags to interpolate code. HEEx supports rendering any type of code that implements the [`Phoenix.HTML.Safe`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html) protocol.

- The first case renders the string `"Lubien"`.
- The second case renders the integer 2.
- The third case just uses the string concatenation operator [`<>`](https://hexdocs.pm/elixir/1.12/Kernel.html#%3C%3E/2) whose result is "Chris McCord".

But what about the fourth case? Nothing appears on your screen. The reason is simple: we use the `<% %>` tag, note that there is no `=` after the first `%`. In HEEx this means "execute this code but do not render the result". As it uses the [`IO.puts/2`](https://hexdocs.pm/elixir/1.12/IO.html#puts/2) function, you can see the result in your terminal.

%{
title: "Then I can add logic to my HEEx!",
type: :warning,
description: ~H"""
The direct answer is yes, you can, however this means that every time your HEEx is recalculated when an assignment changes, your logic will be executed once again. <.link navigate="https://hexdocs.pm/phoenix_live_view/assigns-eex.html#pitfalls" target="\_blank">The Phoenix team's recommendation</.link> is that you do any logic in assigns to avoid possible performance problems. In the future we will learn other ways to have logic in your HEEx efficiently.
"""
} %% .callout

## Rendering something that cannot be converted to string

Create and run a file called `cant_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule User do
  defstruct id: nil, name: nil
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= %User{id: 1, name: "Lubien"} %></h2>
    """
  end
end

LiveviewPlayground.start()
```

You will notice an "Internal Server Error" and the exception in your terminal:

```elixir
** (exit) an exception was raised:
    ** (Protocol.UndefinedError) protocol Phoenix.HTML.Safe not implemented for %User{id: 1, name: "Lubien"} of type User (a struct). This protocol is implemented for the following type(s): Atom, BitString, Date, DateTime, Float, Integer, List, NaiveDateTime, Phoenix.HTML.Form, Phoenix.LiveComponent.CID, Phoenix.LiveView.Component, Phoenix.LiveView.Comprehension, Phoenix.LiveView.JS, Phoenix.LiveView.Rendered, Time, Tuple, URI
        (phoenix_html 3.3.3) lib/phoenix_html/safe.ex:1: Phoenix.HTML.Safe.impl_for!/1
        (phoenix_html 3.3.3) lib/phoenix_html/safe.ex:15: Phoenix.HTML.Safe.to_iodata/1
        priv/examples/basics-of-heex/cant_render.exs:14: anonymous fn/2 in PageLive.render/1
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:398: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
        (elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:396: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
```

You will notice an "Internal Server Error" and the exception in your terminal: As mentioned previously, the `Phoenix.HTML.Safe` protocol is necessary for us to render Elixir data. This happens not for reasons of LiveView limitations or security, the reason this protocol exists is because the Phoenix team converts the original Elixir data into a structure called `iodata` which is more efficient in being sent to its user.

If you just want to quickly debug data that cannot be rendered by HEEx, the recommendation would be to use inspect:`<h2>Hello <%= inspect(%User{id: 1, name: "Lubien"}) %></h2>`. If you really need to teach HEEx to interpret your struct you can also implement the protocol yourself. Create and run a file called `impl_phoenix_html_safe.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
], consolidate_protocols: false)

defmodule User do
  defstruct id: nil, name: nil
end

defimpl Phoenix.HTML.Safe, for: User do
  def to_iodata(user) do
    "User #{user.id} is named #{user.name}"
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= %User{id: 1, name: "Lubien"} %></h2>
    """
  end
end

LiveviewPlayground.start()
```

Using [`defimpl/3`](https://hexdocs.pm/elixir/1.14/Kernel.html#defimpl/3) we were able to define the protocol's `to_iodata/1` callback and convert the user to string (given that HEEx can render).

It is worth mentioning that if you decide to return any type of HTML here, you are responsible for ensuring that there is no vulnerability such as [XSS](https://owasp.org/www-community/attacks/xss/). Imagine if your user has a name with `<svg onload=alert(1)>` and you didn't escape this data? Therefore, avoid this practice whenever possible.

## Rendering of `nil`

Create and run a file called `nil_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= "Lubien" %></h2>
    <h2>Hello <%= nil %></h2>
    """
  end
end

LiveviewPlayground.start()
```

In this scenario we see that when the tag `<%= %>` receives `nil` the result is to render absolutely nothing. This will come in handy soon!

## HTML attribute rendering

Create and run a file called `attribute_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    bg_for_hello_phoenix = "bg-black"
    multiple_attributes = %{style: "color: yellow", class: "bg-black"}

    ~H"""
    <style>
    .color-red { color: red }
    .bg-black { background-color: black }
    .bg-red { background-color: red }
    </style>

    <h2 style="color: red" class={"bg-black"}>Hello World</h2>
    <h2 style={"color: white"} class={"bg-" <> "red"}>Hello Elixir</h2>
    <h2 class={[bg_for_hello_phoenix, nil, "color-red"]}>Hello Phoenix</h2>
    <h2 {multiple_attributes}>Hello LiveView</h2>
    """
  end
end

LiveviewPlayground.start()

```

There are multiple ways we can add HTML attributes in HEEx for developer convenience. Let's check each of them.

In the first case (Hello World) we add `style="color: red"` which works like any other HTML in the world. In this format it can be said that there is no type of extra processing. In `class={"bg-black"}` when using the keys we are saying that the content inside them comprises an Elixir code. Any Elixir code like `class={calculate_class()}` (assuming the function exists) or `class={"bg-{@my_background}"}` (assuming the assign exists) will be valid!

In the second case (Hello Elixir) we just demonstrate once again what was explained in the previous case. In `class={"bg-" <> "red"}` you can see an example of using the `<>` operator to calculate the final class.

In the third example (Hello Phoenix) there is a golden tip: you can pass an array with multiple strings to an attribute and at the end it will be automatically joined and values that are `nil` will be ignored. The reason this technique is powerful is that it makes it easier to work with variables, as we can see `bg_for_hello_phoenix` being used.

The last case (Hello LiveView) adds one more outside of working with attributes. If you ever need to add attributes dynamically, that is, you don't know exactly which attributes will or will not be included in advance, you can use the syntax of adding an elixir map within the opening HTML tag and HEEx will understand that each key in your map represents an attribute.

%{
title: "Can I use variables in my render function?",
description: ~H"""
Yes, there is no problem simply adding variables before your HEEx, especially if you do this just to make the code more readable (imagine you have an absurd amount of classes for example) but you will see warnings saying that the official recommendation is to transform these variables in assigns. In future classes we will learn how to do this in a very simple and readable way.
"""
} %% .callout

## Recap!

- Using the `<%= %>` tag renders Elixir code that the `Phoenix.HTML.Safe` protocol accepts.
- Using the `<% %>` tag just executes Elixir code and does not render anything.
- You can implement `Phoenix.HTML.Safe` for structs but you should be aware of the security risks this may bring.
- HEEx considers `nil` as something that should not be rendered, this is useful if you want to work with optional variables.
- In HEEx, HTML attributes with the value around curly braces execute any valid Elixir code to generate the attribute value.
- In HEEx, you can also pass lists to attributes to simplify mixing strings and variables.
- In HEEx, you can pass a map between braces in the HTML tag so that multiple attributes are added dynamically.
