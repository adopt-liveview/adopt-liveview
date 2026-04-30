%{
title: "Saving data with Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Persisting data with databases in LiveView projects",
previous_page_id: "v2-cleanup",
next_page_id: "v2-listing-data"
}

---

We will finally start implementing our CRUD (Create-Read-Update-Delete). Currently our project already has both LiveView and Ecto installed, so we will focus on getting that to work. In this lesson we will learn how to persist our ticket in the database.

%{
title: "This class is a direct continuation of the previous class",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch cleanup-done`</code>.
"""
} %% .callout

## Important concepts of Ecto

Before we start new code we will explore a little bit of what the Phoenix project has already installed for you and, at the same time, talk about the project patterns.

### Introducing `Repo`

If you go to the file `lib/lineup/repo.ex`, you'll see the following code:

```elixir
defmodule Lineup.Repo do
  use Ecto.Repo,
    otp_app: :lineup,
    adapter: Ecto.Adapters.SQLite3
end
```

Ecto uses a Design Pattern called Repository to access the database. The rule of thumb is simple: if you intend to execute a query you will use this module. Whenever the database needs to be accessed you'll see something like `Repo.insert()` or `Repo.one()`.

Phoenix automatically generated this module `Lineup.Repo`. The naming convention will always be in the format `YourProject.Repo`. Inside it the `use Ecto.Repo` line sets up the module with functions like `Repo.insert` and the options passed define the configuration of our Repo. The `otp_app` option contains the name of our Mix project, `:lineup`, and we use `Ecto.Adapters.SQLite3` as the adapter.

### Migrating the database

To manage database modifications, Ecto uses [schema migrations](https://en.wikipedia.org/wiki/Schema_migration) design pattern. The way migrations work is simple: whenever you need to modify the structure of your database you generate a migration that instructs Ecto what needs to be done.

Let's create your first migration: we want to create the tickets table. Using your terminal execute `mix ecto.gen.migration create_tickets`. The result will be something like:

```bash
* creating priv/repo/migrations/20260428160027_create_tickets.exs
```

Don't worry if the name isn't exactly the same. Migrations have a timestamp at the beginning of their name to make the order they should be executed clear. At this point your migration should have a code similar to the following:

```elixir
defmodule Lineup.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do

  end
end
```

Lets change it to:

```elixir
defmodule Lineup.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :called_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
```

Within our module we should have a `change/0` method. This method is used to specify what changed in your database. The `Ecto.Migration` module that we imported at the top of our migration contains this and other Data Definition Language (DDL) functions prepared for common operations to modify the structure of our database.

Inside `change/0`, we can use [`create/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#create/2) to specify that we are creating something, [`table/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#table/2) to indicate that we are creating a new table called `tickets`, and [`add/3`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#add/3) to define the two columns named `name` and `description` within this table.

When your migration is ready and saved execute `mix ecto.migrate` to run it:

```bash
$ mix ecto.migrate

08:56:48.950 [info] == Running 20260428160027 Lineup.Repo.Migrations.CreateTickets.change/0 forward

08:56:48.952 [info] create table tickets

08:56:48.955 [info] == Migrated 20260428160027 in 0.0s
```

%{
title: "How to undo a migration?",
type: :warning,
description: ~H"""
If something goes wrong or if you believe your migration was incorrect you can always execute <code>`mix ecto.rollback`</code> to undo the migrations applied the last time you ran <code>`mix ecto.migrate`</code> (even if there were more than one). <br><br>If you're curious about how Ecto knows how to roll back, it's quite simple: if your migration has a <code>`create/2`</code> method with <code>`table/2`</code> it knows that the reverse of this is to delete a table. That's why we can create a migration with just the <code>`change/0`</code> function instead of <code>`up`</code> and <code>`down`</code> as in other frameworks although Ecto optionally accepts these callbacks if you have a very specific migration for your current database.
"""
} %% .callout

### Creating our `Ecto.Schema`

Create `lib/lineup/queue/ticket.ex`. You might need to create the `queue` folder too. Write it as:

```elixir
defmodule Lineup.Queue.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :called_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:called_at])
    |> validate_required([:called_at])
  end
end
```

Previously we used a `embedded_schema` in the fundamentals course of this website as it is useful when you don't intend to work with a database. To make this schema work with a database the only modification needed is very simple! We used the macro [`schema/2`](https://hexdocs.pm/ecto/Ecto.Schema.html#schema/2) which takes the table name as the first argument so that when we use our `Repo` it will know where to read/write the data from/to.

### Your first context module

As mentioned previously, our queue ticket system main business logic module will be `Lineup.Queue` so thats why our `Ticket` module lives under `Lineup.Queue.Ticket`. In Phoenix we call modules that encapsulate functions that manage a part of our application business logic `Context Modules`. The `Queue` Context is responsible for managing our tickets. If we had a Context called `Accounts` it would be in charge of managing user accounts. Each Context can have zero or more schemas and generally the naming will be `YourProject.YourContext` and `YourProject.YourContext.YourSchema`.

Inside the `lib/lineup` folder create a file called queue.ex with the following content:

```elixir
defmodule Lineup.Queue do
  alias Lineup.Repo
  alias Lineup.Queue.Ticket

  @doc """
  Creates a ticket.

  ## Examples

      iex> create_ticket(%{field: value})
      {:ok, %Ticket{}}

      iex> create_ticket(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ticket(attrs) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ticket changes.

  ## Examples

      iex> change_ticket(ticket)
      %Ecto.Changeset{data: %Ticket{}}

  """
  def change_ticket(%Ticket{} = ticket, attrs \\ %{}) do
    Ticket.changeset(ticket, attrs)
  end
end
```

Everything related to tickets will be here. Phoenix is heavily inspired by Domain-Driven Design (DDD) where each part of your application focuses on its specific domain.

Use an `alias` to write a bit less code. We created a function that takes `attrs` and validates them with our `Ticket.changeset/2`, then attempts to insert into our database. This function has two possible outcomes: `{:ok, %Ticket{...}` if everything goes well or `{:error, %Ecto.Changeset{...}}` if there are validation errors. We also create a helper function to create changesets for our tickets.

%{
title: ~H"Why use <code>`Queue.change_ticket/2`</code> if someone could easily use <code>`Ticket.changeset/2`</code>?",
description: ~H"""
We use our context module to hide business logic as much as possible from our LiveViews. Right now the function is just doing nothing but routing the arguments to the changeset function but it doesn't mean it will be forever like that. Have we ever need to add some extra business logic to starting a changeset for a Ticket we can focus on improving our <code>`change_ticket/2`</code> instead of breaking the simplicity of <code>`Ticket.changeset/2`</code> function.
"""
} %% .callout

### Testing our module directly from the terminal

We can test everything we've built so far without even starting to work on our LiveView! Since we've constructed a module `Lineup.Queue` that doesn't depend on anything related to the web, we can simply start an interactive terminal with our project's mix code and execute the function `create_ticket/2`.

Using your terminal execture the command that follows the `$` prompt:

```elixir
$ iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

Using `iex -S mix` we entered Interactive Elixir (`iex`) mode containing all the functions of our project. At the beginning of the last line you can see that `iex(1)>` has become your new command prompt. Let's alias our context:

```elixir
iex(1)> alias Lineup.Queue
Lineup.Queue
iex(2)>
```

Now we can write `Queue.` instead of `Lineup.Queue.`. Let's create our first ticket! Execute: `Queue.create_ticket(%{})`.

```elixir
iex(2)> Queue.create_ticket(%{})
{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{},
   errors: [called_at: {"can't be blank", [validation: :required]}],
   data: #Lineup.Queue.Ticket<>,
   valid?: false,
   ...
 >}
```

Uh oh! back when we defined our schema we said that `called_at` was mandatory! But on our real application you need to get the ticket first and then you're gonna get called. Without leaving you `iex` shell change this at `lib/lineup/queue/ticket.ex` and save the file:

```diff
- |> validate_required([:called_at])
+ |> validate_required([])
```

Then run `recompile` inside it and try again to create your ticket. Tip: you can press up to find previous commands in `iex`.

```elixir
iex(3)> recompile
Compiling 1 file (.ex)
Generated lineup app
:ok

iex(4)> Queue.create_ticket(%{})
[debug] QUERY OK source="tickets" db=0.7ms decode=0.6ms idle=515.9ms
INSERT INTO "tickets" ("inserted_at","updated_at") VALUES (?1,?2) RETURNING "id" [~U[2026-04-29 19:23:38Z], ~U[2026-04-29 19:23:38Z]]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
{:ok,
 %Lineup.Queue.Ticket{
   __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
   id: 2,
   called_at: nil,
   inserted_at: ~U[2026-04-29 19:23:38Z],
   updated_at: ~U[2026-04-29 19:23:38Z]
 }}
```

Now that we know our Context works as expected we can return to our LiveView work!

## Using our Context in our LiveView

First, lets add a new route to our project:

```elixir
scope "/", LineupWeb do
  pipe_through :browser

  live "/", TicketLive.Index, :index
  live "/tickets/new", TicketLive.New, :new
end
```

Also we need to write our new LiveView TicketLive.New

```elixir
defmodule LineupWeb.TicketLive.New do
  use LineupWeb, :live_view

  alias Lineup.Queue
  alias Lineup.Queue.Ticket

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
          <.button navigate={~p"/"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    ticket = %Ticket{}

    {:ok,
     socket
     |> assign(:page_title, "New Ticket")
     |> assign(:ticket, ticket)
     |> assign(:form, to_form(Queue.change_ticket(ticket)))}
  end

  @impl true
  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    changeset = Queue.change_ticket(socket.assigns.ticket, ticket_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    save_ticket(socket, ticket_params)
  end

  defp save_ticket(socket, ticket_params) do
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
end
```

That's a lot of code! To better understand what we just wrote lets break it down by parts.

### Our `<.header>` component

```elixir
@impl true
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash}>
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage ticket records in your database.</:subtitle>
    </.header>
    ...    
  </Layouts.app>
  """
end
```

`<.header>` is a component under `CoreComponents` that can be used to make page header styles consistent across all apps. Bored on how they look? Just edit the component definition and see all headers be updated. As a general advice from someone who worked with LiveView a lot: having components to encapsulate styles not only makes your LiveView render function code more elegant and readable as it also makes things easy to update. If you find yourself repeating code across all your UI, it might be time for a new component to be born. As you can see `<.header>` also has an optional slot called `<:subtitle>`. Feel free to look into that component definition in `lib/lineup_web/components/core_components.ex` if you want to learn more.

%{
title: ~H"Did you notice we used <code>@page_title</code> in our HEEx code?",
description: ~H"""
Even though <code>@page_title</code> is a special assign since it holds meaning to the HTML title tag it doesn't mean you can't use it just like any other assign.
"""
} %% .callout

### Our `<.form>`

```elixir
~H"""
...
<.form for={@form} id="ticket-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:called_at]} type="datetime-local" label="Called at" />
  <footer>
    <.button phx-disable-with="Saving..." variant="primary">Save Ticket</.button>
    <.button navigate={~p"/"}>Cancel</.button>
  </footer>
</.form>
...
"""
```

As we learned from lessons in the Fundamentals course, Phoenix projects come with a built-in `<.form>` component that shall be used to handle forms across your codebase. Now, from the very start we are using `CoreComponets`' `<.input>` and `<.button>` components as we only have written them before for learning purposes. Just like the `<.header>` component, if you ever feel bored on how your app looks like you can always edit these styles in `CoreComponents` later.

A new attribute we haven't talked about before though is `phx-disable-with`. This attribute is a [Phoenix binding](https://hexdocs.pm/phoenix_live_view/bindings.html) that works exclusively for form submit buttons to show a loading message as the client is waiting on the server's response. It is advised to use those not only to create a better loading state UX without much code but also to prevent someone from furiously pressing submit buttons multiple times which could lead to duplicated creations.

### Our `mount/3` callback

```elixir
@impl true
def mount(_params, _session, socket) do
  ticket = %Ticket{}
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  {:ok,
   socket
   |> assign(:page_title, "New Ticket")
   |> assign(:ticket, ticket)
   |> assign(:form, form)}
end
```

Similar to what we learned on Fundamentals course we use a changeset to track validation and then we convert it to a Phoenix.Form using the `to_form/2` function. We will see in the next section why we also assigned the empty ticket to our socket.

### Our validation event

```elixir
...
@impl true
def handle_event("validate", %{"ticket" => ticket_params}, socket) do
  changeset = Queue.change_ticket(socket.assigns.ticket, ticket_params)
  {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
end
...
```

To apply validations we need to create a "validate" event (since we wrote in HEEx that `phx-change="validate"`) and receive the `ticket_params`. For this validation all we need is to access the original `%Ticket{}` (which is empty) from `socket.assigns.ticket` (thats why we assigned it to the socket before), use `Queue.change_ticket/2` again then assign the new form value alongiside `action: :validate` so our form knows that it should show validation errors.

## Our save event

```elixir
...
def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, ticket_params)
end

defp save_ticket(socket, ticket_params) do
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

Very similarly to what we just wrote in our `"validate"` event, now we will handle the same `ticket_params` but using `Queue.create_ticket/2` directly (remember, it also uses changesets behind the scenes so any validation error will cause a `{:error, %Ecto.Changeset{}}`),.

In our success scenario we will have `{:ok, ticket}` but we dont need its ID so we just ignore the variable using underscore in the name and we do two things:

1. We use [`put_flash/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#put_flash/3) to add an information message about our ticket being created which will go into the `@flash` assignment we mentioned before. Think of `@flash` as a way to pass notifications from LiveView to your frontend (even though it can do so much more).
2. We use [push_navigate/2](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_navigate/2) to redirect our users to the home page. Its worth mentioning that `push_navigate/2` uses LiveView internal mechanisms to do optimized redirections when possible (between views in the same scope) by doing WebSocket messages instead of a full browser refresh like regular redirects do.

If a validation error occurs we receive the changeset and convert it into a `form` using `to_form/2`.

If you had any issues you can see the final code for this lesson using `git checkout saving-data-done` or by cloning it into another folder using `git clone https://github.com/adopt-liveview/lineup --branch saving-data-done`.

## Recap!

- Ecto uses the Repository design pattern to interact with databases.
- Whenever we need to use the database we'll use a function from the `Repo` module.
- Ecto uses the schema migrations design pattern to modify the database structure.
- To create a migration you need to run `mix ecto.gen.migration migration_name` in the terminal.
- To apply pending migrations you should run `mix ecto.migrate` in the terminal.
- To rollback the lastest applied migrations you can run `mix ecto.rollback` in the terminal.
- A schema with `embedded_schema do` doesn't interact with the database but `schema "table_name" do` is all you need to instruct Ecto how to interact with that table.
- In Phoenix projects we concentrate functions related to a specific domain in a context module, following inspiration from [DDD](https://en.wikipedia.org/wiki/Domain-driven_design).
- In our current project we focused our ticket management domain in the `Lineup.Queue` context.
- You can use `iex -S mix` to enter Interactive Elixir mode and test all functions in your project.
- When your context and schema are well-designed, adding functions to your LiveView becomes trivial.
