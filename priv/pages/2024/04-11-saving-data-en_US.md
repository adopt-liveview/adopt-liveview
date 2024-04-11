%{
title: "Saving data with Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Persisting data",
previous_page_id: "my-first-liveview-project",
next_page_id: "listing-data"
}

---

We will finally start implementing our CRUD (Create-Read-Update-Delete). Currently, our project already has both LiveView and Ecto installed, so we will focus on how to put this into practice. In this class, we will learn how to persist our product in the database.

%{
title: "This class is a direct continuation of the previous class",
type: :warning,
description: ~H"""
If you went straight into this class it might be confusing because it is a direct continuation of the code from the previous class. If you want to skip the previous class and start straight with this one, you can clone the initial version for this class using the command <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch my-first- liveview-project-done`</code>.
"""
} %% .callout

## Important concepts of Ecto

Before we start new code, we will explore a little bit of what the Phoenix project has already installed for you and, at the same time, talk about the project patterns.

### Introducing `Repo`

If you go to the file `lib/super_store/repo.ex`, you'll see the following code:

```elixir
defmodule SuperStore.Repo do
  use Ecto.Repo,
    otp_app: :super_store,
    adapter: Ecto.Adapters.SQLite3
end
```

Ecto uses a Design Pattern called Repository to access the database. The rule is simple: if you intend to execute a query, you will use this module. Whenever the database needs to be accessed, you'll see something like `Repo.insert()` or `Repo.one()`.

Phoenix automatically generated this module `SuperStore.Repo`. The naming convention will always be in the format `YourProject.Repo`. Inside it, the `use Ecto.Repo` sets up the module with functions like `Repo.insert`, and the options passed define the configuration of our Repo. The `otp_app` option contains the name of our Mix project, `:super_store`, and we use `Ecto.Adapters.SQLite3` as the adapter.

### Migrating the database

