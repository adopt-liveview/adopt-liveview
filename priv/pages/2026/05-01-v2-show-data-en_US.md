%{
title: "Showing a ticket",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Showing a specific ticket on your LiveView project",
previous_page_id: "v2-listing-data",
next_page_id: "v2-deleting-data"
}

---

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you jumped straight into this lesson, it might be confusing as it's a direct continuation of the code from the previous one. If you want to skip the previous lesson and start directly from this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git --branch listing-data-done`</code>.
"""
} %% .callout

In our previous lesson we created the list of tickets for our application. In this lesson we'll finish the Read part of our CRUD: we'll create the page that displays a specific ticket.

## Once more, Context

By this point you've probably guessed that we're going to start by editing the Context Module in `lib/lineup/queue.ex`. Open this file and add the following line at the end:

```elixir
defmodule Lineup.Queue do
  # ...
  
  @doc """
  Gets a single ticket.

  Raises `Ecto.NoResultsError` if the Ticket does not exist.

  ## Examples

      iex> get_ticket!(123)
      %Ticket{}

      iex> get_ticket!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ticket!(id), do: Repo.get!(Ticket, id)
end

```

This time you can see that the function name is slightly different: it has an exclamation mark at the end. Not only the function we're creating but also the function [`Repo.get/3`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:get!/3) have an exclamation mark. In Elixir, we call these "bang functions".

### Understanding bang functions

While you may have noticed that some Elixir functions prefer to return `{:ok, data}` or `{:error, data}`, bang functions prefer to return the data or raise an exception. Let's see this for real. Enter Interactive Elixir using `iex -S mix`. Let's assume your system has a ticket with ID 1.

```elixir
[I] ➜ iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Generated lineup app
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> Lineup.Queue.get_ticket!(1)
[debug] QUERY OK source="tickets" db=0.7ms decode=0.5ms idle=705.3ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 WHERE (t0."id" = ?) [1]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
%Lineup.Queue.Ticket{
  __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
  id: 1,
  called_at: ~U[2026-04-21 13:07:00Z],
  inserted_at: ~U[2026-04-28 16:03:37Z],
  updated_at: ~U[2026-04-28 16:03:37Z]
}

iex(2)> Lineup.Queue.get_ticket!(100000000)
[debug] QUERY OK source="tickets" db=0.0ms idle=1359.2ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 WHERE (t0."id" = ?) [100000000]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
** (Ecto.NoResultsError) expected at least one result but got none in query:

from t0 in Lineup.Queue.Ticket,
  where: t0.id == ^100_000_000

    (ecto 3.13.5) lib/ecto/repo/queryable.ex:173: Ecto.Repo.Queryable.one!/3
    iex
```

When we use the function `Lineup.Queue.get_ticket!/1` with the existing ID 1, the result is the ticket itself, without the format `{:ok, ticket}`. When we use it with a non-existent ID, the result is an exception `Ecto.NoResultsError`. What advantage is there in using this format instead of simply handling the error ourselves?

### Automatic exception handling

Internally, the Phoenix framework can understand that `Ecto.NoResultsError` is an exception that means that the expected data does not exist, so this page is a 404 error. This handling comes from the `phoenix_ecto` library, which was already installed in your project and which we also installed in previous lessons. Check directly from the [source code](https://github.com/phoenixframework/phoenix_ecto/blob/3bdb207e31a242d3286faf117c95a3c40a048dc5/lib/phoenix_ecto/plug.ex#L1-L6) which exceptions are automatically handled:

```elixir
errors = [
  {Ecto.CastError, 400},
  {Ecto.Query.CastError, 400},
  {Ecto.NoResultsError, 404},
  {Ecto.StaleEntryError, 409}
]
```

If you want to automatically handle different exceptions just take a look at the [Custom Exceptions](https://hexdocs.pm/phoenix/custom_error_pages.html#custom-exceptions) documentation in Phoenix. The main advantage here is: if Phoenix handles the error, our LiveView can focus only on the success flow.

## Creating our `TicketLive.Show`

Inside the folder `lib/lineup_web/live/ticket_live`, create a file called `show.ex` with the following content:

```elixir
defmodule LineupWeb.TicketLive.Show do
  use LineupWeb, :live_view

  alias Lineup.Queue

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Ticket {@ticket.id}
        <:subtitle>This is a ticket record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Called at">{@ticket.called_at}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Ticket")
     |> assign(:ticket, Queue.get_ticket!(id))}
  end
