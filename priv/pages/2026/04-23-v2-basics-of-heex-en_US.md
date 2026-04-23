%{
title: "HEEx Basics",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "Learn how HEEx understands HTML in a different way",
previous_page_id: "v2-heex-is-not-html",
next_page_id: "v2-conditional-rendering"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

To make your future easier on LiveView, let's learn some simple things about how HEEx works that will make your daily life more productive.

## Elixir rendering

Lets update `page_live.ex` to this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {"Lubien"}</h2>
    <h2>Hello {1 + 1}</h2>
    <h2>Hello {"Chris" <> " " <> "McCord"}</h2>
    <h2>Hello <% "King Crimson" |> IO.puts() %></h2>
    """
  end
end
```

In this file we have 3 HEEx interpolations and a tag in our code. HEEx supports rendering any type of code that implements the [`Phoenix.HTML.Safe`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html) protocol.

- The first case renders the string `"Lubien"`.
- The second case renders the integer 2.
- The third case just uses the string concatenation operator [`<>`](https://hexdocs.pm/elixir/1.12/Kernel.html#%3C%3E/2) whose result is "Chris McCord".

But what about the fourth case? Nothing appears on your screen. The reason is simple: we use the `<% %>` tag, do note that there is no `=` after the first `%`. In HEEx this means "execute this code but do not render the result". As it uses the [`IO.puts/2`](https://hexdocs.pm/elixir/1.12/IO.html#puts/2) function, you can see the result in your terminal.

%{
title: "Then I can add logic to my HEEx!",
type: :warning,
description: ~H"""
The direct answer is yes, you can, however this means that your logic will be executed every time your HEEx is recalculated when an assignment changes. <.link navigate="https://hexdocs.pm/phoenix_live_view/assigns-eex.html#common-pitfalls" target="\_blank">The Phoenix team's recommendation</.link> is that you do any logic in assigns to avoid possible performance problems. In the future we will learn other ways to have logic in your HEEx efficiently.
"""
} %% .callout

## Rendering something that cannot be converted to string

Now lets try this:

```elixir
defmodule User do
  defstruct id: nil, name: nil
end

defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {%User{id: 1, name: "Lubien"}}</h2>
    """
  end
end
```

You will notice an "Internal Server Error" and the exception in your terminal:

```elixir
[info] GET /
[debug] Processing with MyappWeb.PageLive.__live__/0
  Parameters: %{}
  Pipelines: [:browser]
[info] Sent 500 in 50ms
[error] ** (Protocol.UndefinedError) protocol Phoenix.HTML.Safe not implemented for User (a struct). This protocol is implemented for: Atom, BitString, Date, DateTime, Decimal, Duration, Float, Integer, List, NaiveDateTime, Phoenix.LiveComponent.CID, Phoenix.LiveView.Component, Phoenix.LiveView.Comprehension, Phoenix.LiveView.JS, Phoenix.LiveView.Rendered, Time, Tuple, URI

Got value:

    %User{id: 1, name: "Lubien"}

    (phoenix_html 4.3.0) lib/phoenix_html/safe.ex:1: Phoenix.HTML.Safe.impl_for!/1
    (phoenix_html 4.3.0) lib/phoenix_html/safe.ex:15: Phoenix.HTML.Safe.to_iodata/1
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:10: anonymous fn/2 in MyappWeb.PageLive.render/1
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:420: Phoenix.LiveView.Diff.traverse/6
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:146: Phoenix.LiveView.Diff.render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:291: Phoenix.LiveView.Static.to_rendered_content_tag/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:171: Phoenix.LiveView.Static.do_render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/controller.ex:39: Phoenix.LiveView.Controller.live_render/3
    (phoenix 1.8.1) lib/phoenix/router.ex:416: Phoenix.Router.__call__/5
    (myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
    (myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
    (myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
    (phoenix 1.8.1) lib/phoenix/endpoint/sync_code_reload_plug.ex:22: Phoenix.Endpoint.SyncCodeReloadPlug.do_call/4
    (bandit 1.8.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2
    (bandit 1.8.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5
    (bandit 1.8.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3
    (bandit 1.8.0) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3
    (bandit 1.8.0) lib/bandit/delegating_handler.ex:8: Bandit.DelegatingHandler.handle_continue/2
    (stdlib 7.0.1) gen_server.erl:2424: :gen_server.try_handle_continue/3
    (stdlib 7.0.1) gen_server.erl:2291: :gen_server.loop/4
```

As mentioned previously, the `Phoenix.HTML.Safe` protocol is necessary for us to render Elixir data. The reason this protocol exists is that the Phoenix team converts the original Elixir data into a structure called `iodata` which is more efficient in being sent to its user.

If you just want to quickly debug data that cannot be rendered by HEEx, the recommendation would be to use inspect: `<h2>Hello {inspect(%User{id: 1, name: "Lubien"})}</h2>`. If you really need to teach HEEx to interpret your struct you can also implement the protocol yourself. Updating the example from before:

```elixir
defmodule User do
  defstruct id: nil, name: nil
end

defimpl Phoenix.HTML.Safe, for: User do
  def to_iodata(user) do
    "User #{user.id} is named #{user.name}"
  end
end

defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {%User{id: 1, name: "Lubien"}}</h2>
    """
  end
end
```

Using [`defimpl/3`](https://hexdocs.pm/elixir/1.14/Kernel.html#defimpl/3) we were able to define the protocol's `to_iodata/1` callback and convert the user to string (something that HEEx can render).

It is worth mentioning that if you decide to return any type of HTML here, you are responsible for ensuring that there is no vulnerability such as [XSS](https://owasp.org/www-community/attacks/xss/). Imagine if your user has a name with `<svg onload=alert(1)>` and you didn't escape this data? Therefore, avoid this practice whenever possible.

## Rendering of `nil`

Lets simplify our code to just this:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {"Lubien"}</h2>
    <h2>Hello {nil}</h2>
    """
  end
end

```

In this scenario we see that when the interpolation `{}` receives `nil` the result is to render absolutely nothing. This will come in handy soon!

## HTML attribute rendering

Now try this out:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    bg_for_hello_phoenix = "bg-black"
    multiple_attributes = %{style: "color: yellow", class: "bg-black"}

    ~H"""
    <style>
      .color-red { color: red }
      .bg-black { background-color: black }
      .bg-red { background-color: red }
    </style>

    <h2 style="color: red" class="bg-black">Hello World</h2>
    <h2 style="color: white" class={"bg-" <> "red"}>Hello Elixir</h2>
    <h2 class={[bg_for_hello_phoenix, nil, "color-red"]}>Hello Phoenix</h2>
    <h2 {multiple_attributes}>Hello LiveView</h2>
    """
  end
end
```

There are multiple ways we can add HTML attributes in HEEx for developer convenience. Let's check each of them.

In the first case (Hello World) we add `style="color: red"` which works like any other HTML in the world. In this format there are no type of extra processing steps. In `class={"bg-black"}` when using brackets we are saying that the content inside them is Elixir code. Any Elixir code like `class={calculate_class()}` (assuming the function exists) or `class={"bg-#{@my_background}"}` (assuming the assign exists) will be valid!

In the second case (Hello Elixir) we just demonstrate once again what was explained in the previous case. In `class={"bg-" <> "red"}` you can see an example of using the `<>` operator to calculate the final class.

In the third example (Hello Phoenix) there is a golden tip: you can pass a list with multiple strings to an attribute and at the end it will be automatically joined and values that are `nil` will be ignored. The reason this technique is powerful is that it makes it easier to work with variables, as we can see `bg_for_hello_phoenix` being used.

The last case (Hello LiveView) adds one more way of working with attributes. If you ever need to add attributes dynamically, that is, you don't know exactly which attributes will or wont be included in advance, you can use the syntax of adding an elixir map within the opening HTML tag and HEEx will understand that each key in your map represents an attribute.

%{
title: "Can I use variables in my render function?",
description: ~H"""
Yes, there is no problem simply adding variables before your HEEx, especially if you do this just to make your code more readable (imagine you have an absurd amount of classes for example) but you will see warnings saying that the official recommendation is to transform these variables in assigns. In future lessons we will learn how to do this in a very simple and readable way.
"""
} %% .callout

## A sidenote for an old syntax

Before interpolations like `{this}` existed the default way for HEEx to render things in HTML was the tag `<%= this %>`. Similar to the `<% %>` tag (which doesnt render), this one comes with a `=`. Nowadays if you use formatters on new projects they will be automatically converted to interpolations unless they fall into very [specific cases](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2-interpolating-blocks).

## Recap!

- Using the `{}` tag renders Elixir code that the `Phoenix.HTML.Safe` protocol accepts.
- Using the `<% %>` tag just executes Elixir code and does not render anything.
- You can implement `Phoenix.HTML.Safe` for structs but you should be aware of the security risks this might bring.
- HEEx considers `nil` as something that should not be rendered, this is useful if you want to work with optional variables.
- In HEEx, HTML attributes with the value around curly braces execute any valid Elixir code to generate the attribute value.
- In HEEx, you can also pass lists to attributes to simplify mixing strings and variables.
- In HEEx, you can pass a map between braces in the HTML tag so that multiple attributes are added dynamically.
- Old projects would have the tag interpolation syntax `<%= %>` instead.
