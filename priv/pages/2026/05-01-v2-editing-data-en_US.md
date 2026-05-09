%{
title: "Editing a ticket",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Editing existing data with LiveView forms",
previous_page_id: "v2-deleting-data",
next_page_id: "v2-form-component"
}

---

%{
title: "This lesson is a direct continuation of the previous lesson",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git --branch deleting-data- done`</code>.
"""
} %% .callout

To finalize the CRUD we will create a ticket edit form. Let's see how this can be extremely similar to the ticket creation form.

## Back to Context

Let's go back to our `lib/lineup/queue.ex` and add a new function:

```elixir
defmodule Lineup.Queue do
  # ...
  
  @doc """
  Updates a ticket.

  ## Examples

      iex> update_ticket(ticket, %{field: new_value})
      {:ok, %Ticket{}}

      iex> update_ticket(ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end
end
```

Unlike `create_ticket/1` which only receives the attributes, to update a ticket we need the original data to be able to apply the changes. Our function `Queue.update_ticket/2` receives the original struct and the modifications, applies the changeset, and using the function [`Repo.update/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:update/2) returns `{:ok, %Ticket{}}` or `{: error, %Ecto.Changeset{}}`.

### Testing on `iex`

Using Interactive Elixir we can get the last ticket with `ticket = Lineup.Queue.list_tickets() |> List.last` and update it using `Lineup.Queue.update_ticket(ticket, %{name: "Edited"}) `:

```elixir
$  iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Compiling 1 file (.ex)
Generated lineup app
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> ticket = Lineup.Queue.list_tickets() |> List.last
[debug] QUERY OK source="tickets" db=0.8ms decode=0.6ms idle=727.5ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
%Lineup.Queue.Ticket{
 __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
 id: 6,
 called_at: ~U[2026-04-22 13:15:00Z],
 inserted_at: ~U[2026-04-30 14:15:45Z],
 updated_at: ~U[2026-04-30 14:15:45Z]
}

iex(2)> NaiveDateTime.utc_now()
~N[2026-05-01 17:11:03.402100]

iex(3)> Lineup.Queue.update_ticket(ticket, %{called_at: DateTime.utc_now()})
[debug] QUERY OK source="tickets" db=0.1ms idle=936.7ms
UPDATE "tickets" SET "called_at" = ?, "updated_at" = ? WHERE "id" = ? [~U[2026-05-01 17:11:13Z], ~U[2026-05-01 17:11:13Z], 6]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
{:ok,
%Lineup.Queue.Ticket{
  __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
  id: 6,
  called_at: ~U[2026-05-01 17:11:13Z],
  inserted_at: ~U[2026-04-30 14:15:45Z],
  updated_at: ~U[2026-05-01 17:11:13Z]
}}
```

Note that in the second argument we only pass the `called_at` with `DateTime.utc_now()`. Ecto knows what changed and what stays the same when using changesets.

## Making our LiveView

Let's write the LiveView code step-by-step so that we can see the similarities with `TicketLive.Create`. In the folder `lib/lineup_web/live/ticket_live/` create a file `edit.ex`.

### Starting

```elixir
defmodule LineupWeb.TicketLive.Edit do
  use LineupWeb, :live_view
  alias Lineup.Queue
  alias Lineup.Queue.Ticket
end
```

The first step is to create the module and `use LineupWeb, :live_view`. We then add two useful aliases for what comes next.

### The `mount/3`

```elixir
@impl true
def mount(%{"id" => id}, _session, socket) do
  ticket = Queue.get_ticket!(id)
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  {:ok,
   socket
   |> assign(:page_title, "Edit Ticket")
   |> assign(:ticket, ticket)
   |> assign(:form, form)}
end
```

In our `mount/3` function we receive the `id` of the ticket as a parameter. Soon we will define this on the router as `live "/tickets/:id/edit", TicketLive.Edit, :edit` so we can guarantee that there will be this `id`.

The next step is to use `ticket = Queue.get_ticket!(id)` to retrieve the ticket by `id`. It is worth remembering that if there is no ticket with this `id` a 404 error will be automatically generated as we saw in a previous lesson.

We define our `form` as a changeset that receives the original ticket. In the creation form we used `Ticket.changeset(%Ticket{})`, that is, the empty ticket because at that moment there was no ticket. As we are working with editing, all our changesets will receive the ticket being edited.

Also note that in assign we pass `ticket`. We will use this assignment not only in our HEEx but also in other events.

### The validate event

```elixir
@impl true
def handle_event("validate", %{"ticket" => ticket_params}, socket) do
  changeset = Queue.change_ticket(socket.assigns.ticket, ticket_params)
  {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
end
```

You're not seeing things, this is an exact copy of the `validate` event from our `TicketLive.New` view.

### The save event

```elixir
def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, ticket_params)
end

defp save_ticket(socket, ticket_params) do
  case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
    {:ok, ticket} ->
      {:noreply,
       socket
       |> put_flash(:info, "Ticket updated successfully")
       |> push_navigate(to: ~p"/tickets/#{ticket}")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

Once again our event is a copy of the create ticket event with some minor changes only in the successful update case!

### The `render/1`

```elixir
@impl true
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash}>
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage ticket records in your database.</:subtitle>
    </.header>

    <.form for={@form} id="ticket-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:called_at]} type="datetime-local" label="Called at" />
      <footer>
        <.button phx-disable-with="Saving..." variant="primary">Save Ticket</.button>
        <.button navigate={~p"/tickets/#{@ticket}"}>Cancel</.button>
      </footer>
    </.form>
  </Layouts.app>
  """
end
```

The sole difference from our `TicketLive.New` is that this "Cancel" button redirects to `TicketLive.Show` instead of `TicketLive.Index`.

### Updating our router

Open your router file and add the route `live "/tickets/:id/edit", TicketLive.Edit, :edit`. Your router should currently look like this:

```elixir
# ...
scope "/", LineupWeb do
  pipe_through :browser

  live "/", TicketLive.Index, :index
  live "/tickets/new", TicketLive.New, :new
  live "/tickets/:id", TicketLive.Show, :show
  live "/tickets/:id/edit", TicketLive.Edit, :edit
end
# ...
```

## Adding a link to the form

We have a page, but our users don't know about it. Open your `TicketLive.Show` and update just the `<.header>` component to add one more button under `<:actions>`:

```elixir
<.header>
  Ticket {@ticket.id}
  <:subtitle>This is a ticket record from your database.</:subtitle>
  <:actions>
    <.button navigate={~p"/"}>
      <.icon name="hero-arrow-left" />
    </.button>
    <.button variant="primary" navigate={~p"/tickets/#{@ticket}/edit"}>
      <.icon name="hero-pencil-square" /> Edit ticket
    </.button>
  </:actions>
</.header>
```

Also, let's update `TicketLive.Index` to show a quick link to edit tickets:

```elixir
<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="Called at">{ticket.called_at}</:col>
  <:action :let={{_id, ticket}}>
    <div class="sr-only">
      <.link navigate={~p"/tickets/#{ticket}"}>Show</.link>
    </div>
    <.link navigate={~p"/tickets/#{ticket}/edit"}>Edit</.link>
  </:action>
  <:action :let={{id, ticket}}>
    <.link
      phx-click={JS.push("delete", value: %{id: ticket.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>
```

%{
title: ~H"What was that 'sr-only' thing?",
description: ~H"""
This CSS class is often used to hide elements in a way that it's still understood by Screen Readers (SR) so folks can understand there's an actionable item in there unlike just making the Table Row (tr) element clickable as, semantically speaking, `tr` is not meant to be something you'd click in. 
"""
} %% .callout

## Adding our final tests

As you might have thought, since our edit view is so similar to our new ticket form, indeed these tests will look alike. Starting with `Lineup.QueueTest`:

```elixir
test "update_ticket/2 with valid data updates the ticket" do
  ticket = ticket_fixture()
  update_attrs = %{called_at: ~U[2026-04-28 16:00:00Z]}

  assert {:ok, %Ticket{} = ticket} = Queue.update_ticket(ticket, update_attrs)
  assert ticket.called_at == ~U[2026-04-28 16:00:00Z]
end
```

This test case is nothing but obvious at this point in our lessons. As for `LineupWeb.TicketLiveTest` first add this under the top of the file alongside the existing `@create_attrs`:

```elixir
@create_attrs %{called_at: "2026-04-27T16:00:00Z"}
@update_attrs %{called_at: "2026-05-01T16:00:00Z"}
```

Then, let's add to `describe "Index" do`:

```elixir
test "updates ticket in listing", %{conn: conn, ticket: ticket} do
  {:ok, index_live, _html} = live(conn, ~p"/")

  assert {:ok, edit_form_live, _html} =
           index_live
           |> element("#tickets-#{ticket.id} a", "Edit")
           |> render_click()
           |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")

  assert render(edit_form_live) =~ "Edit Ticket"

  assert {:ok, index_live, _html} =
           edit_form_live
           |> form("#ticket-form", ticket: @update_attrs)
           |> render_submit()
           |> follow_redirect(conn, ~p"/tickets/#{ticket}")

  html = render(index_live)
  assert html =~ "Ticket updated successfully"
end
```

And, finally, inside `describe "Show" do` add:

```elixir
test "updates ticket and returns to show", %{conn: conn, ticket: ticket} do
  {:ok, show_live, _html} = live(conn, ~p"/tickets/#{ticket}")

  assert {:ok, edit_form_live, _} =
            show_live
            |> element("a", "Edit")
            |> render_click()
            |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")

  assert render(edit_form_live) =~ "Edit Ticket"

  assert {:ok, show_live, _html} =
            edit_form_live
            |> form("#ticket-form", ticket: @update_attrs)
            |> render_submit()
            |> follow_redirect(conn, ~p"/tickets/#{ticket}")

  html = render(show_live)
  assert html =~ "Ticket updated successfully"
end
```

At this point, anything that was used here was already explained in previous lessons!

## Final code

Done! Our application has a complete CRUD. There are still some things that can be improved and we will look at this in another section of this course but if you have followed the course so far you already have enough knowledge to get by creating your next CRUD!

If you had any issues you can see the final code for this lesson using `git checkout editing-data-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/lineup.git --branch editing-data-done`.

## Recap!

- Using `Repo.update/2` we can update a ticket by passing a changeset.
- An edit form LiveView can be extremely similar to one for creating data.
- You already know how to do a complete CRUD in LiveView 😉.
- I wonder what we can do about having two LiveViews that have a lot of duplicate code?