To manage database modifications, Ecto uses the design pattern called [schema migrations](https://en.wikipedia.org/wiki/Schema_migration). The logic of migrations is simple: whenever you need to modify the structure of your database, you generate a migration that instructs Ecto what needs to be done.

Let's create your first migration: we want to create the products table. Using your terminal, execute `mix ecto.gen.migration create_products`. The result will be something like:

```bash
* creating priv/repo/migrations/20240405213602_create_products.exs
```

Don't worry if the name isn't exactly the same. Migrations have a timestamp at the beginning of their name to make it clear the order in which they were created. At this point, your migration should have a code similar to the following:

```elixir
defmodule SuperStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do

  end
end
```

Vamos modificar um pouquinho isso para:

```elixir
defmodule SuperStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :string, null: false
    end
  end
end
```

Within our module, we should have a `change/0` method. The responsibility of this method is to specify what changed in your database. The `Ecto.Migration` module that we imported at the top of our migration contains this and other Data Definition Language (DDL) functions prepared for common operations to modify the structure of our database.

Inside `change/0`, we can use [`create/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#create/2) to specify that we are creating something, [`table/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#table/2) to indicate that we are creating a new table called `products`, and [`add/3`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#add/3) to define the two columns named `name` and `description` within this table.

When your migration is ready, execute `mix ecto.migrate` to run it:

```bash
$ mix ecto.migrate

08:56:48.950 [info] == Running 20240405213602 SuperStore.Repo.Migrations.CreateProducts.change/0 forward

08:56:48.952 [info] create table products

08:56:48.955 [info] == Migrated 20240405213602 in 0.0s
```

%{
title: "How to undo a migration?",
type: :warning,
description: ~H"""
If something goes wrong or if you believe your migration was incorrect, you can always execute <code>`mix ecto.rollback`</code>'' to undo the migrations applied the last time you ran <code>`mix ecto.migrate`</code> (even if there were more than one). <br><br>If you're curious about how Ecto knows how to roll back, it's quite simple: if your migration has a <code>`create/2`</code> method with <code>`table/2`</code>, it knows that the reverse of this is to delete a table. That's why we can create a migration with just the <code>`change/0`</code> function instead of <code>`up`</code> and <code>`down`</code> as in other frameworks, although Ecto optionally accepts these callbacks if you have a specific migration for your current database.
"""
} %% .callout

### Updating our `Ecto.Schema`

Go to `lib/super_store/catalog/product.ex`. At the moment, it should be defined as:

```elixir
defmodule SuperStore.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
```

An `embedded_schema` is useful when you don't intend to work with a database. To make this schema work with a database, the modification is very simple! We'll use the macro [`schema/2`](https://hexdocs.pm/ecto/Ecto.Schema.html#schema/2) which takes the table name as the first argument so that when we use our `Repo`, it will know where to read/write the data from/to.

```elixir
defmodule SuperStore.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
```

With just one line of code, our schema is ready for complete CRUD operations!

### The context `Product.Catalog`

Let's go to `lib/super_store/catalog.ex`. In the previous lesson, we only created this module. We will concentrate all CRUD operations of our product system in this Context.

Everything related to products will be here. Phoenix is heavily inspired by Domain-Driven Design (DDD), where each part of your application focuses on its specific domain.

Let's add our first one: `create_product/1`:

```elixir
defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end
```

Using `alias` to write a bit less code, we create a function that takes `attrs` and validates them with our `Product.changeset/2`, then attempts to insert into our database. This function has two possible outcomes: `{:ok, %Product{...}` if everything goes well or `{:error, %Ecto.Changeset{...}}` if there is a validation error.

### Testing our module directly from the terminal

We can test everything we've built so far without even starting to work on our LiveView! Since we've constructed a module `SuperStore.Catalog` that doesn't depend on anything related to the web, we can simply start an interactive terminal with our project's mix code and execute the function `create_product/2`.

Sure, I'm ready to help with that. Could you please provide the commands you'd like me to execute, starting with `$`?

```elixir
$ iex -S mix
[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

Using `iex -S mix` we enter Interactive Elixir (`iex`) mode containing all the functions of our project. At the beginning of the last line you can see that `iex(1)>` has become your new command prompt. Let's import our context:

```elixir
iex(1)> alias SuperStore.Catalog
SuperStore.Catalog
iex(2)>
```

Now we can write `Catalog.` instead of `SuperStore.Catalog.`. Let's create our first product! Execute: `Catalog.create_product(%{ name: "Elixir in Action", description: "A great book" })`.

```elixir
iex(2)> Catalog.create_product(%{ name: "Elixir in Action", description: "A great book" })

[debug] QUERY OK source="products" db=0.7ms idle=1532.9ms
INSERT INTO "products" ("name","description") VALUES (?,?) RETURNING "id" ["Elixir in Action", "A great book"]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

{:ok,
 %SuperStore.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
   id: 1,
   name: "Elixir in Action",
   description: "A great book"
 }}
```

Excellent! Our database has one product. Let's check our validations. Use the following command to create an invalid product: `Catalog.create_product(%{ name: "Missing description" })`.

```elixir
iex(3)> Catalog.create_product(%{ name: "Missing description" })
{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{name: "Missing description"},
   errors: [description: {"can't be blank", [validation: :required]}],
   data: #SuperStore.Catalog.Product<>,
   valid?: false
 >}
```

As expected, our changeset handled our validation correctly and did not create anything in the database. Now that we know our Context works as expected, we can return to our LiveView.

## Using our Context in our LiveView

At this point, your PageLive should look like this:

```elixir
defmodule SuperStoreWeb.PageLive do
  use SuperStoreWeb, :live_view
  import SuperStoreWeb.CoreComponents
  alias SuperStore.Catalog.Product

  def mount(_params, _session, socket) do
    form =
      Product.changeset(%Product{})
      |> to_form()

    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate_product", %{"product" => product_params}, socket) do
    form =
      Product.changeset(%Product{}, product_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-change="validate_product"
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <h1>Creating a product</h1>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <.button type="submit">Send</.button>
      </.form>
    </div>
    """
  end
end
```

Our `"create_product"` event currently does nothing but generate a log in the terminal: `IO.inspect({"Form submitted!!", product_params})`. Let's improve on that.

### Improving our `"create_product"` event

At the top of your PageLive, create an `alias SuperStore.Catalog`. Modify the `"create_product"` event to:

```elixir
def handle_event("create_product", %{"product" => product_params}, socket) do
  socket =
    case Catalog.create_product(product_params) do
      {:ok, %Product{} = product} ->
        put_flash(socket, :info, "Product ID #{product.id} created!")

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)

        socket
        |> assign(form: form)
        |> put_flash(:error, "Invalid product!")
    end

  {:noreply, socket}
end
```

As mentioned earlier, our function `Catalog.create_product/2` has two possibilities. Using `case-do`, we can gracefully handle both. If the result is `{:ok, %Product{} = product}`, we add a success message to our socket using [`put_flash/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#put_flash/3).

If a validation error occurs, we receive the changeset and convert it into a `form` using `to_form/2`. Then, we use `put_flash/3`, this time to inform an error.

### Final code

Our final code for the LiveView:

```elixir
defmodule SuperStoreWeb.PageLive do
  use SuperStoreWeb, :live_view
  import SuperStoreWeb.CoreComponents
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product

  def mount(_params, _session, socket) do
    form =
      Product.changeset(%Product{})
      |> to_form()

    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate_product", %{"product" => product_params}, socket) do
    form =
      Product.changeset(%Product{}, product_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create_product", %{"product" => product_params}, socket) do
    socket =
      case Catalog.create_product(product_params) do
        {:ok, %Product{} = product} ->
          put_flash(socket, :info, "Product ID #{product.id} created!")

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)

          socket
          |> assign(form: form)
          |> put_flash(:error, "Invalid product!")
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-change="validate_product"
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <h1>Creating a product</h1>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <.button type="submit">Send</.button>
      </.form>
    </div>
    """
  end
end
```

If you found it challenging to follow the code in this lesson, you can see the completed code using `git checkout saving-data-done` or by cloning it into another folder using `git clone https://github.com/adopt-liveview/first-crud.git --branch saving-data-done`.

## In short!

- Ecto uses the Repository design pattern to interact with databases.
- Whenever we need to use the database, we'll use a function from the `Repo` module.
- Ecto uses the schema migrations design pattern to modify the database structure.
- To create a migration, you need to run `mix ecto.gen.migration migration_name` in the terminal.
- To apply pending migrations, you should run `mix ecto.migrate` in the terminal.
- To rollback the last applied migrations, you can run `mix ecto.rollback` in the terminal.
- A schema with `embedded_schema do` doesn't interact with the database, but `schema "table_name" do` is all you need to instruct Ecto how to interact with this table.
- In Phoenix projects, we concentrate functions related to a specific domain in a context module, following inspiration from [DDD](https://en.wikipedia.org/wiki/Domain-driven_design).
- In our current project, we focus our product management domain in the `SuperStore.Catalog` context.
- You can use `iex -S mix` to enter Interactive Elixir mode and test all functions in your project.
- Once your context and schema are well-designed, adding functions to your LiveView becomes trivial.
