%{
title: "Modal Form",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "How to reuse forms in a modal",
previous_page_id: "v2-live-component",
next_page_id: "my-first-test",
}

---

Now that our form is in a Live Component, we can reuse it much more easily. In this lesson, we will learn how to use the `<.modal>` component to create a quick edit form for tickets on the home page.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/refactoring-crud.git --branch live-component-done`</code>.
"""
} %% .callout

## Using `TicketLive.Index` for editing?

In previous lessons, we saw how it's possible to use the same LiveView for more than one action. Let's make our `TicketLive.Index` capable of both listing and editing a ticket! In your router file, add the second clause of your index route:

```elixir
live "/", TicketLive.Index, :index
live "/:id/edit", TicketLive.Index, :edit # Add this line
```

Now our `TicketLive.Index` route has two possible values for `@live_action`: `:index` or `:edit`.

### Adding a link for quick editing

Open the `index.ex` file and edit the table that lists tickets as follows:

```elixir
~H"""
...

<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="Name"><%= ticket.name %></:col>
  <:col :let={{_id, ticket}} label="Description"><%= ticket.description %></:col>
  <:action :let={{_id, ticket}}>
    <.link patch={~p"/#{ticket}/edit"}>Quick Edit</.link>
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

...
"""
```

We added a new `<:action>` slot with just a link to the new editing route. Note that we used `<.link patch={}>` because we are in the same LiveView! Another point to remember about `patch` is that it calls `handle_params/3`. Let's create this callback for our LiveView:

```elixir
def handle_params(params, _uri, socket) do
  case socket.assigns.live_action do
    :edit ->
      %{"id" => id} = params
      ticket = Queue.get_ticket!(id)
      {:noreply, assign(socket, ticket: ticket)}

    :index ->
      {:noreply, assign(socket, ticket: nil)}
  end
end
```

Much like we did in the previous lesson, we simply check the value of `socket.assigns.live_action` to determine what to do. In the case of editing, we need to know about the ticket to be edited, so we receive the ticket's `id` from the `params` (which comes from the URL) and assign its value. In the case of the `:index` action, we can simply assign `ticket` as `nil`.

If you also remember from the previous lesson, we can simplify this `case` by creating a new function!

```elixir
def handle_params(params, _uri, socket) do
  {:noreply, apply_action(socket, socket.assigns.live_action, params)}
end

defp apply_action(socket, :edit, %{"id" => id}) do
  ticket = Queue.get_ticket!(id)
  assign(socket, ticket: ticket)
end

defp apply_action(socket, :index, _params) do
  assign(socket, ticket: nil)
end
```

Now our `handle_params/3` is much more readable, and this convention of creating a private function `apply_action/3` is very common in Phoenix projects.

### Adding the modal

At the moment, clicking on Quick Edit correctly redirects you to the new route, but nothing new appears on your screen. Let's add the form Live Component. Alias `LineupWeb.TicketLive.FormComponent` and add the following code at the end of your `render/1`.

```elixir
defmodule LineupWeb.TicketLive.Index do
  # ...
  alias LineupWeb.TicketLive.FormComponent

  def render(assigns) do
    ~H"""
    # ...

    <.modal :if={@live_action == :edit} id="ticket-modal" show on_cancel={JS.patch(~p"/")}>
      <.live_component
        module={FormComponent}
        id="quick-edit-form"
        ticket={@ticket}
        action={@live_action}
      >
        <h1>Editing a ticket</h1>
      </.live_component>
    </.modal>
    """
  end
end
```

The magic happens in the special attribute `:if`. If `@live_action` is `:edit`, the modal appears. If the modal is closed, the `on_cancel` property defines that the user should be redirected to the home page.

### Redirection issues

At this point, your form works correctly. Use Quick Edit to edit any item. Oops? Did you get redirected to the ticket editing page?

This happens because in our `TicketLive.FormComponent`, we defined that after editing a ticket, we go directly to the editing page. To avoid this, we can introduce a new optional assign called `patch`.

Inside your `TicketLive.Index`, update the code of your modal to:

```elixir
~H"""
...

<.modal :if={@live_action == :edit} id="ticket-modal" show on_cancel={JS.patch(~p"/")}>
  <.live_component
    module={FormComponent}
    id="quick-edit-form"
    ticket={@ticket}
    action={@live_action}
    patch={~p"/"}
  >
    <h1>Editing a ticket</h1>
  </.live_component>
</.modal>
"""
```

In your `TicketLive.FormComponent` look for the `save_ticket` at the `:edit` case and change the code to:

```elixir
defp save_ticket(socket, :edit, ticket_params) do
  case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
    {:ok, ticket} ->
      socket =
        socket
        |> put_flash(:info, "Ticket updated successfully")

      socket =
        if patch = socket.assigns[:patch] do
          push_patch(socket, to: patch)
        else
          push_navigate(socket, to: ~p"/tickets/#{ticket.id}/edit")
        end

      {:noreply, socket}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end
