%{
title: "Deleting a ticket",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Creating a UX to delete a ticket using LiveView",
previous_page_id: "v2-show-data",
next_page_id: "v2-editing-data"
}

---

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git --branch show-data-done`</code>.
"""
} %% .callout

Let's skip to the last letter of CRUD: Delete. In this lesson, we'll see how simple it is to create a UX to delete an item using resources from our project.

## You probably guessed that we'd start with the Context.

The first step is to go back to our `lib/lineup/queue.ex` file and add a new function:

```elixir
defmodule Lineup.Queue do
  # ...

  @doc """
  Deletes a ticket.

  ## Examples

      iex> delete_ticket(ticket)
      {:ok, %Ticket{}}

      iex> delete_ticket(ticket)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end
end
```

The `delete_ticket/1` function takes a struct of type `%Ticket{}` and simply applies the [`Repo.delete/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:delete/2) method to it. The result will be `{:ok, %Ticket{}}` which is useful if it is necessary know about the deleted ticket.

### Testing on `iex`

Using the reliable Elixir Interactive mode we can fetch the last ticket with `ticket = Lineup.Queue.list_tickets() |> List.last` and delete it using `Lineup.Queue.delete_ticket(ticket)`:

```elixir
$ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> ticket = Lineup.Queue.list_tickets() |> List.last

[debug] QUERY OK source="tickets" db=0.2ms queue=0.1ms idle=1192.5ms
SELECT p0."id", p0."name", p0."description" FROM "tickets" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%Lineup.Queue.Ticket{
  __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
  id: 10,
  name: "asda",
  description: "ad"
}

iex(2)> Lineup.Queue.delete_ticket(ticket)
[debug] QUERY OK source="tickets" db=1.7ms idle=1366.3ms
DELETE FROM "tickets" WHERE "id" = ? [10]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405
{:ok,
 %Lineup.Queue.Ticket{
   __meta__: #Ecto.Schema.Metadata<:deleted, "tickets">,
   id: 10,
   name: "asda",
   description: "ad"
 }}
```

## Deleting tickets in the list LiveView

Instead of creating a new LiveView called `TicketLive.Delete`, we can reuse the ticket list for this purpose. Open your `TicketLive.Index` located in `lib/lineup_web/live/ticket_live/index.ex`.

### The `<:action>` slot of the `<.table>` component

Within your `render/1`, update your `<.table>` to the following code:

```elixir
<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="ID">{ticket.id}</:col>
  <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
  <:action :let={{id, ticket}}>
    <.link
      phx-click={JS.push("delete", value: %{id: ticket.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>
</.table>
```

We added a slot called `<:action>` where we receive both the `id` and the `ticket` using the special attribute `:let`. This slot is placed as the last column to add action buttons to our row.

### The ID from the `:let`

This specific `id` is known as the "DOM ID" or "HTML ID" and, in this case, it should be something like "tickets-123" because our table has the ID "tickets" and assuming the ID in the database of the item is 123. It's useful for applying JS commands.

### Confirming actions with `data-confirm`

The next focus point is `data-confirm`. We don't want the item to be deleted immediately without any kind of confirmation, right? Phoenix checks that if you click on an element with `data-confirm` it triggers a `confirm` dialog in your browser and only applies the `phx-click` if the user confirms.

### The `hide/2` command

Within our `phx-click` binding, two things occur:

1. We send an event to our LiveView called "delete" (we still need to define it).
2. We hide the element of the current row using the HTML ID.

As you can see, we're not directly using `JS.hide/2` but rather just the `hide/1` function. This is because Phoenix already provides this simplified function within `CoreComponents`, which applies transitions using CSS classes! Look at your `CoreComponents`:

```elixir
def hide(js \\ %JS{}, selector) do
  JS.hide(js,
    to: selector,
    time: 200,
    transition:
      {"transition-all transform ease-in duration-200",
       "opacity-100 translate-y-0 sm:scale-100",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
  )
end
```

Whenever possible, prefer to use `hide/1` from `CoreComponents`. However, if you need to customize the transition, opt for `JS.hide/2`.

### Creating the delete event

To be able to test this code we need to create our `handle_event/3`. In your LiveView. Below the `mount/3` function add this callback:

```elixir
@impl true
def handle_event("delete", %{"id" => id}, socket) do
  ticket = Queue.get_ticket!(id)
  {:ok, _} = Queue.delete_ticket(ticket)

  {:noreply, stream_delete(socket, :tickets, ticket)}
end
```

In this event we only receive the ID, we immediately check in the database if the ticket exists using the `Queue.get_ticket/1` function that we built in the previous lesson. We then delete the ticket. As we already have the `ticket` variable we ignore the second result of the delete function.

### The `stream_delete/3` function

In previous lessons we had already seen how to create streams using `stream/4` to render lists in an efficient way. Now we can see the [`stream_delete/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream_delete/3) function to delete an item from the stream.

Remembering that streams do not store any data in memory about its items the `stream_delete/3` function receives the name of the stream which is `:tickets` as we defined in our `mount/3` and the `ticket`. Using these two variables, it infers that the HTML ID of the element will be `#tickets-123` and sends a simple payload to the client indicating that LiveView should delete this element from the HTML.

### LiveView Code

With all the pieces together your `TicketLive.Index` should be close to this code:

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
  def handle_event("delete", %{"id" => id}, socket) do
    ticket = Queue.get_ticket!(id)
    {:ok, _} = Queue.delete_ticket(ticket)

    {:noreply, stream_delete(socket, :tickets, ticket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tickets
        <:actions>
          <.button variant="primary" navigate={~p"/tickets/new"}>
            <.icon name="hero-plus" /> New Ticket
          </.button>
        </:actions>
      </.header>

      <.table
        id="tickets"
        rows={@streams.tickets}
        row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
      >
        <:col :let={{_id, ticket}} label="ID">{ticket.id}</:col>
        <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
        <:action :let={{id, ticket}}>
          <.link
            phx-click={JS.push("delete", value: %{id: ticket.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  defp list_tickets() do
    Queue.list_tickets()
  end
end
```

## Adding more tests!

It should be no mystery to you how to add context tests under `QueueTest`. Head out to that test file and add:

```elixir
test "delete_ticket/1 deletes the ticket" do
  ticket = ticket_fixture()
  assert {:ok, %Ticket{}} = Queue.delete_ticket(ticket)
  assert_raise Ecto.NoResultsError, fn -> Queue.get_ticket!(ticket.id) end
end
```

In this test case we are now using [`assert_raise/2`](https://hexdocs.pm/ex_unit/1.19.3/ExUnit.Assertions.html#assert_raise/2) to verify that calling `Queue.get_ticket/1` again will properly return `Ecto.NoResultsError` as we expect. As for our `TicketLiveTest` our test is as simple as triggering the button click event. Add this to your `describe "Index" do` section:

```elixir
test "deletes ticket in listing", %{conn: conn, ticket: ticket} do
  {:ok, index_live, _html} = live(conn, ~p"/tickets")

  assert index_live |> element("#tickets-#{ticket.id} a", "Delete") |> render_click()
  refute has_element?(index_live, "#tickets-#{ticket.id}")
end
```

## Final code

Ready! Now you just need to test your LiveView and verify that the current flow is working.

If you had any issues you can see the final code for this lesson using `git checkout deleting-data-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/lineup.git --branch deleting-data-done`.

## Recap!

- The function `Repo.delete/2` receives a struct from an Ecto schema and deletes it from the database.
- The `<:action>` slot is useful for adding action buttons to your tables.
- The IDs that come from the special attribute `:let` in component slots `<.table>` are called DOM ID or HTML ID and follow the format `name-of-your-stream-ID` (where ID is the ID in the database element data).
- The DOM ID is useful for applying JS commands.
- The `CoreComponents` of Phoenix projects comes with a `hide/1` function that is just `JS.hide/2` but with a beautiful transition.
- We can use `data-confirm` to confirm with the user before triggering an action like a `phx-click`.
- The `stream_delete/3` function is a way to delete elements from a stream. This function optimizes sending the minimum amount of data to LiveView so it follows the idea that streams are an efficient way to manage lists in LiveView.
- `assert_raise/2` can be used to to test that exceptions will be raised by some code.
