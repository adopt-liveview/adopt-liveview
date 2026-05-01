%{
title: "Listing tickets",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Organizing our project and listing our tickets",
previous_page_id: "v2-saving-data",
next_page_id: "v2-show-data"
}

---

In the previous lesson we created some tickets! Let's create a simple page to list saved tickets.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you jumped straight into this lesson, it might be confusing as it's a direct continuation of the code from the previous one. If you want to skip the previous lesson and start directly from this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git --branch first-context-test-done`</code>.
"""
} %% .callout

## Back to our Context

Remember that all operations related to modifying our ticket domain will be concentrated in the `Queue` context. At this moment we need a function to list all tickets. Open `lib/lineup/queue.ex` and add the `list_tickets/0` method:

```elixir
defmodule Lineup.Queue do
  @moduledoc """
  The Queue context.
  """

  import Ecto.Query, warn: false
  alias Lineup.Repo

  alias Lineup.Queue.Ticket

  @doc """
  Returns the list of tickets.

  ## Examples

      iex> list_tickets()
      [%Ticket{}, ...]

  """
  def list_tickets do
    Repo.all(Ticket)
  end

  # Other methods...
end
```

To list rows from our database, we use the function [`Repo.all/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:all/2) which takes an Ecto query and returns all rows. Our `Ticket` module itself is considered a query and, in this case, represents `select * from tickets`.

### Testing in `iex`.

Open your `iex -s mix` and execute `Lineup.Queue.list_tickets()`:

```elixir
$ iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Compiling 2 files (.ex)
Generated lineup app
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Lineup.Queue.list_tickets()
[debug] QUERY OK source="tickets" db=0.7ms decode=0.8ms idle=1809.8ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
[
  %Lineup.Queue.Ticket{
    __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
    id: 1,
    called_at: ~U[2026-04-21 13:07:00Z],
    inserted_at: ~U[2026-04-28 16:03:37Z],
    updated_at: ~U[2026-04-28 16:03:37Z]
  }
]
```

As you can see, our function works. We can proceed to apply it in a new LiveView.

## Back to our `TicketLive.Index`

To list our tickets, we will use `LineupWeb.TicketLive.Index`. Phoenix projects like to follow this pattern: `YourAppWeb.NameOfSomethingLive.{Index, Show, New, Edit}` (or is it? We will discuss this later). Lets change our `Index` LiveView:

```elixir
defmodule LineupWeb.TicketLive.Index do
  use LineupWeb, :live_view

  alias Lineup.Queue

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Tickets")
     |> stream(:tickets, list_tickets())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tickets
      </.header>

      <.table
        id="tickets"
        rows={@streams.tickets}
      >
        <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
      </.table>
    </Layouts.app>
    """
  end

  defp list_tickets() do
    Queue.list_tickets()
  end
end
```

### Remember streams?

In the lesson on rendering lists we discussed streams as an optimized way to render items in HEEx. In that lesson there was a bit more complexity in the code because we needed to add an `id` to each element. But in this case, since we're working with a database, all elements have an `id`, so we can define a stream of tickets without any hassle.

### Using the `<.table>` component

Phoenix projects contain a very powerful component called `<.table>` in their `CoreComponents`. Throughout the CRUD lessons we'll learn more about it.

```elixir
<.table id="tickets" rows={@streams.tickets}> ... </.table>
```

At the moment all you need to understand is that this component works very well with streams. We pass two assigns to the component: an unique `id` and `rows` receives the stream of `tickets`.

```elixir
<:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
```

Inside the component, you can see that we use the `<:col>` slot twice. Each of these slots requires a `label` attribute to define the column name in the table and receives the special attribute `:let` for you to access `{id, element}`. At the moment, we can ignore the `id` and receive the `ticket` to render the content of that column for each ticket. If all of this seems very weird to you, you can take a look at our lesson on rendering lists with slots in the component section. Also its worth mentioning that in the "Called at" `<:col>` we used short circuit on `ticket.called_at || "n/a"` to either render the date or to show "n/a" because if `called_at` is `nil` nothing will be rendered as thats how HEEx interprets the `nil` atom.

Success! Open your browser and you'll see that at the homepage all your tickets are listed. But wait, how do we go to the new ticket page? Your user won't guess the route!

### Connecting the pages using links

Go to your `TicketLive.Index` and modify just the `<.header>` section a bit:

```elixir
<.header>
  Listing Tickets
  <:actions>
    <.button variant="primary" navigate={~p"/tickets/new"}>
      <.icon name="hero-plus" /> New Ticket
    </.button>
  </:actions>
</.header>
```

We used the `<.header>` component, which also comes from the `CoreComponents`, not only to give a title to our ticket list page but also to use its `<:action>` slot to add a link to our new ticket page.

## Updating our context test

Now that our context module has a new function we might as well test it too. Head out to `test/lineup/queue_test.exs` and add a new test case inside your describe block:

```elixir
defmodule Lineup.QueueTest do
  use Lineup.DataCase

  alias Lineup.Queue

  describe "tickets" do
    alias Lineup.Queue.Ticket

    import Lineup.QueueFixtures

    test "list_tickets/0 returns all tickets" do
      ticket = ticket_fixture()
      assert Queue.list_tickets() == [ticket]
    end

    # other tests...
  end
end
```

