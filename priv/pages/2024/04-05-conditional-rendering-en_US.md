%{
title: "Conditional rendering",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "To render or not to render, that is the question",
previous_page_id: "basics-of-heex",
next_page_id: "list-rendering"
}

---

Let's learn some ways to render HTML depending on certain conditions. Create and run a file called `toggle.exs`:

## Using `if-else` for simple cases

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% else %>
        <p>You can't see this message!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Let's break down this code. The only assign we have here is called `show_information?` with an initial value of false. The `"toggle"` event sent by the input simply reverses the value between `true` and `false`. What's really new here is our `if-else` block.

%{
title: "Question mark in the middle of the code? Is that even possible?",
description: ~H"""
In Elixir the question mark is valid in atoms and variables when added at the end. This is very useful for booleans. isn't <code>`if @show_information?`</code> elegant?
"""
} %% .callout

Inside a LiveView you can do an `if-else` as follows:

- Add a `<%= if condition do %>`. It is important that you use the tag that contains `=` otherwise HEEx will understand that this should not be rendered!
- Write any HTML that will be in the case that should be rendered.
- Add an `<% else %>`. Note that there is no `=` this time. If you add it, the code continues to work but a warning will ask to remove it.
- Write any HTML for the `else` case.
- Add a `<% end %>`. Again, without `=`.

If you don't want to show an `else` case there are two ways to do this. The first is simple: just remove the `<% else %>` and its contents! Create and run a file called `toggle_without_else.ex`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

## The special attribute `:if`

For cases where you only have `if`, HEEx has a special attribute called `:if` that you can place directly in the HTML tag. Create and run a file called `toggle_special_if.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={@show_information?}>You're an amazing person!</p>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

At the moment there is no special attribute for `else` so if you only need `if` it is recommended to use `:if` when you can put it in a parent tag of the things that enter the condition, otherwise use the first example with `if-else` as shown above.

## Using `case` for complex cases

It's only a matter of time before you end up in a situation where there are more than two possibilities for rendering something. Elixir does not support `else if` and for good reason: the preference is `case` which is much more powerful!

Let's create a simple tab system in LiveView. Create and run a file called `case.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

This time our assign became `tab` which can be a string between `"home"`, `"about"` or `"contact"`. Each input contains a `phx-click="show_TAB_NAME"` so our `handle_event/3` will use pattern matching in Elixir to accept any event that starts with `show_` and save the rest of the event name in a variable. Another simple but interesting bit in our code is that we use the HTML `disabled` property to prevent the button from being clickable if you are already on the correct tab.

%{
title: "Pattern matching?!",
description: ~H"""
In Elixir pattern matching is a common and very powerful technique that, once you learn it, you can't help but want to use it. Since the scope of this course is to talk about LiveView, don't feel like it's necessary for you to stop everything to study more about it. To learn more about it Elixir School talks about it here: <.link navigate="https://elixirschool.com/en/lessons/basics/functions" target="\_blank">Functions - Pattern Matching</.link>.
"""
} %% .callout

Now let's talk about what's important for this class: `case`. Just like `if` you need to start the conditional with `<%= case (condition here) do %>`, emphasis on `=` because without it nothing will be rendered. Since our condition passed to `case` was `@tab`, each condition will essentially check `@tab == 'value'`. For each condition we do an `<% "expected value" -> %>` (without the need for `=`) and end the block with `<% end %>`.

