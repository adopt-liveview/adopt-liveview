%{
title: "Editing a product",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Editing existing data with LiveView forms",
previous_page_id: "deleting-data",
}

---

To finalize the CRUD we will create a product edit form. Let's see how this can be extremely similar to the product creation form.

%{
title: "This class is a direct continuation of the previous class",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch deleting-data- done`</code>.
"""
} %% .callout

## Back to Context

Let's go back to our `lib/super_store/catalog.ex` and add a new function:

```elixir
defmodule SuperStore.Catalog do
  # ...

  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end
end
```

Unlike `create_product/1` which only receives the attributes, to update a product we need the original data to be able to apply the changes. Our function `Catalog.update_product/2` receives the original struct and the modifications, applies the changeset, and using the function [`Repo.update/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:update/2) returns `{:ok, %Product{}}` or `{: error, %Ecto.Changeset{}}`.

### Testing on `iex`

Using Interactive Elixir we can get the last product with `product = SuperStore.Catalog.list_products() |> List.last` and update it using `SuperStore.Catalog.update_product(product, %{name: "Edited"}) `:

```elixir
$ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> product = SuperStore.Catalog.list_products() |> List.last

[debug] QUERY OK source="products" db=0.0ms idle=823.0ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%SuperStore.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  id: 7,
  name: "asda",
  description: "asd"
}

iex(2)> SuperStore.Catalog.update_product(product, %{name: "Edited"})

[debug] QUERY OK source="products" db=0.7ms idle=539.3ms
UPDATE "products" SET "name" = ? WHERE "id" = ? ["Edited", 7]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

{:ok,
 %SuperStore.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
   id: 7,
   name: "Edited",
   description: "asd"
 }}
iex(3)>
```

Note that in the second argument we only pass the name. Our changeset necessarily requires a `description` however, as the original product already has a description, this validation passes.

## Making our LiveView

Let's write the LiveView code step-by-step so that we can see the similarities with `ProductLive.Create`. In the folder `lib/super_store_web/live/product_live/` create a file `edit.ex`.

### Starting

```elixir
defmodule SuperStoreWeb.ProductLive.Edit do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product
end
```

The first step is to create the module and `use SuperStoreWeb, :live_view`. We then add two useful aliases for what comes next.

### The `mount/3`

```elixir
def mount(%{"id" => id}, _session, socket) do
  product = Catalog.get_product!(id)

  form =
    Product.changeset(product)
    |> to_form()

  {:ok, assign(socket, form: form, product: product)}
end
```

In our `mount/3` function we receive the `id` of the product as a parameter. Soon we will define this on the router as `live "/products/:id/edit", ProductLive.Edit, :edit` so we can guarantee that there will be this `id`.

The next step is to use `product = Catalog.get_product!(id)` to retrieve the product by `id`. It is worth remembering that if there is no product with this `id` a 404 error will be automatically generated as we saw in previous classes.

We define our `form` as a changeset that receives the original product. In the creation form we used `Product.changeset(%Product{})`, that is, the empty product because at that moment there is no product. As we are working with editing, all our changesets will receive the product being edited.

Also note that in assign we pass `product`. We will use this assignment not only in our HEEx but also in other events.

### The validation event

```elixir
def handle_event("validate_product", %{"product" => product_params}, socket) do
  form =
    Product.changeset(socket.assigns.product, product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

The validation event is a copy of the creation form except that `Product.changeset/2` receives at the first argument, instead of `%Product{}` (the empty product), `socket.assigns.product` which contains the value of the product being edited.

### The save event

```elixir
def handle_event("save_product", %{"product" => product_params}, socket) do
  socket =
    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, %Product{} = product} ->
        put_flash(socket, :info, "Product ID #{product.id} updated!")

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)

        socket
        |> assign(form: form)
        |> put_flash(:error, "Invalid data!")
    end

  {:noreply, socket}
end
```

Once again our event is a copy of the create product event. We renamed the event to `"save_product"` to make sense with this form and changed the main function in `case` to `Catalog.update_product/2` passing `socket.assign.product` once again. We also modified `put_flash/2` to a message that makes more sense for this case.

### The `render/1`

```elixir
def render(assigns) do
  ~H"""
  <.header>
    Editing Product <%= @product.id %>
    <:subtitle>Use this form to edit product records in your database.</:subtitle>
  </.header>

  <div class="bg-grey-100">
    <.form
      for={@form}
      phx-change="validate_product"
      phx-submit="save_product"
      class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
    >
      <h1>Editing a product</h1>
      <.input field={@form[:name]} placeholder="Name" />
      <.input field={@form[:description]} placeholder="Description" />

      <.button type="submit">Send</.button>
    </.form>
  </div>

  <.back navigate={~p"/products/#{@product}"}>Back to product</.back>
  """
end
```

In this part we only modified the texts and the name of the `phx-submit` binding event. There were no functional changes except that the `<.back>` component link now returns to the product view page.

### Updating the router

Open your router file and add the route `live "/products/:id/edit", ProductLive.Edit, :edit`. Your router should currently look like this:

```elixir
# ...
scope "/", SuperStoreWeb do
  pipe_through :browser

  live "/", ProductLive.Index, :index
  live "/products/new", ProductLive.New, :new
  live "/products/:id", ProductLive.Show, :show
  live "/products/:id/edit", ProductLive.Edit, :edit
end
# ...
```

## Adding a link to the form

We have a page, but our users don't know about it. Open your `ProductLive.Show` and update just the `<.header>` component to add this `<:actions>`:

```elixir
<.header>
  Product <%= @product.id %>
  <:subtitle>This is a product record from your database.</:subtitle>
  <:actions>
    <.link patch={~p"/products/#{@product}/edit"}>
      <.button>Edit event</.button>
    </.link>
  </:actions>
</.header>
```

## Final code

Done! Our application has a complete CRUD. There are still some things that can be improved and we will look at this in another section of this course but if you have followed the course so far you already have enough knowledge to get by creating your next CRUD!

If you had any issues you can see the final code for this lesson using `git checkout editing-data-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/first-crud.git --branch editing-data-done`.

## Recap!

- Using `Repo.update/2` we can update a product by passing a changeset.
- An edit form LiveView can be extremely similar to one for creating data.
- You already know how to do a complete CRUD in LiveView 😉.
