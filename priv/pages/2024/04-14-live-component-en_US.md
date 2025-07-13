%{
title: "Live Component",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "How to reuse logic in components",
previous_page_id: "form-component",
next_page_id: "modal-form",
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

Let's start by converting the new product form to a Live Component. Open your `ProductLive.FormComponent` and edit it to:

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :live_component

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

There were no major changes here other than removing the `attr` and `slot`, removing the `@rest` assign, and the main change: we changed at the top from `use SuperStoreWeb, :html` to `use SuperStoreWeb, :live_component`. With this, we can now apply the Live Component.

### Using a Live Component

Go to your `ProductLive.New` and edit its HEEx code for the form to:

```elixir
~H"""
...
<.live_component
  module={FormComponent}
  id="new-form"
>
  <h1>Creating a product</h1>
</.live_component>
"""
```

To use a Live Component, we should use the `<.live_component>` component, passing at least the `module` and `id` as parameters. At the moment, it doesn't do anything. Let's go back to the `ProductLive.FormComponent`.

### Initializing the state of the `FormComponent`

At the moment, your creation form page should raise an exception. This happens because we haven't initialized the `@form`. Let's start by learning the new initialization callback for Live Components: `update/2`:

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :live_component
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product

  def update(assigns, socket) do
    form =
      Product.changeset(%Product{})
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

def handle_event("validate", %{"product" => product_params}, socket) do
  form =
    %Product{}
    |> Product.changeset(product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end

def handle_event("save", %{"product" => product_params}, socket) do
  case Catalog.create_product(product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product created successfully")
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

As you can see, the entire creation logic is a copy of the original. It's worth mentioning that we added a `|> push_navigate(to: ~p"/products/")` so that when the product is created, the user is redirected to the product list.

### `phx-target`

In our current `render/1`, we updated our `<.form>` to add the form bindings, but a new binding appears: `phx-target`. To understand this binding, I need to reveal to you a new piece of information about Live Components: they live in an isolated process.

Knowing that a Live Component lives in its own process, you need to make it explicit that the form events are handled by it and not by the parent Live View. Using `phx-target={@myself}`, the `<.form>` will know where to send events.

## Generalizing the component

At the moment, the Live Component only knows how to create new products. Now, let's see how to generalize it to handle editing.

### Where to change the code?

Lets identify which areas need some changes to make editing work:

1. The `update/2` should know to initialize the form with an empty product or an existing product.
2. The `handle_event("validate", ...)` should know to initialize the form with an empty product or an existing product.
3. The `handle_event("save", ...)` should know whether to use `Catalog.create_product/1` or `Catalog.update_product/2`.

Here's a suggestion: items 1 and 2 are all about "knowing the product". For new product form we'll use an empty product and for editing product form we'll use the existing product. This can be solved with an assign like `<.live_component module={FormComponent} product={...}>`.

As for the third item it depends on knowing whether it's edition or creation form. We can also solve this with an assign like `<.live_component module={FormComponent} action={:new / :edit}>`. Additionally, we can use the automatic assign `@live_action` that comes from the router. If the page is `:edit`, `@live_action` will be `:edit`. This simplifies things!

### Updating our LiveViews

In your `ProductLive.New`, update the HEEx code to:

```elixir
~H"""
...
<.live_component module={FormComponent} id="new-form" product={%Product{}} action={@live_action}>
  <h1>Creating a product</h1>
</.live_component>
...
"""
```

In your `ProductLive.Edit`, update the HEEx code to:

```elixir
~H"""
...
<.live_component module={FormComponent} id={@product.id} product={@product} action={@live_action}>
  <h1>Editing a product</h1>
</.live_component>
...
"""
```

### Improving the `update/2`

Let's go back to the `FormComponent`. Since we know that the Live Component will always receive a `product` as an assign, we can do:

```elixir
def update(%{product: product} = assigns, socket) do
  form =
    Product.changeset(product)
    |> to_form()

  {:ok,
   socket
   |> assign(form: form)
   |> assign(assigns)}
end
```

Additionally, since the `product` variable is part of the `assigns`, in the future we can use `socket.assigns.product`.

### Improving the `handle_event("validate", ...)`

```elixir
def handle_event("validate", %{"product" => product_params}, socket) do
  form =
    socket.assigns.product
    |> Product.changeset(product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

Instead of directly using `%Product{}`, the only thing that changed here is that we built the `form` using `socket.assigns.product`, which comes from our `<.live_component ... product={...}>`.

### Improving the `handle_event("save", ...)`

At this point, we will use `socket.assigns.action` to determine which action to take:

```elixir
def handle_event("save", %{"product" => product_params}, socket) do
  case socket.assigns.action do
    :new ->
      case Catalog.create_product(product_params) do
        {:ok, product} ->
          {:noreply,
           socket
           |> put_flash(:info, "Product created successfully")
           |> push_navigate(to: ~p"/")}

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, form: form)}
      end

    :edit ->
      case Catalog.update_product(socket.assigns.product, product_params) do
        {:ok, product} ->
          {:noreply,
           socket
           |> put_flash(:info, "Product updated successfully")
           |> push_navigate(to: ~p"/products/#{product.id}/edit")}

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, form: form)}
      end
  end