```

As you can see, an `if patch = socket.assigns[:patch] do` was added. We used the syntax to retrieve a dynamic data `socket.assigns[:patch]` because it works even if the value is not defined. If the value is not defined, we go to the else clause.

At this point, your Quick Edit functionality should work completely!

## Creating a ticket via modal

Now that we've created the editing modal case, we're almost ready to do the same with the modal for quickly creating a ticket. Let's give it a try!

### Modifying the router

Your router will have 3 routes pointing to `TicketLive.Index`, each with a different live action. This is completely normal!

```elixir
live "/", TicketLive.Index, :index
live "/:id/edit", TicketLive.Index, :edit
live "/new", TicketLive.Index, :new # nova
```

### Improving `apply_action/3`

Remember we used a new private function to handle different live actions called `apply_action/3`? This makes it much easier to add a new case. Add an `alias Lineup.Queue.Ticket` and one more clause to your function as follows:

```elixir
defmodule LineupWeb.TicketLive.Index do
  # ...
  alias Lineup.Queue.Ticket

  # ...

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    ticket = Queue.get_ticket!(id)
    assign(socket, ticket: ticket)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, ticket: nil)
  end

  defp apply_action(socket, :new, _new) do
    ticket = %Ticket{}
    assign(socket, ticket: ticket)
  end

  # ...
end
```

The last case in `apply_action/3` handles the `:new` case and simply assigns `@ticket` to an empty ticket.

### Updating `render/1`

We need to do two things: update the link of the create ticket button and update the `:if` condition of the `<.modal>`.

```elixir
# ...

def render(assigns) do
  ~H"""
  <.header>
    Listing Tickets
    <:actions>
      <.link patch={~p"/new"}>
        <.button>New Ticket</.button>
      </.link>
    </:actions>
  </.header>

  # ...

  <.modal :if={@live_action in [:edit, :new]} id="ticket-modal" show on_cancel={JS.patch(~p"/")}>
    <.live_component
      module={FormComponent}
      id="quick-edit-form"
      ticket={@ticket}
      action={@live_action}
      patch={~p"/"}
    >
      <h1>Editing a ticket</h1>
    </.live_component>
  </.modal>
  """
end
```

Now the button performs a `patch` to `/new`. Our modal now handles both `:edit` and `:new` as live actions.

There you go! You now have both quick editing and quick creating functionalities!

### Deleting Dead Code

If you think about it, we no longer need a dedicated ticket creation page. Our `TicketLive.New` has become dead code!

We can delete the file `lib/lineup_web/live/ticket_live/new.ex` and remove from our router `live "/tickets/new", TicketLive.New, :new`.

### Final Code

Now that we've implemented the modal, we have in our system:

- A home page that lists tickets and has modals for creating and editing tickets, as well as the option to delete tickets.
- A dedicated page for showing the ticket.
- A dedicated page for editing the ticket.

You can choose to remove the dedicated editing page and let `TicketLive.Index` be the only place where you edit the ticket, or even use the quick edit modal on the page that shows the ticket. It's up to you.

If you had any issues you can see the final code for this lesson using `git checkout modal-form-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch modal-form-done`.

## Recap!

- The `<.modal>` component can be useful as a simple way to show forms.
- Since our forms are a Live Component, using them in new places is extremely simple, without fear of repeating code.
- We can use routes to define when a modal should open.
- By using different Live Actions, we can define different cases of `handle_params/3` for the same LiveView, as we did to make our `TicketLive.Index` work for both listing, editing, and creating tickets.
- To organize multiple live actions in the same LiveView, we chose to create an `apply_action/3` function for each action for organization purposes.
- We can render HEEx conditionally by checking the `@live_action` assign, as we did to only show the modal in `:new` and `:edit` cases.
