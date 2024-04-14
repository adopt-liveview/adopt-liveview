%{
title: "Showing a product",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Showing a specific product on your LiveView project",
previous_page_id: "listing-data",
next_page_id: "deleting-data"
}

---

In our previous lesson we created the list of products for our application. In this lesson we'll finish the Read part of our CRUD: we'll create the page that displays a specific product.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch listing-data-done`</code>.
"""
} %% .callout

## Once more, Context

By this point you've probably guessed that we're going to start by editing the Context Module in `lib/super_store/catalog.ex`. Open this file and add the following line at the end:

```elixir
defmodule SuperStore.Catalog do
  # ...

  def get_product!(id), do: Repo.get!(Product, id)
end

```

This time you can see that the function name is slightly different: it has an exclamation mark at the end. Not only the function we're creating but also the function [`Repo.get/3`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:get!/3) have an exclamation mark. In Elixir, we call these "bang functions".

### Understanding bang functions

While you may have noticed that some Elixir functions prefer to return `{:ok, data}` or `{:error, data}`, bang functions prefer to return the data or raise an exception. Let's see this for real. Enter Interactive Elixir using `iex -S mix`. Let's assume your system has a product with ID 1.

```elixir
[I] ➜ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> SuperStore.Catalog.get_product!(1)

[debug] QUERY OK source="products" db=1.8ms queue=0.2ms idle=74.6ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 WHERE (p0."id" = ?) [1]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%SuperStore.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  id: 1,
  name: "Elixir in Action",
  description: "A great book"
}

iex(2)> SuperStore.Catalog.get_product!(100000000)

[debug] QUERY OK source="products" db=14.9ms idle=1617.2ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 WHERE (p0."id" = ?) [100000000]

  ↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405
** (Ecto.NoResultsError) expected at least one result but got none in query:

from p0 in SuperStore.Catalog.Product,
  where: p0.id == ^100_000_000

    (ecto 3.11.2) lib/ecto/repo/queryable.ex:164: Ecto.Repo.Queryable.one!/3
    iex:2: (file)
iex(2)>
```

When we use the function `SuperStore.Catalog.get_product!/1` with the existing ID 1, the result is the product itself, without the format `{:ok, product}`. When we use it with a non-existent ID, the result is an exception `Ecto.NoResultsError`. What advantage is there in using this format instead of simply handling the error ourselves?

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

## Creating our `ProductLive.Show`

Inside the folder `lib/super_store_web/live/product_live`, create a file called `show.ex` with the following content:

```elixir
defmodule SuperStoreWeb.ProductLive.Show do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog

  def handle_params(%{"id" => id}, _uri, socket) do
    product = Catalog.get_product!(id)
    socket = assign(socket, product: product)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Product <%= @product.id %>
      <:subtitle>This is a product record from your database.</:subtitle>
    </.header>

    <.list>
      <:item title="Name"><%= @product.name %></:item>
      <:item title="Description"><%= @product.description %></:item>
    </.list>

    <.back navigate={~p"/"}>Back to products</.back>
    """
  end
end
```

Note that we used `handle_params/3` instead of `mount/3` to receive the params. There's no particular reason for this choice other than to show how simple it can be to switch between these two. Inside the function we call our bang function without considering the case where the product may not exist, and we assign it to our socket.

### The `<.list>` component

Within our `render/1`, the only new component is the `<.list>`, which also comes from the `CoreComponents`. For each `<:item>` slot, it receives a `title` and renders the inner block. This component is useful for displaying things in a `key-value` format.

### Updating our router

Open your `router.ex` and add the new route below the others:

```elixir
live "/products/:id", ProductLive.Show, :show
```

Once again, we're following not only the naming convention for the LiveView but also for the live action `:show`.

Open a tab [http://localhost:4000/products/1](http://localhost:4000/products/1) and see your product being displayed. Similarly, switch to a non-existent ID like [http://localhost:4000/products/1123](http://localhost:4000/products/1123) and see the error message.

### Nice error messages in the development environment

It's worth mentioning that on the page with the non-existent ID you should have seen a well-formatted error message with code being displayed and much more information. Phoenix brings this error screen only in the development environment. In production you'll see only a generic "Not found" message because we don't want to leak any information about our code to users.

If you want to see how the generic message looks without having to deploy, you can open `config/dev.exs`, change `debug_errors: true` to `false`, and restart the server.

## Creating a link from the list to the product

Once again, we shouldn't make our users figure out where things are. Open your `ProductLive.Index` and edit only the table inside the `render/1` to:

```elixir
<.table
  id="products"
  rows={@streams.products}
  row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
>
  <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
  <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
</.table>
```

Now, when you click on a row in the table, your user will go to `ProductLive.Show`. The `<.table>` component accepts an assign called `row_click`, which takes an anonymous function and passes `{id, product}` to it. We can ignore the `id` and use the `product` directly.

### `JS.navigate/2`

Here we introduce a new JS Command: [`JS.navigate/1`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#navigate/1). It takes a URL and simply navigates the user to it.

### `Phoenix.Param`

You might be surprised that the URL is `~p"/products/#{product}"` instead of `~p"/products/#{product.id}"` (do note the `.id`). This is because Phoenix knows how to convert an Ecto schema like `%Product{}` to an URL by reading its ID. Just an [internal framework trivia](https://hexdocs.pm/phoenix/Phoenix.Param.html) for you to know.

## Final code

Using the route to show a product, we were able to learn many things related to the Phoenix framework and the Elixir programming language.

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
