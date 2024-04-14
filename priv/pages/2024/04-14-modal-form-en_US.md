%{
title: "Modal Form",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "How to reuse forms in a modal",
previous_page_id: "live-component",
}

---

Now that our form is in a Live Component, we can reuse it much more easily. In this lesson, we will learn how to use the `<.modal>` component to create a quick edit form for products on the home page.

%{
title: "This lesson is a direct continuation of the previous one.",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/refactoring.git --branch live-component-done`</code>.
"""
} %% .callout

## Using `ProductLive.Index` for editing?

In previous lessons, we saw how it's possible to use the same LiveView for more than one action. Let's make our `ProductLive.Index` capable of both listing and editing a product! In your router file, add the second clause of your index route:

```elixir
live "/", ProductLive.Index, :index
live "/:id/edit", ProductLive.Index, :edit # Add this line
```

Now our `ProductLive.Index` route has two possible values for `@live_action`: `:index` or `:edit`.

### Adding a link for quick editing

Open the `index.ex` file and edit the table that lists products as follows:

```elixir
~H"""
...

<.table
  id="products"
  rows={@streams.products}
  row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
>
  <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
  <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
  <:action :let={{_id, product}}>
    <.link patch={~p"/#{product}/edit"}>Quick Edit</.link>
  </:action>
  <:action :let={{id, product}}>
    <.link
      phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>

...
"""
```

We added a new `<:action>` slot with just a link to the new editing route. Note that we used `<.link patch={}>` because we are in the same LiveView! Another point to remember about `patch` is that it calls `handle_params/3`. Let's create this callback for our LiveView:

```elixir
def handle_params(params, _uri, socket) do
  case socket.assigns.live_action do
    :edit ->
      %{"id" => id} = params
      product = Catalog.get_product!(id)
      {:noreply, assign(socket, product: product)}

    :index ->
      {:noreply, assign(socket, product: nil)}
  end
end
```

Much like we did in the previous lesson, we simply check the value of `socket.assigns.live_action` to determine what to do. In the case of editing, we need to know about the product to be edited, so we receive the product's `id` from the `params` (which comes from the URL) and assign its value. In the case of the `:index` action, we can simply assign `product` as `nil`.

If you also remember from the previous lesson, we can simplify this `case` by creating a new function!

```elixir
def handle_params(params, _uri, socket) do
  {:noreply, apply_action(socket, socket.assigns.live_action, params)}
end

defp apply_action(socket, :edit, %{"id" => id}) do
  product = Catalog.get_product!(id)
  assign(socket, product: product)
end

defp apply_action(socket, :index, _params) do
  assign(socket, product: nil)
end
```

Now our `handle_params/3` is much more readable, and this convention of creating a private function `apply_action/3` is very common in Phoenix projects.

### Adding the modal

At the moment, clicking on Quick Edit correctly redirects you to the new route, but nothing new appears on your screen. Let's add the form Live Component. Alias `SuperStoreWeb.ProductLive.FormComponent` and add the following code at the end of your `render/1`.

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  # ...
  alias SuperStoreWeb.ProductLive.FormComponent

  def render(assigns) do
    ~H"""
    # ...

    <.modal :if={@live_action == :edit} id="product-modal" show on_cancel={JS.patch(~p"/")}>
      <.live_component
        module={FormComponent}
        id="quick-edit-form"
        product={@product}
        action={@live_action}
      >
        <h1>Editing a product</h1>
      </.live_component>
    </.modal>
    """
  end
end
```

The magic happens in the special attribute `:if`. If `@live_action` is `:edit`, the modal appears. If the modal is closed, the `on_cancel` property defines that the user should be redirected to the home page.

### Redirection issues

At this point, your form works correctly. Use Quick Edit to edit any item. Oops? Did you get redirected to the product editing page?

This happens because in our `ProductLive.FormComponent`, we defined that after editing a product, we go directly to the editing page. To avoid this, we can introduce a new optional assign called `patch`.

Inside your `ProductLive.Index`, update the code of your modal to:

```elixir
~H"""
...

<.modal :if={@live_action == :edit} id="product-modal" show on_cancel={JS.patch(~p"/")}>
  <.live_component
    module={FormComponent}
    id="quick-edit-form"
    product={@product}
    action={@live_action}
    patch={~p"/"}
  >
    <h1>Editing a product</h1>
  </.live_component>
</.modal>
"""
```

In your `ProductLive.FormComponent` look for the `save_product` at the `:edit` case and change the code to:

```elixir
defp save_product(socket, :edit, product_params) do
  case Catalog.update_product(socket.assigns.product, product_params) do
    {:ok, product} ->
      socket =
        socket
        |> put_flash(:info, "Product updated successfully")

      socket =
        if patch = socket.assigns[:patch] do
          push_patch(socket, to: patch)
        else
          push_navigate(socket, to: ~p"/products/#{product.id}/edit")
        end

      {:noreply, socket}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end
```

As you can see, an `if patch = socket.assigns[:patch] do` was added. We used the syntax to retrieve a dynamic data `socket.assigns[:patch]` because it works even if the value is not defined. If the value is not defined, we go to the else clause.

At this point, your Quick Edit functionality should work completely!

## Creating a product via modal

Now that we've created the editing modal case, we're almost ready to do the same with the modal for quickly creating a product. Let's give it a try!

### Modifying the router

Your router will have 3 routes pointing to `ProductLive.Index`, each with a different live action. This is completely normal!

```elixir
live "/", ProductLive.Index, :index
live "/:id/edit", ProductLive.Index, :edit
live "/new", ProductLive.Index, :new # nova
```

### Improving `apply_action/3`

Remember we used a new private function to handle different live actions called `apply_action/3`? This makes it much easier to add a new case. Add an `alias SuperStore.Catalog.Product` and one more clause to your function as follows:

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  # ...
  alias SuperStore.Catalog.Product

  # ...

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Catalog.get_product!(id)
    assign(socket, product: product)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, product: nil)
  end

  defp apply_action(socket, :new, _new) do
    product = %Product{}
    assign(socket, product: product)
  end

  # ...
