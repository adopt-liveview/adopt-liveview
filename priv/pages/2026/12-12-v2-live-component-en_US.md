%{
title: "Live Component",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "How to reuse logic in components",
previous_page_id: "v2-form-component",
next_page_id: "v2-modal-form",
}

---

In the previous lesson, we learned how to reuse HEEx code using components. However, up to now, we haven't seen any case where we could reuse callback code in a LiveView. For this, we will learn about an important new part of LiveView: Live Components.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/refactoring-crud.git --branch form-component-done`</code>.
"""
} %% .callout

## What is a Live Component?

So far, we've only talked about functional components. They allowed us to greatly simplify our code by preventing us from repeating HTML and will facilitate maintaining our code in the future. However, their limitation is that they have no relationship with business logic.

Live Components, on the other hand, bring not only the advantages of functional components but they can also manage their own local state. Think of Live Components as if they were LiveViews that can be nested within other LiveViews.

## Converting our current code to Live Component

Let's start by converting the new ticket form to a Live Component. Open your `TicketLive.FormComponent` and edit it to:

```elixir
defmodule LineupWeb.TicketLive.FormComponent do
  use LineupWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <%= render_slot(@inner_block) %>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <.button type="submit">Send</.button>
      </.form>
    </div>
    """
  end
end
```

There were no major changes here other than removing the `attr` and `slot`, removing the `@rest` assign, and the main change: we changed at the top from `use LineupWeb, :html` to `use LineupWeb, :live_component`. With this, we can now apply the Live Component.

### Using a Live Component

Go to your `TicketLive.New` and edit its HEEx code for the form to:

```elixir
~H"""
...
<.live_component
  module={FormComponent}
  id="new-form"
>
  <h1>Creating a ticket</h1>
</.live_component>
"""
```

To use a Live Component, we should use the `<.live_component>` component, passing at least the `module` and `id` as parameters. At the moment, it doesn't do anything. Let's go back to the `TicketLive.FormComponent`.

### Initializing the state of the `FormComponent`

At the moment, your creation form page should raise an exception. This happens because we haven't initialized the `@form`. Let's start by learning the new initialization callback for Live Components: `update/2`:

```elixir
defmodule LineupWeb.TicketLive.FormComponent do
  use LineupWeb, :live_component
  alias Lineup.Queue
  alias Lineup.Queue.Ticket

  def update(assigns, socket) do
    form =
      Ticket.changeset(%Ticket{})
      |> to_form()

    {:ok,
     socket
     |> assign(form: form)
     |> assign(assigns)}
  end

  # ...
end
```

The `update/2` callback for Live Components looks very similar to the `mount/3` of a LiveView. It receives the `assigns` passed in the `<.live_component>` and the `socket`. Just like in `mount/3`, we create the `form` and assigned it.

The main difference here is that we take the received `assigns` in the callback and do `assign(assigns)` so that all of them are available within the component as well. In other words, if you use `<.live_component module={FormComponent} x={10} y={20}>`, within your Live Component, `@x` and `@y` will be available.

### Adding events

```elixir
# ...

