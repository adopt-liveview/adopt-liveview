%{
title: "Simplifying everything with Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "Forms",
description: "Now we are getting serious",
previous_page_id: "v2-form-validation",
next_page_id: "v2-my-first-liveview-project"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch form-validation-done`</code>.
"""
} %% .callout

Now that you understand not only how forms work behind the scenes but also how to reason about the flow of forms and events, let's simplify everything!

## Introducing Ecto

Ecto is a library in Elixir that manages database access. Over time the community noticed that Ecto's validation pattern was quite powerful and abstractions to validate data without even considering the database were emerging. Today we will use one of them.

It's worth mentioning that in new Phoenix projects Ecto comes by default, so understanding Ecto will not only help us today to refactor our form into more manageable code but it will also teach you the fundamentals of Ecto so that you can use this library in future projects.

## Refactoring our previous form to Ecto

Let's get straight to the point. Create a `Product` module in `lib/myapp/products/product.ex`:

```elixir
defmodule Myapp.Products.Product do
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

Also update your `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  alias Myapp.Products.Product

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
    <div>
      <.form
        for={@form}
        phx-change="validate_product"
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto p-24"
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

### Understanding an Ecto Schema

```elixir
defmodule Myapp.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  # ...
end
```

The magic starts here. We defined a module called `Myapp.Products.Product` to represent the data in our form. Do note that this module is not under `MyappWeb` but instead its `Myapp.Products.Product`. Phoenix projects like to separate business logic from web logic. We will dive into why we put `Product` nested in `Products` soon enough, for now you just need to understand that this is a convention.

The first thing we do inside our module is `use Ecto.Schema` so that our module receives the DSL (Domain Specific Language) that lets us use macros like `embedded_schema` and `field` to define the format of our Product model. Think of this DSL as a simple way to define a Struct in Elixir.

We also imported [`Ecto.Changeset`](https://hexdocs.pm/ecto/Ecto.Changeset.html). Changesets are data structures that contain data about modifications to something. In this case our Changeset will contain data about modifications, errors and validations of our Product struct. Think of changesets as a validation step.

### Understanding an `embedded_schema`

```elixir
defmodule Myapp.Products.Product do
  # ...

  embedded_schema do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  # ...
end
```

In Ecto terms, Embedded Schemas are data that live only in memory without being saved in a database. Using the above syntax and defining the struct fields with [`field/3`](https://hexdocs.pm/ecto/Ecto.Schema.html#field/3) we can easily tell which data belongs to the Product struct. Essentially what this piece of code does is say that a Struct Product starts as `%Product{name: "", description: ""}` with its DSL.

### The `changeset/2` function

```elixir
defmodule Myapp.Products.Product do
  # ...

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
```

An Ecto.Schema with at least one `changeset/2` function is a given. These functions are under your full control and are used to define how we validate data. In previous lessons validation took place within LiveView but this left our code messy and difficult to reuse. In Phoenix projects, validations are almost always carried out at the level of an Ecto.Schema in `changeset/2` functions.

We receive two arguments: the product and optional parameters (note that if nothing is passed we use the default `%{}`). With these two values in mind we use pipes to transform this value as follows:

- We have a struct of `%Product{name: "", description: ""}` (since our form starts with an empty `%Product{}`).
- Using the function [`cast/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) we transform the `%Product{}` into a `%Ecto.Changeset{}` receiving the `params` and accepting only the `params` that are `:name` or `:description`.
- Using the function [`validate_required/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3) we receive the `%Ecto.Changeset{}` and validate that `:name` and `:description` are present.

At the end of the function we will have a validated changeset. The `Ecto.Changeset` module contains several useful validation functions and you can also create custom validations. At this moment we will continue only with `validate_required/3`.

## Using changesets in our LiveView

```elixir
defmodule MyappWeb.PageLive do
  # ...

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

  # ...
end
```

Now that we have changesets the only refactoring necessary for our LiveView happened in the callbacks. Let's analyze them step by step.

#### The new `mount/3`

```elixir
def mount(_params, _session, socket) do
  form =
    Product.changeset(%Product{})
    |> to_form()

  {:ok, assign(socket, form: form)}
end
```

In our `mount/3` we use the module's `changeset/2` function without passing the second argument as we know that there is no modified data. We immediately pass the result to `to_form/2`.

You may be wondering: don't we need an `as: :product`? Phoenix forms are prepared to automatically convert the `Ecto.Schema` names so that a `Product` schema implicitly means `as: :product` in `to_form/2`. It's worth remembering that from the beginning we mentioned that this was the Phoenix standard and you can see how the framework takes this seriously to the point of simplifying it for you.

#### The new `handle_event/3`

```elixir
def handle_event("validate_product", %{"product" => product_params}, socket) do
  form =
    Product.changeset(%Product{}, product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

Very similar to `mount/3`, our function also uses changeset to create `Phoenix.HTML.Form`. We had two modifications:

- We pass the `product_params` to the changeset so that the new data is validated.
- We use `Map.put/3` to define that the changeset is in validation mode. This is necessary so that our LiveView knows that the changeset has been validated and errors can be rendered.

## Recap!

- Ecto is a powerful library for managing powerful database access.
- Phoenix projects use Ecto by default not only to work with databases but also to validate data.
- We can use `Ecto.Schema` to easily create a `Struct`. As we are not working with a database (yet) we use `embedded_schema` and `fields` to be able to create data only in memory.
- We can use `Ecto.Changeset` to easily validate user data going into your struct.
- Usually an `Ecto.Schema` has one or more `changeset/2` functions to define how to validate its data and are used as `Product.changeset(%Product{}, params)`.
- Our LiveViews become cleaner when we separate the validation logic from our UI logic.