end
```

The last case in `apply_action/3` handles the `:new` case and simply assigns `@product` to an empty product.

### Updating `render/1`

We need to do two things: update the link of the create product button and update the `:if` condition of the `<.modal>`.

```elixir
# ...

def render(assigns) do
  ~H"""
  <.header>
    Listing Products
    <:actions>
      <.link patch={~p"/new"}>
        <.button>New Product</.button>
      </.link>
    </:actions>
  </.header>

  # ...

  <.modal :if={@live_action in [:edit, :new]} id="product-modal" show on_cancel={JS.patch(~p"/")}>
    <.live_component
      module={FormComponent}
      id="quick-edit-form"
      product={@product}
      action={@live_action}
      patch={~p"/"}
    >
      <h1>Editing a product</h1>
    </.live_component>
  </.modal>
  """
end
```

Now the button performs a `patch` to `/new`. Our modal now handles both `:edit` and `:new` as live actions.

There you go! You now have both quick editing and quick creating functionalities!

### Deleting Dead Code

If you think about it, we no longer need a dedicated product creation page. Our `ProductLive.New` has become dead code!

We can delete the file `lib/super_store_web/live/product_live/new.ex` and remove from our router `live "/products/new", ProductLive.New, :new`.

### Final Code

Now that we've implemented the modal, we have in our system:

- A home page that lists products and has modals for creating and editing products, as well as the option to delete products.
- A dedicated page for showing the product.
- A dedicated page for editing the product.

You can choose to remove the dedicated editing page and let `ProductLive.Index` be the only place where you edit the product, or even use the quick edit modal on the page that shows the product. It's up to you.

If you had any issues you can see the final code for this lesson using `git checkout modal-form-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch modal-form-done`.

## Recap!

- The `<.modal>` component can be useful as a simple way to show forms.
- Since our forms are a Live Component, using them in new places is extremely simple, without fear of repeating code.
- We can use routes to define when a modal should open.
- By using different Live Actions, we can define different cases of `handle_params/3` for the same LiveView, as we did to make our `ProductLive.Index` work for both listing, editing, and creating products.
- To organize multiple live actions in the same LiveView, we chose to create an `apply_action/3` function for each action for organization purposes.
- We can render HEEx conditionally by checking the `@live_action` assign, as we did to only show the modal in `:new` and `:edit` cases.
