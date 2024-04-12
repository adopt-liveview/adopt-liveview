%{
title: "Deleting a product",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Creating a UX to delete an item",
previous_page_id: "show-data",
next_page_id: "editing-data"
}

---

Let's skip to the last letter of CRUD: Delete. In this lesson, we'll see how simple it is to create a UX to delete an item using resources from our project.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you've jumped straight into this lesson, it might be confusing because it's a direct continuation of the previous one. If you want to skip the previous lesson and start directly with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch show-data-done`</code>.
"""
} %% .callout

## You probably guessed that we'd start with the Context.

The first step is to go back to our `lib/super_store/catalog.ex` file and add a new function:

```elixir
defmodule SuperStore.Catalog do
  # ...

  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end
end
```

The `delete_product/1` function takes a struct of type `%Product{}` and simply applies the [`Repo.delete/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:delete/2) method to it. The result will be `{:ok, %Product{}}` if it is necessary to use the product again.

### Testing on `iex`

Using the reliable Elixir Interactive mode, we can fetch the last product with `product = SuperStore.Catalog.list_products() |> List.last` and delete it using `SuperStore.Catalog.delete_product(product)`:

```elixir
$ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> product = SuperStore.Catalog.list_products() |> List.last

[debug] QUERY OK source="products" db=0.2ms queue=0.1ms idle=1192.5ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%SuperStore.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  id: 10,
  name: "asda",
  description: "ad"
}

iex(2)> SuperStore.Catalog.delete_product(product)
[debug] QUERY OK source="products" db=1.7ms idle=1366.3ms
DELETE FROM "products" WHERE "id" = ? [10]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405
{:ok,
 %SuperStore.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:deleted, "products">,
   id: 10,
   name: "asda",
   description: "ad"
 }}
```

## Deleting products in the list

Instead of creating a new LiveView called `ProductLive.Delete`, we can reuse the product list for this purpose. Open your `ProductLive.Index` located in `lib/super_store_web/live/product_live/index.ex`.

### The `<:action>` slot of the `<.table>` component

Within your `render/1`, update your `<.table>` to the following code:

```elixir
<.table
  id="products"
  rows={@streams.products}
  row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
>
  <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
  <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
  <:action :let={{id, product}}>
    <.link
      phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>
```

We added a slot called `<:action>` where we receive both the `id` and the `product` using the special attribute `:let`. This slot is placed as the last column to add action buttons to our row.

### The ID from the `:let`

This specific `id` is known as the "HTML ID" and, in this case, it should be something like "products-123" because our table has the ID "products" and assuming the ID in the database of the item is 123. It's useful for applying JS commands.

### Confirming actions with `data-confirm`

The next focus point is `data-confirm`. We don't want the item to be deleted immediately without any kind of confirmation, right? Phoenix checks that if you click on an element with `data-confirm`, it triggers a `confirm` dialog in your browser and only applies the `phx-click` if the user confirms.

### The `JS.hide/2` command

Within our `phx-click` binding, two things occur:

1. We send an event to our LiveView called "delete" (we still need to define it).
2. We hide the element of the current row using the HTML ID.

As you can see, we're not directly using `JS.hide/2` but rather just the `hide/1` function. This is because Phoenix already provides this simplified function within `CoreComponents`, which applies transitions using CSS classes! Within your `CoreComponents`:

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

To be able to test this code we need to create our `handle_event/3`. In your LiveView, below `mount/3` add the callback:

```elixir
def handle_event("delete", %{"id" => id}, socket) do
  product = Catalog.get_product!(id)
  {:ok, _} = Catalog.delete_product(product)

  {:noreply, stream_delete(socket, :products, product)}
end
```

In this event we only receive the ID, we immediately check in the database if the product exists using the `Catalog.get_product/1` function that we built in the previous class. We then delete the product. As we already have the `product` variable we ignore the second result of the delete function.

### The `stream_delete/3` function

In previous classes we had already seen how to create streams using `stream/4` to render lists in an efficient way. Now we see the [`stream_delete/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream_delete/3) function to delete an item from the stream.

Remembering that streams do not store any data in memory about the items, the `stream_detele/3` function receives the name of the stream which is `:products` as we defined in our `mount/3` and the `product`. Using these two variables, it infers that the HTML ID of the element will be `#products-123` and sends simple data indicating that LiveView should delete this element from the HTML. Remembering that the element was already hidden using our `hide/1` previously.

### LiveView Code

With all the pieces together your `ProductLive.Index` should be close to this code:

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog

  def mount(_params, _session, socket) do
    socket = stream(socket, :products, Catalog.list_products())
    {:ok, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Listing Products
      <:actions>
        <.link patch={~p"/products/new"}>
          <.button>New Product</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="products"
      rows={@streams.products}
      row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
    >
      <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
      <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
      <:action :let={{id, product}}>
        <.link
          phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end
end
```

## Final code

Ready! Now you just need to test your LiveView and see how the current flow is working.

If you had difficulty following the code in this class, you can see the ready-made code for this class using `git checkout deleting-data-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/first -crud.git --branch deleting-data-done`.

## In short!

- The function `Repo.delete/2` receives a struct from an Ecto schema and deletes it from the database.
- The `<:action>` slot is useful for adding action buttons to your tables.
- The IDs that come from the special attribute `:let` in component slots `<.table>` are called HTML ID and follow the format `name-of-your-stream-ID` (where ID is the ID in the database element data).
- The HTML ID is useful for applying JS commands.
- The `CoreComponents` of Phoenix projects comes with a `hide/1` function that is just `JS.hide/2` but with a beautiful transition.
- We can use `data-confirm` to confirm with the user before triggering an action like a `phx-click`.
- The `stream_delete/3` function is a way to delete elements from a stream. This function optimizes sending the minimum amount of data to LiveView so it follows the idea that streams are an efficient way to manage lists in LiveView.