It is worth mentioning that in our case we handled all cases. What if we forget a possibility? Create and run a file called `case_missing.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    <input disabled={@tab == "blog"} type="button" value="Open Blog" phx-click="show_blog" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

In this example we added a new button to show a blog tab but we did not add a clause in our `case` to handle this value from our assign. When you click on "Open Blog" you should notice that your LiveView resets to its original state and an exception appears in your terminal:

```elixir
07:18:46.498 [error] GenServer #PID<0.376.0> terminating
** (CaseClauseError) no case clause matching: "blog"
    priv/examples/conditional-rendering/case_missing.exs:16: anonymous fn/2 in PageLive.render/1
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:375: Phoenix.LiveView.Diff.traverse/7
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
    (elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:373: Phoenix.LiveView.Diff.traverse/7
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:833: Phoenix.LiveView.Channel.render_diff/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:689: Phoenix.LiveView.Channel.handle_changed/4
Last message: %Phoenix.Socket.Message{topic: "lv:phx-F8E02o_S_TzHVAEB", event: "event", payload: %{"event" => "show_blog", "type" => "click", "value" => %{"value" => "Open Blog"}}, ref: "13", join_ref: "12"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-F8E02o_S_TzHVAEB", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.376.0>, router: LiveviewPlayground.Router, assigns: %{tab: "home", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.371.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-F8E02o_S_TzHVAEB", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "12", upload_names: %{}, upload_pids: %{}}
```

The message could not be more explicit! Let's analyze each piece:

- The exception is `CaseClauseError` making it obvious that a case is missing.
- The error message itself makes it clear that the missing case is called "blog".
- If you look at "Last message" you can see that the event that caused the problem was `"show_blog"`. This makes it easier for you to understand which part of your LiveView initiated the problem so that you can reproduce locally and handle the error.

To add a default clause simply use the format `<% _ -> %>`. In Elixir the `_` in the context of pattern matching means "anything". We could add default content like `<p>Tab does not exist</p>`.

%{
title: "What to do when we don't know how to handle all cases?",
type: :warning,
description: ~H"""
It all depends on the UX you intend to give your user. By using a default clause you fail silently giving the user an experience that your system is incomplete. If you intentionally leave it without a default clause, the system will restart LiveView, which creates discomfort for your user as well, but if you have an APM you will see the exception and can correct it afterwards. In the future we will discuss validations as a solution for these cases.
"""
} %% .callout

## Condition chains with `cond`

In the previous example we used `case` to compare the exact value of the `@tab` variable in each clause. If you need to render something based on a condition that does is not about equality, `cond` is perfect for this. Create and run a file called `cond.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: <%= @temperature_celsius %>C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="Increase" phx-click="increase" />
    <input type="button" value="Decrease" phx-click="decrease" />
    """
  end

  def handle_event("increase", _params, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + 10)
    {:noreply, socket}
  end
  def handle_event("decrease", _params, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius - 10)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

In the next example we manage the temperature in degrees Celsius increasing/decreasing by 10. The really important part of the code is precisely our conditional. Once again we notice that only the first tag has `=` while the others do not. The first difference between `cond` and `case` is that in `cond` you always start with `cond do` without passing anything different, the conditions are independent and may well use different variables.

Each `cond` clause follows the predicate format (an expression that returns true or false) and the first condition that is true ends the flow and renders its corresponding HTML. As the order of checking the clauses is from top to bottom we do not need to do checks like `@temperature_celsius > 30 && @temperature_celsius < 40 ->` because if the condition `@temperature_celsius > 40 ->` did not return true we already know that in the second clause we already have a temperature below 40. Unlike `case`, to add a standard clause we added `true ->` at the end because as `true` is hardcoded and this is the last clause it will always end there.

## Recap!

- For `if-else` situations you must explicitly use the `<%= if condition do %>` and `<% else %>` blocks.
- For `if` only situations you can use the `<%= if condition do %>` block format or the special HEEx attribute `:if={condition}` in an HTML tag.
- For multiple comparisons of a value you can use `<%= case value of %>`.
- For multiple conditions that don't just involve comparing whether a value is equal to something you can use `<%= cond do %>`.
- In all cases, the first tag will always need `=` and the others do not need it. If you add `=` to the other tags, LiveView will generate warnings but everything will work normally.
- If in the first tag you do not add `=` the HTML code will not be rendered.