Then check it out with `mix test`:

```sh
$ mix test test/lineup/queue_test.exs
Compiling 3 files (.ex)
Generated lineup app
Running ExUnit with seed: 684602, max_cases: 28

...
Finished in 0.02 seconds (0.00s async, 0.02s sync)
3 tests, 0 failures
```

Great, all tests are passing!

## Our first LiveView test!

Similarly to how we created a test for our context module we will need to create a test module with a similar name. Since our CRUD LiveViews are very simple and related to each other we will create a single module instead of one per LiveView. 

Create `test/lineup_web/live/ticket_live_test.exs` with the following code:

```elixir
defmodule LineupWeb.TicketLiveTest do
  use LineupWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lineup.QueueFixtures

  @create_attrs %{called_at: "2026-04-27T16:00:00Z"}

  defp create_ticket(_) do
    ticket = ticket_fixture()

    %{ticket: ticket}
  end

  describe "Index" do
    setup [:create_ticket]

    test "lists all tickets", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Listing Tickets"
    end

    test "saves new ticket", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      assert {:ok, new_ticket_live, _} =
               index_live
               |> element("a", "New Ticket")
               |> render_click()
               |> follow_redirect(conn, ~p"/tickets/new")

      assert render(new_ticket_live) =~ "New Ticket"

      assert {:ok, index_live, _html} =
                new_ticket_live
               |> form("#ticket-form", ticket: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/")

      html = render(index_live)
      assert html =~ "Ticket created successfully"
    end
  end
end
```

### `ConnCase`

The first thing in our module is us using a helper called `LineupWeb.ConnCase` which, just like `LineupWeb.DataCase`, lives inside your repository. The main difference is that `ConnCase` will bring useful functions to handle testing how Phoenix HTTP requests work without actually running the server. Just below that we also `import Phoenix.LiveViewTest` which brings even more test helpers that are specific to LiveViews.

At the very top we created a function called `create_ticket/1` which plainly ignores the first argument. For now you dont need to know much about it but we will talk about it in another lesson. What you need to understand about is that it will ensure that our database will always have at least a single `%Ticket{}` stored. That function is implicitely being used inside our `describe` block by `setup [:create_ticket]` which tells ExUnit to always call it before running each test.

Our first test case receives as an argument a map that includes `conn` which is how we will be simulating a request to our Phoenix server. If you don't know about Plug's `conn` its fine, just think of it as a simulated connection.

Our LiveView tests will often use a helper called [`live/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live/4). This helper converts a `conn` (which is a simulated plain HTTP request) into a simulated LiveView connection. Its return is a 3-tuple with `:ok`, the simulated LiveView and the HTML rendered at the start. Its worth mentioning that since LiveViews are reactive, we can always get the HTML back by using `render(live)` (assuming we called our LiveView as `live` variable).

In our `"list all tickets"` test we just check that the header text appears. We will improve on that later. As for our `"saves new ticket"` test we nmot only start by rendering `index_live`, we simulate a click on the "New ticket" link then follow the redirection to generate a **new** live called `new_ticket_live` but inside that we submit the form and follow the redirect back to `index_live` again with a flash message appearing with "Ticket created successfully". 

Take your time to get familiar with those functions but don't worry, you can always look for other examples in your codebase or the internet when you find yourself lost on what can you do to test LiveViews. Tip: save this documentation link to have all `LiveViewTest` functions whenever you need to look for something: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html

## Final code

Now your application is not only more organized in terms of folders but the user will also have a good first navigation experience.

If you found it challenging to follow the code in this lesson, you can see the completed code using `git checkout listing-data-done` or by cloning it into another folder using `git clone https://github.com/adopt-liveview/lineup.git --branch listing-data-done`.

## Recap!

- Using `Repo.all/2` we can list the result of an Ecto query.
- The `Ticket` module can be considered an Ecto query in the format `select * from tickets`.
- Phoenix projects like to follow this pattern: `YourAppWeb.NameOfSomethingLive.{Index, Show, New, or Edit}`.
- To keep your LiveView folders more organized in your project, we use the format `lib/your_app_web/live/your_model/{index.ex, new.ex, edit.ex, show.ex}`, as we'll see in future lessons.
- When using databases it's very easy to use streams in LiveView because the elements already come with an `id`.
- The `<.table>` component is very powerful in simplifying tables with items, as we'll see in the future.
- In your `router.ex`, prefer Live Actions between `:new`, `:index`, `:edit`, and `:show`, as we'll see in the next lessons.
- The `<.header>` component is very useful for titling your pages and can also contain an `<:actions>` slot to simplify adding action buttons, as we used to add the create ticket button.
- In LiveViews test we both `use MyappWeb.ConnCase` and `import Phoenix.LiveViewTest`.
- `ConnCase` is where helpers to simulate HTTP requests to Phoenix are imported.
- `Phoenix.LiveViewTest` is where helpers to test LiveViews exist.
- You can simulate LiveView interactions with `live/3` to enter a view, `element/3` to find some HTML, `render_click/1` to trigger a link/button and `follow_redirect/3` to create test scenarios for your users workflows.
