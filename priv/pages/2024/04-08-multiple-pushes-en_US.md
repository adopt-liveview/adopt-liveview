%{
title: "More than one event triggered",
author: "Lubien",
tags: ~w(getting-started),
section: "Events",
description: "How to activate 2+ events in one click?",
previous_page_id: "js-push",
next_page_id: "your-second-liveview"
}

---

Imagine that we are building a points system for a competition between two players. Winning awards 3 points to the winner and drawing awards 1 point to both. If we have code like below to award wins, how can we build a third button for a draw match? Do we need a third event?

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={JS.push("add_points", value: %{team: :red, amount: +3})}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={JS.push("add_points", value: %{team: :blue, amount: +3})}
    />
    ?????????
    """
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Let's analyze what we have so far. Our LiveView has two integer-valued assigns: `:red` and `:blue`. When we click on the "Red Wins" button we trigger an event called `"add_points"` with value `%{team: :red, amount: +3}`.

Our handle `handle_event/3` receives at the `"add_points"` event a map in the format `%{"team" => "red", "amount" => +3}`. We convert the string `"red"` into the atom `:red` and look for the current value in our assigns. Soon after, we update the socket so that the corresponding team receives the `amount` in points.

%{
title: ~H"In HEEx I wrote <code>`:red`</code> in the <code>`team`</code> property, shouldn't the event receive an atom?",
description: ~H"""
JS Commands serialize data into JSON to store on the client. Data that is compatible with Elixir types such as Elixir's Integer and JSON's Integer works normally. Atoms doesn't exist in JSON therefore they are converted into strings.
"""
} %% .callout

%{
title: ~H"How does <code>`socket.assigns[team_atom]`</code> work?",
description: ~H"""
Assigns in LiveView are just elixir maps using atoms (a key-value structure basically). In this LiveView the assigns would be <code>`%{red: 0, blue: 0}`</code>. In Elixir you can dynamically get data from a map using the <code>`map[:atom]`</code> syntax, so <code>`socket.assigns[:red]`</code> works just as well as <code>`socket.assigns.red`</code> does. If you have any questions, we recommend <.link navigate="https://elixirschool.com/en/lessons/basics/collections#maps-6">this short class from Elixir School</.link>.
"""
} %% .callout

## Chaining JS Commands

Fortunately JS Commands can be combined using the pipe operator. Create and run a file named `multiple_pushes.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={JS.push("add_points", value: %{team: :red, amount: +3})}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={JS.push("add_points", value: %{team: :blue, amount: +3})}
    />
    <input
      type="button"
      value="Draw"
      phx-click={
        JS.push("add_points", value: %{team: :blue, amount: +1})
        |> JS.push("add_points", value: %{team: :red, amount: +1})
      }
    />
    """
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

The only difference from the original code to this one is that the `phx-click` binding has two `JS.push` chained together. You can add as many more as you deem necessary.

## Custom JS Commands

Our LiveView seems to be getting full of duplicated code now with these JS.push everywhere. Imagine if one day we were to refactor the shipping format? We would have to manually modify multiple places. Fortunately a LiveView module can use module functions in your HEEx. Create and run `multiple_pushes_refactor.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={add_points(:red, 3)}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={add_points(:blue, 3)}
    />
    <input
      type="button"
      value="Draw"
      phx-click={add_points(:red, 1) |> add_points(:blue, 1)}
    />
    """
  end

  defp add_points(js \\ %JS{}, team, amount) do
    JS.push(js, "add_points", value: %{team: team, amount: amount})
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

We created a private function called `add_points/3` that takes 3 arguments. At this point you may be wondering what this initial argument called `js` is. To answer this, let's talk about how JS Commands work internally.

Every time you use `JS.push` or any other JS Commands function what you are actually creating is a data structure called `%JS{}`. When empty it looks like this: `%Phoenix.LiveView.JS{ops: []}`. It contains the list of operations that will be performed.

When you run `JS.push("event", value: %{})` you are internally using `JS.push(%JS{}, "event", value: %{})`, i.e. you have started the chain of operations now. In order for our custom JS Command function to be chainable we need to make the first argument optionally take a `js \\ %JS{}` argument.

It's okay if this part is a little bit confusing at the moment, we will revisit JS Commands in the future. For now, just remember that if you make a custom JS Commands function you must always start with `def your_function(js \\ %JS{}, ...rest)` and use the variable `js` in the first argument of `JS.push/3`.

## Recap!

- JS Commands can be chained.
- Using JS Commands you can cause more than one event to be triggered in the same `phx-click` binding.
- Creating custom JS Commands functions requires that we explicitly receive an optional argument `js \\ %JS{}` and that `js` is used.
