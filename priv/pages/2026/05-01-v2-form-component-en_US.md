%{
title: "DRY Form",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "How to prevent code duplication with forms",
previous_page_id: "v2-editing-data",
next_page_id: "v2-live-component",
}

---

%{
title: "This class is a direct continuation of the previous class",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git --branch editing-data-done`</code>.
"""
} %% .callout

A good practice in programming is to avoid repeating code whenever possible. The DRY principle (Don't Repeat Yourself) is a mantra that you can carry with you during your day-to-day life as a developer. At the end of the previous section, we noticed a considerable amount of code repetition in the form. In this section, we will analyze how to avoid this one step at a time.

## Using `diff`

The shell command `diff` can be a neat way to compare things when they're close enough. Lets try that out:

```sh
$ diff lib/lineup_web/live/ticket_live/new.ex lib/lineup_web/live/ticket_live/edit.ex
1c1
< defmodule LineupWeb.TicketLive.New do
---
> defmodule LineupWeb.TicketLive.Edit do
5d4
<   alias Lineup.Queue.Ticket
20c19
<           <.button navigate={~p"/"}>Cancel</.button>
---
>           <.button navigate={~p"/tickets/#{@ticket}"}>Cancel</.button>
28,29c27,28
<   def mount(_params, _session, socket) do
<     ticket = %Ticket{}
---
>   def mount(%{"id" => id}, _session, socket) do
>     ticket = Queue.get_ticket!(id)
35c34
<      |> assign(:page_title, "New Ticket")
---
>      |> assign(:page_title, "Edit Ticket")
51,52c50,51
<     case Queue.create_ticket(ticket_params) do
<       {:ok, _ticket} ->
---
>     case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
>       {:ok, ticket} ->
55,56c54,55
<          |> put_flash(:info, "Ticket created successfully")
<          |> push_navigate(to: ~p"/")}
---
>          |> put_flash(:info, "Ticket updated successfully")
>          |> push_navigate(to: ~p"/tickets/#{ticket}")}
```

## Analyzing the Pieces

We will focus on two files: `TicketLive.New` (in `lib/lineup_web/live/ticket_live/new.ex`) and `TicketLive.Edit` (in `lib/lineup_web/live/ticket_live/edit.ex`). Both have:

1. A `mount/3` function that initializes the form but only `Edit` module needs the ID.
2. The exact same `handle_event("validate" ...)`.
3. The exact same `handle_event("save", ...)`.
4. Minor differences on how `save_ticket/2` handles saving data, flash message and redirection.
5. A `<.form>` with the same data but different route per "Cancel" button.

When we need to add a new field, we would have to add it in both files. When we need to add some specific validation (e.g., validating if the ticket name is duplicated), we would have to do it in both forms. Can you see where I'm going with this?

## Reusing the same LiveView more than once

Its not against the rules to reuse a LiveView in different routes. In fact lets do it now. Rename `LineupWeb.TicketLive.New` to `LineupWeb.TicketLive.Form`, make sure to rename its file to `form.ex` too!

In your router, edit `/tickets/:new` and `/tickets/:id/edit` to use that same LiveView:

```elixir
scope "/", LineupWeb do
  pipe_through :browser

  live "/", TicketLive.Index, :index
  live "/tickets/new", TicketLive.Form, :new
  live "/tickets/:id", TicketLive.Show, :show
  live "/tickets/:id/edit", TicketLive.Form, :edit
end
```

And to check the damage you've done, run `mix test`:

```rs
$ mix test
Compiling 3 files (.ex)
Generated lineup app
Running ExUnit with seed: 603750, max_cases: 28

