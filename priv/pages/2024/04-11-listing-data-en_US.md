%{
title: "Listing products",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Organizing our project and listing our products",
previous_page_id: "saving-data",
next_page_id: "show-data"
}

---

In the previous lesson we created some products! Let's create a simple page to list saved products.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you jumped straight into this lesson, it might be confusing as it's a direct continuation of the code from the previous one. If you want to skip the previous lesson and start directly from this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch saving-data-done`</code>.
"""
} %% .callout

## Back to our Context

Remember that all operations related to modifying our product domain will be concentrated in the `Catalog` context. At this moment we need a function to list all products. Open `lib/super_store/catalog.ex` and add the `list_products/0` method:

```elixir
defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def list_products() do
    Product
    |> Repo.all()
  end

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end
```

To list rows from our database, we use the function [`Repo.all/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:all/2) which takes an Ecto query and returns all rows. Our `Product` module itself is considered a query and, in this case, represents `select * from products`.

### Testing in `iex`.

Open your `iex -s mix` and execute `SuperStore.Catalog.list_products()`:

```elixir
$ iex -S mix
[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> SuperStore.Catalog.list_products()

[debug] QUERY OK source="products" db=0.2ms queue=0.2ms idle=283.7ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

[
  %SuperStore.Catalog.Product{
    __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
    id: 1,
    name: "Elixir in Action",
    description: "A great book"
  },
  ...
]
```

As you can see, our function works. We can proceed to apply it in a new LiveView.

## Creating a new LiveView

To list our products, we will create a new LiveView called `SuperStoreWeb.ProductLive.Index`. Phoenix projects like to follow this pattern: `YourAppWeb.NameOfSomethingLive.{Index, Show, New, or Edit}`. Create the folder `lib/super_store_web/live/product_live` and inside it, create a file named `index.ex` with the following code:

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog

  def mount(_params, _session, socket) do
    socket = stream(socket, :products, Catalog.list_products())
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.table id="products" rows={@streams.products}>
      <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
      <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
    </.table>
    """
  end
end
```

### Remember streams?

In the lesson on rendering lists we discussed streams as an optimized way to render items in HEEx. In that lesson there was a bit more complexity in the code because we needed to add an `id` to each element. But in this case, since we're working with a database, all elements have an `id`, so we can define a stream of products without any hassle.

### Using the `<.table>` component

Phoenix projects contain a very powerful component called `<.table>` in their `CoreComponents`. Throughout the CRUD lessons we'll learn more about it.

```elixir
<.table id="products" rows={@streams.products}> ... </.table>
```

At the moment all you need to understand is that this component works very well with streams. We pass two assigns to the component: an unique `id` and `rows` receives the stream of `products`.

```elixir
<:col :let={{_id, product}} label="Name"><%= product.name %></:col>
```

Inside the component, you can see that we use the `<:col>` slot twice. Each of these slots requires a `label` attribute to define the column name in the table and receives the special attribute `:let` for you to access `{id, element}`. At the moment, we can ignore the `id` and receive the `product` to render the content of that column for each product. If all of this seems very weird to you, you can take a look at our lesson on rendering lists with slots in the component section.

## Updating our old LiveView

Currently, in the `lib/super_store_web/live` folder, we have the file `page_live.ex`. With this name, the purpose of this LiveView isn't obvious. Move this file to `lib/super_store_web/live/product_live/new.ex` and rename the module to `SuperStoreWeb.ProductLive.New`. Now, not only we know its purpose from the folder structure but also the module name also follows the Phoenix convention!

## Updating our `router.ex`

Open your router at `lib/super_store_web/router.ex` and modify your routes within the main scope:

```elixir
scope "/", SuperStoreWeb do
  pipe_through :browser

  live "/", ProductLive.Index, :index
  live "/products/new", ProductLive.New, :new
end
```

Note that we also changed the live action from `ProductLive.New` to make it clear that it's a LiveView that creates something.

Success! Open your browser and you'll see that at the homepage all your products are listed. But wait, how do we go to the new product page? Your user won't guess the route!

### Connecting the pages using links

Go to your `ProductLive.Index` and modify its `render/1` a bit:

```elixir
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

  <.table id="products" rows={@streams.products}>
    <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
    <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
  </.table>
  """
end
```

We used the `<.header>` component, which also comes from the `CoreComponents`, not only to give a title to our product list page but also to use its `<:action>` slot to add a link to our product page.

Similarly, modify the `render/1` of your `ProductLive.New` to:

```elixir
def render(assigns) do
  ~H"""
  <.header>
    New Product
    <:subtitle>Use this form to create product records in your database.</:subtitle>
  </.header>

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

  <.back navigate={~p"/"}>Back to products</.back>
  """
end
```

In addition to the `<.header>` at the top, we added the `<.back>` component at the bottom, referencing the home page of our application. In case you're curious, this component isn't magical at all; it's just a `<.link>` with a back icon (a left arrow).

## Final code

Now your application is not only more organized in terms of folders but the user will also have a good first navigation experience.

If you found it challenging to follow the code in this lesson, you can see the completed code using `git checkout listing-data-done` or by cloning it into another folder using `git clone https://github.com/adopt-liveview/first-crud.git --branch listing-data-done`.

## Recap!

- Using `Repo.all/2` we can list the result of an Ecto query.
- The `Product` module can be considered an Ecto query in the format `select * from products`.
- Phoenix projects like to follow this pattern: `YourAppWeb.NameOfSomethingLive.{Index, Show, New, or Edit}`.
- To keep your LiveView folders more organized in your project, we use the format `lib/your_app_web/live/your_model/{index.ex, new.ex, edit.ex, show.ex}`, as we'll see in future lessons.
- When using databases it's very easy to use streams in LiveView because the elements already come with an `id`.
- The `<.table>` component is very powerful in simplifying tables with items, as we'll see in the future.
- In your `router.ex`, prefer Live Actions between `:new`, `:index`, `:edit`, and `:show`, as we'll see in the next lessons.
- The `<.header>` component is very useful for titling your pages and can also contain an `<:actions>` slot to simplify adding action buttons, as we used to add the create product button.