def handle_event("validate", %{"ticket" => ticket_params}, socket) do
  form =
    %Ticket{}
    |> Ticket.changeset(ticket_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end

def handle_event("save", %{"ticket" => ticket_params}, socket) do
  case Queue.create_ticket(ticket_params) do
    {:ok, ticket} ->
      {:noreply,
       socket
       |> put_flash(:info, "Ticket created successfully")
       |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end

def render(assigns) do
  ~H"""
  <div class="bg-grey-100">
    <.form
      for={@form}
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save"
      class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
    >
      <%= render_slot(@inner_block) %>
      <.input field={@form[:name]} placeholder="Name" />
      <.input field={@form[:description]} placeholder="Description" />

      <.button type="submit">Send</.button>
    </.form>
  </div>
  """
end
```

As you can see, the entire creation logic is a copy of the original. It's worth mentioning that we added a `|> push_navigate(to: ~p"/tickets/")` so that when the ticket is created, the user is redirected to the ticket list.

### `phx-target`

In our current `render/1`, we updated our `<.form>` to add the form bindings, but a new binding appears: `phx-target`. To understand this binding, I need to reveal to you a new piece of information about Live Components: they live in an isolated process.

Knowing that a Live Component lives in its own process, you need to make it explicit that the form events are handled by it and not by the parent Live View. Using `phx-target={@myself}`, the `<.form>` will know where to send events.

## Generalizing the component

At the moment, the Live Component only knows how to create new tickets. Now, let's see how to generalize it to handle editing.

### Where to change the code?

Lets identify which areas need some changes to make editing work:

1. The `update/2` should know to initialize the form with an empty ticket or an existing ticket.
2. The `handle_event("validate", ...)` should know to initialize the form with an empty ticket or an existing ticket.
3. The `handle_event("save", ...)` should know whether to use `Queue.create_ticket/1` or `Queue.update_ticket/2`.

Here's a suggestion: items 1 and 2 are all about "knowing the ticket". For new ticket form we'll use an empty ticket and for editing ticket form we'll use the existing ticket. This can be solved with an assign like `<.live_component module={FormComponent} ticket={...}>`.

As for the third item it depends on knowing whether it's edition or creation form. We can also solve this with an assign like `<.live_component module={FormComponent} action={:new / :edit}>`. Additionally, we can use the automatic assign `@live_action` that comes from the router. If the page is `:edit`, `@live_action` will be `:edit`. This simplifies things!

### Updating our LiveViews

In your `TicketLive.New`, update the HEEx code to:

```elixir
~H"""
...
<.live_component module={FormComponent} id="new-form" ticket={%Ticket{}} action={@live_action}>
  <h1>Creating a ticket</h1>
</.live_component>
...
"""
```

In your `TicketLive.Edit`, update the HEEx code to:

```elixir
~H"""
...
<.live_component module={FormComponent} id={@ticket.id} ticket={@ticket} action={@live_action}>
  <h1>Editing a ticket</h1>
</.live_component>
...
"""
```

### Improving the `update/2`

Let's go back to the `FormComponent`. Since we know that the Live Component will always receive a `ticket` as an assign, we can do:

```elixir
def update(%{ticket: ticket} = assigns, socket) do
  form =
    Ticket.changeset(ticket)
    |> to_form()

  {:ok,
   socket
   |> assign(form: form)
   |> assign(assigns)}
end
```

Additionally, since the `ticket` variable is part of the `assigns`, in the future we can use `socket.assigns.ticket`.

### Improving the `handle_event("validate", ...)`

```elixir
def handle_event("validate", %{"ticket" => ticket_params}, socket) do
  form =
    socket.assigns.ticket
    |> Ticket.changeset(ticket_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

Instead of directly using `%Ticket{}`, the only thing that changed here is that we built the `form` using `socket.assigns.ticket`, which comes from our `<.live_component ... ticket={...}>`.

### Improving the `handle_event("save", ...)`

At this point, we will use `socket.assigns.action` to determine which action to take:

```elixir
def handle_event("save", %{"ticket" => ticket_params}, socket) do
  case socket.assigns.action do
    :new ->
      case Queue.create_ticket(ticket_params) do
        {:ok, ticket} ->
          {:noreply,
           socket
           |> put_flash(:info, "Ticket created successfully")
           |> push_navigate(to: ~p"/")}

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, form: form)}
      end

    :edit ->
      case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
        {:ok, ticket} ->
          {:noreply,
           socket
           |> put_flash(:info, "Ticket updated successfully")
           |> push_navigate(to: ~p"/tickets/#{ticket.id}/edit")}

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, form: form)}
      end
  end
end
```

As you can see, the only new thing here is the outermost `case` that checks the value of `socket.assigns.action`. However, our function has become quite large and with nested `case` statements. We can improve this by creating another function!

```elixir
def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, socket.assigns.action, ticket_params)
end

defp save_ticket(socket, :edit, ticket_params) do
  case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
    {:ok, ticket} ->
      {:noreply,
       socket
       |> put_flash(:info, "Ticket updated successfully")
       |> push_navigate(to: ~p"/tickets/#{ticket.id}/edit")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end

defp save_ticket(socket, :new, ticket_params) do
  case Queue.create_ticket(ticket_params) do
    {:ok, ticket} ->
      {:noreply,
       socket
       |> put_flash(:info, "Ticket created successfully")
       |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end
```

Now our `"save"` event simply forwards values to a new private function called `save_ticket/3`. This function uses pattern matching to check the second argument if it is `:edit` or `:new` and applies the necessary functions.

## Reviewing the final code

Let's take a look at each part of the code we touched in this lesson to see the final ticket.

### `TicketLive.FormComponent`

```elixir
defmodule LineupWeb.TicketLive.FormComponent do
  use LineupWeb, :live_component
  alias Lineup.Queue
  alias Lineup.Queue.Ticket

  def update(%{ticket: ticket} = assigns, socket) do
    form =
      Ticket.changeset(ticket)
      |> to_form()

    {:ok,
     socket
     |> assign(form: form)
     |> assign(assigns)}
  end

  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    form =
      socket.assigns.ticket
      |> Ticket.changeset(ticket_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    save_ticket(socket, socket.assigns.action, ticket_params)
  end

  defp save_ticket(socket, :edit, ticket_params) do
    case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
      {:ok, ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ticket updated successfully")
         |> push_navigate(to: ~p"/tickets/#{ticket.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)
        {:noreply, assign(socket, form: form)}
    end
  end

  defp save_ticket(socket, :new, ticket_params) do
    case Queue.create_ticket(ticket_params) do
      {:ok, ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ticket created successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)
        {:noreply, assign(socket, form: form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <%= render_slot(@inner_block) %>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <.button type="submit">Send</.button>
      </.form>
    </div>
    """
  end
end
```

### `TicketLive.New`

```elixir
defmodule LineupWeb.TicketLive.New do
  use LineupWeb, :live_view
  import LineupWeb.CoreComponents
  alias Lineup.Queue.Ticket
  alias LineupWeb.TicketLive.FormComponent

  def render(assigns) do
    ~H"""
    <.header>
      New Ticket
      <:subtitle>Use this form to create ticket records in your database.</:subtitle>
    </.header>

    <.live_component module={FormComponent} id="new-form" ticket={%Ticket{}} action={@live_action}>
      <h1>Creating a ticket</h1>
    </.live_component>

    <.back navigate={~p"/"}>Back to tickets</.back>
    """
  end
end
```

### `TicketLive.Edit`

```elixir
defmodule LineupWeb.TicketLive.Edit do
  use LineupWeb, :live_view
  alias Lineup.Queue
  alias LineupWeb.TicketLive.FormComponent

  def mount(%{"id" => id}, _session, socket) do
    ticket = Queue.get_ticket!(id)
    {:ok, assign(socket, ticket: ticket)}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Editing Ticket <%= @ticket.id %>
      <:subtitle>Use this form to edit ticket records in your database.</:subtitle>
    </.header>

    <.live_component module={FormComponent} id={@ticket.id} ticket={@ticket} action={@live_action}>
      <h1>Editing a ticket</h1>
    </.live_component>

    <.back navigate={~p"/tickets/#{@ticket}"}>Back to ticket</.back>
    """
  end
end
```

### Conclusion

As we can see, the LiveViews became quite lean. There is no repeated form code. With this lesson, we learned how to reuse business logic in more than one LiveView using Live Components!

If you had any issues you can see the final code for this lesson using `git checkout live-component-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch live-component-done`.

## Recap!

- Live Components are components capable of managing their own state. They are also an excellent tool to avoid code duplication.
- To create a Live Component, you can use `use YourProjectWeb, :live_component` at the top of the module.
- To use a Live Component, you use the `<.live_component module={SomeModule} id="some-id">` component.
- You can use the `update/2` callback of a Live Component to define the initial state.
- You can use `assign(socket, assigns)` within the `update/2` to save all assigns passed in the `<.live_component x={10} y={20} z={30}>` call to the component.
- Live Components live in separate processes from the LiveView that uses them.
- When creating events in Live Components, you should use `phx-target={@myself}` to make it clear that the event will be handled by this component and not the LiveView that contains it.