..........

  1) test Index updates ticket in listing (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:46
     Assertion with =~ failed
     code:  assert render(edit_form_live) =~ "Edit Ticket"
     left:  "A LOT OF HTML" <> ...
     right: "Edit Ticket"
     stacktrace:
       test/lineup_web/live/ticket_live_test.exs:55: (test)

.

  2) test Show updates ticket and returns to show (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:77
     ** (ArgumentError) expected LiveView to redirect to "/tickets/1/edit", but got "/tickets/1/edit"
     code: |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")
     stacktrace:
       (phoenix_live_view 1.1.28) lib/phoenix_live_view/test/live_view_test.ex:1796: Phoenix.LiveViewTest.__follow_redirect__/4
       test/lineup_web/live/ticket_live_test.exs:84: (test)

..
Finished in 0.1 seconds (0.05s async, 0.1s sync)
15 tests, 2 failures
```

Unit tests are a blessing because they can help us make sure our code works as expected. Now that we have failing tests, lets fix that.

### Custom title per route

Lets look back at our first failing test:

```sh
  1) test Index updates ticket in listing (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:46
     Assertion with =~ failed
     code:  assert render(edit_form_live) =~ "Edit Ticket"
     left:  "A LOT OF HTML" <> ...
     right: "Edit Ticket"
     stacktrace:
       test/lineup_web/live/ticket_live_test.exs:55: (test)
```

Since the failing assertion is pointed as `assert render(edit_form_live) =~ "Edit Ticket"` it means we simply need to update our HTML title according to the current route. That can be easily done by introducing a variable you didn't new until now called `socket.assigns.live_action`. As our router defined:

```elixir
live "/tickets/new", TicketLive.Form, :new
live "/tickets/:id/edit", TicketLive.Form, :edit
```

Both `:new` and `:edit` are possible values for `socket.assigns.live_action` and nothing else. We can leverage it in our `TicketLive.Form` like this:

```elixir
@impl true
def mount(_params, _session, socket) do
  ticket = %Ticket{}
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  {:ok,
   socket
   |> assign(:ticket, ticket)
   |> assign(:form, form)
   |> apply_action(socket.assigns.live_action)}
end

defp apply_action(socket, :edit) do
  socket
  |> assign(:page_title, "Edit Ticket")
end

defp apply_action(socket, :new) do
  socket
  |> assign(:page_title, "New Ticket")
end
```

We created a helper function called `apply_action/2` to check what's the `socket.assigns.live_action` and assign `@page_title` accordingly. If you head out to `/tickets/:id/edit` you can confirm that "Edit Ticket" is working again! As for our unit tests:

```sh
$ mix test
Running ExUnit with seed: 192910, max_cases: 28

.............

  1) test Show updates ticket and returns to show (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:77
     ** (ArgumentError) expected LiveView to redirect to "/tickets/1", but got "/"
     code: |> follow_redirect(conn, ~p"/tickets/#{ticket}")
     stacktrace:
       (phoenix_live_view 1.1.28) lib/phoenix_live_view/test/live_view_test.ex:1796: Phoenix.LiveViewTest.__follow_redirect__/4
       test/lineup_web/live/ticket_live_test.exs:92: (test)



  2) test Index updates ticket in listing (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:46
     ** (ArgumentError) expected LiveView to redirect to "/tickets/1", but got "/"
     code: |> follow_redirect(conn, ~p"/tickets/#{ticket}")
     stacktrace:
       (phoenix_live_view 1.1.28) lib/phoenix_live_view/test/live_view_test.ex:1796: Phoenix.LiveViewTest.__follow_redirect__/4
       test/lineup_web/live/ticket_live_test.exs:61: (test)


Finished in 0.1 seconds (0.06s async, 0.1s sync)
15 tests, 2 failures
```

Don't get discouraged! We fixed a issue, now its time to fix the next one.

### Handling edits

Right now our code is not updating any tickets but also it is creating new ones whenever you press "Save" and sends you to the root page. That's bad. To address this we first need to understand the difference between creating a new ticket and updating an existing one.

Create algorithm:
1. Store empty `%Ticket{}` into `socket.assigns.ticket`.
2. User press "Save" to send updated `ticket_params`.
3. Run `Queue.create_ticket(ticket_params)`.

Update algorithm:
1. Get `%Ticket{}` by `id` from URL `params` and store into `socket.assigns.ticket`.
2. User press "Save" to send updated `ticket_params`.
3. Run `Queue.update_ticket(socket.assigns.ticket, ticket_params)`.

With that knowledge we can conclude that we need to change how we get `%Ticket{}` and how we save it. We can leverage `socket.assigns.live_action` once more in our favor. Edit `TicketLive.Form` again like this:

```elixir
@impl true
def mount(params, _session, socket) do
  {:ok,
   socket
   |> apply_action(socket.assigns.live_action, params)}
end

defp apply_action(socket, :edit, %{"id" => id}) do
  ticket = Queue.get_ticket!(id)
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  socket
  |> assign(:page_title, "Edit Ticket")
  |> assign(:ticket, ticket)
  |> assign(:form, to_form(form))
end

defp apply_action(socket, :new, _params) do
  ticket = %Ticket{}
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  socket
  |> assign(:page_title, "New Ticket")
  |> assign(:ticket, ticket)
  |> assign(:form, to_form(form))
end

# handle_event("validate", ...) doesn't change at all!

def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, socket.assigns.live_action, ticket_params)
end

defp save_ticket(socket, :edit, ticket_params) do
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

defp save_ticket(socket, :new, ticket_params) do
  case Queue.create_ticket(ticket_params) do
    {:ok, _ticket} ->
      {:noreply,
        socket
        |> put_flash(:info, "Ticket created successfully")
        |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

We moved more from our `mount/3` into `apply_action/3` and now that method also receive `params` so it can use `id` on `:edit` and ignore them on `:new`. As for `handle_event("save" ...)` we did the same thing passing `socket.assigns.live_action` so create one clause per action. The contents of each `save_ticket/3` now behave exactly like `TicketLive.New` and `TicketLive.Edit` used to behave separately but this time we share everything else that was previously duplicated. Donf forget to delete `LineupWeb.TicketLive.Edit` if you didn't already. Now, `mix test` should be passing for all tests.

### Success!

With this small modification, we managed to centralize the form in one place. Future additions to the form will affect both pages without needing to duplicate code.

If you had any issues you can see the final code for this lesson using `git checkout form-component-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/lineup.git --branch form-component-done`.

## Summary!

- Keeping the code DRY makes it easier to maintain it in the future.
- When you feel the need to refactor code to make it cleaner, analyze the points of repetition.
- Tests will be a huge help when in need to refactor stuff without breaking your app. Did you notice we didn't change a single code in our tests during this lesson?