end
```

As you can see, the only new thing here is the outermost `case` that checks the value of `socket.assigns.action`. However, our function has become quite large and with nested `case` statements. We can improve this by creating another function!

```elixir
def handle_event("save", %{"product" => product_params}, socket) do
  save_product(socket, socket.assigns.action, product_params)
end

defp save_product(socket, :edit, product_params) do
  case Catalog.update_product(socket.assigns.product, product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product updated successfully")
       |> push_navigate(to: ~p"/products/#{product.id}/edit")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end

defp save_product(socket, :new, product_params) do
  case Catalog.create_product(product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product created successfully")
       |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end
```

Now our `"save"` event simply forwards values to a new private function called `save_product/3`. This function uses pattern matching to check the second argument if it is `:edit` or `:new` and applies the necessary functions.

## Reviewing the final code

Let's take a look at each part of the code we touched in this lesson to see the final product.

### `ProductLive.FormComponent`

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :live_component
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product

  def update(%{product: product} = assigns, socket) do
    form =
      Product.changeset(product)
      |> to_form()

    {:ok,
     socket
     |> assign(form: form)
     |> assign(assigns)}
  end

  def handle_event("validate", %{"product" => product_params}, socket) do
    form =
      socket.assigns.product
      |> Product.changeset(product_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_navigate(to: ~p"/products/#{product.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)
        {:noreply, assign(socket, form: form)}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Catalog.create_product(product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
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

### `ProductLive.New`

```elixir
defmodule SuperStoreWeb.ProductLive.New do
  use SuperStoreWeb, :live_view
  import SuperStoreWeb.CoreComponents
  alias SuperStore.Catalog.Product
  alias SuperStoreWeb.ProductLive.FormComponent

  def render(assigns) do
    ~H"""
    <.header>
      New Product
      <:subtitle>Use this form to create product records in your database.</:subtitle>
    </.header>

    <.live_component module={FormComponent} id="new-form" product={%Product{}} action={@live_action}>
      <h1>Creating a product</h1>
    </.live_component>

    <.back navigate={~p"/"}>Back to products</.back>
    """
  end
end
```

### `ProductLive.Edit`

```elixir
defmodule SuperStoreWeb.ProductLive.Edit do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog
  alias SuperStoreWeb.ProductLive.FormComponent

  def mount(%{"id" => id}, _session, socket) do
    product = Catalog.get_product!(id)
    {:ok, assign(socket, product: product)}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Editing Product <%= @product.id %>
      <:subtitle>Use this form to edit product records in your database.</:subtitle>
    </.header>

    <.live_component module={FormComponent} id={@product.id} product={@product} action={@live_action}>
      <h1>Editing a product</h1>
    </.live_component>

    <.back navigate={~p"/products/#{@product}"}>Back to product</.back>
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
- When creating events in Live Components, you can use `phx-target={@myself}` to make it clear that the event will be handled by this component and not the LiveView that contains it.