end
```

### The `<.list>` component

Within our `render/1`, the only new component is the `<.list>`, which also comes from the `CoreComponents`. For each `<:item>` slot, it receives a `title` and renders the inner block. This component is useful for displaying things in a `key-value` format.

### Updating our router

Open your `router.ex` and add the new route below the others:

```elixir
live "/tickets/:id", TicketLive.Show, :show
```

Once again, we're following not only the naming convention for the LiveView but also for the live action `:show`.

Open a tab [http://localhost:4000/tickets/1](http://localhost:4000/tickets/1) and see your ticket being displayed. Similarly, switch to a non-existent ID like [http://localhost:4000/tickets/1123](http://localhost:4000/tickets/1123) and see the error message.

### Nice error messages in the development environment

It's worth mentioning that on the page with the non-existent ID you should have seen a well-formatted error message with code being displayed and much more information. Phoenix brings this error screen only in the development environment. In production, you'll see only a generic "Not found" message because we don't want to leak any information about our code to users.

If you want to see how the generic message looks without having to deploy, you can open `config/dev.exs`, change `debug_errors: true` to `false`, and restart the server.

## Creating a link from the list to the ticket

Once again, we shouldn't make our users figure out where things are. Open your `TicketLive.Index` and edit only the table inside the `render/1` to:

```elixir
<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="ID">{ticket.id}</:col>
  <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
</.table>
```

Now, when you click on a row in the table, your user will go to `TicketLive.Show`. The `<.table>` component accepts an assign called `row_click`, which takes an anonymous function and passes `{id, ticket}` to it. We can ignore the `id` and use the `ticket` directly.

### `JS.navigate/2`

Here we introduce a new JS Command: [`JS.navigate/1`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#navigate/1). It takes a URL and simply navigates the user to it.

### `Phoenix.Param`

You might be surprised that the URL is `~p"/tickets/#{ticket}"` instead of `~p"/tickets/#{ticket.id}"` (do note the `.id`). This is because Phoenix knows how to convert an Ecto schema like `%Ticket{}` to a URL by reading its ID. Just an [internal framework trivia](https://hexdocs.pm/phoenix/Phoenix.Param.html) for you to know.

## Adding more tests!

We couldn't wrap up this lesson without adding a couple of tests. Add to `Lineup.QueueTest` the following case:

```elixir
test "get_ticket!/1 returns the ticket with given id" do
  ticket = ticket_fixture()
  assert Queue.get_ticket!(ticket.id) == ticket
end
```

There's nothing new about the above, just a simple test. As for `LineupWeb.TicketLiveTest` add a new describe block like this:

```elixir
describe "Show" do
  setup [:create_ticket]

  test "displays ticket", %{conn: conn, ticket: ticket} do
    {:ok, _show_live, html} = live(conn, ~p"/tickets/#{ticket}")

    assert html =~ "Show Ticket"
  end
end
```

For now, we will only be checking that this page renders correctly and displays its title. Wait a minute, there's something different about this test! Up until now we have been getting from test cases `%{conn: conn}` but this time there's also a `ticket` variable in there? The explanation is quite simple. In our `setup` pipeline we have `:create_ticket` which is defined as:

```elixir
defp create_ticket(_) do
  ticket = ticket_fixture()

  %{ticket: ticket}
end
```

In any setup function you write, if you return a map it will automatically be merged with your test context. So if you had written `%{ticket: ticket, user_id: 1}` then later in your test cases you'd be able to match `%{conn: conn, ticket: ticket, user_id: user_id}`. In case you are wondering, `conn` comes from a `setup/1` function in `LineupWeb.ConnCase`!

## Final code

Using the route to show a ticket, we were able to learn many things related to the Phoenix framework and the Elixir programming language.

If you had any issues you can see the final code for this lesson using `git checkout show-data-done` or by cloning to another folder using `git clone https://github.com/adopt-liveview/first-crud.git --branch show-data-done`.

## Recap!

- We can use `Repo.get!/3` to fetch data from the database using an ID.
- Functions in Elixir with names ending in an exclamation mark are called bang functions.
- Bang functions do not use the convenient format of `{:ok, data}` and `{:error, error}`; they simply return the data or raise an exception.
- Phoenix can automatically handle some Ecto exceptions and convert them into HTTP errors, making our code simpler because we can focus only on the success case.
- The `<.list>` component is useful for rendering simple key-value structures.
- In development mode, Phoenix displays beautiful error messages in the browser for exceptions to assist the developer, but in production, the messages are generic (though customizable).
- The `<.table>` component accepts a `row_click` assign with a function that is executed when a row in the table is clicked.
- The JS Command `JS.navigate/1` works exactly like the `<.link navigate={...}>` component, except in a programmatic way.
- Phoenix can automatically convert Ecto schemas into URL parameters by looking at their ID.
- Test setup functions can return maps with data that will be accessible on test cases.
