%{
title: "DRY Form",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "How to prevent code duplication with forms",
previous_page_id: "editing-data",
next_page_id: "live-component",
}

---

A good practice in computing is to avoid repeating code whenever possible. The DRY principle (Don't Repeat Yourself) is a mantra that you can carry with you during your day-to-day life as a developer.

At the end of the previous section, we noticed a considerable amount of code repetition in the form. In this section, we will analyze how to avoid this one step at a time.

## Starting Point

We will use the final code from the previous section as a base. In case you prefer to start from scratch, you can clone a ready-to-start version. Using your terminal:

```
git clone https://github.com/adopt-liveview/refactoring-crud.git
cd refactoring-crud
mix setup
```

With these commands, you should have an initial Phoenix project. The `mix setup` command not only installs but also compiles the dependencies for you. Once you have prepared the project and opened your preferred code editor, run `mix phx.server` and go to [http://localhost:4000](http://localhost:4000) to see the initial page of your Phoenix project.

If you haven't completed the previous section of this course, we hope you at least have some basic understanding of how LiveView forms work.

## Analyzing the Pieces

We will focus on two files: `ProductLive.New` (in `lib/super_store_web/live/product_live/new.ex`) and `ProductLive.Edit` (in `lib/super_store_web/live/product_live/edit.ex`). Both have:

1. A `mount/3` function that initializes the form.
2. A very similar `handle_event("validate_product" ...)`.
3. A very similar `handle_event("create_product", ...)` (or `"save_product"`).
4. A `<.form>` with the same data except for the title of the form itself.

When we need to add a new field, we would have to add it in both files. When we need to add some specific validation (e.g., validating if the product name is duplicated), we would have to do it in both forms. Can you see where I'm going with this?

### Reducing the Scope

Let's start by solving a smaller problem.

> 4. A `<.form>` with the same data except for the title of the form itself.

Can we reuse the HEEx code in two different files? Yes, we just need to create a component!

## Refactoring

The first step in refactoring something repetitive is to identify the point of duplication. At the moment, we are focusing only on HEEx code, so looking at both forms, we see a similarity in:

```elixir
# new.ex
~H"""
...
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
...
"""

# edit.ex
~H"""
...
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
...
"""
```

Only the `phx-submit` and the content of the `h1` change. As the `phx-change` and `phx-submit` bindings are attributes, we can pass them to the component as assigns. We will also need to pass the `@form` assign. As for the `h1`, we can simply use a slot since it is HEEx code.

### Introducing the `ProductLive.FormComponent`

Inside your `lib/super_store_web/live/product_live/` folder, create a file `form_component.ex` with the following code:

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :html

  attr :form, Phoenix.HTML.Form
  attr :rest, :global, include: ~w(phx-change phx-submit)
  slot :inner_block

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form for={@form} class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24" {@rest}>
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

Note that at the top, we use `use SuperStoreWeb, :html` and not `:live_view`. This file will not be a LiveView, i.e., a page in our website. It will only contain a component.

We use `attr` to receive the `:form` and use `:rest` as a `:global` attr to receive the bindings. Additionally, we use the slot `:inner_block` for the HEEx code of `<h1>`.

### Applying to LiveViews

In your `ProductLive.New`, add an `alias SuperStoreWeb.ProductLive.FormComponent` and let's use the component:

```elixir
defmodule SuperStoreWeb.ProductLive.New do
  # ...
  alias SuperStoreWeb.ProductLive.FormComponent

  # ...

  def render(assigns) do
    ~H"""
    <.header>
      New Product
      <:subtitle>Use this form to create product records in your database.</:subtitle>
    </.header>

    <FormComponent.render form={@form} phx-change="validate_product" phx-submit="create_product">
      <h1>Creating a product</h1>
    </FormComponent.render>

    <.back navigate={~p"/"}>Back to products</.back>
    """
  end
end
```

Since the component comes from another file, we use the syntax `<FormComponent.render ...>`. As discussed earlier, we pass the necessary attributes.

Similarly, in our `ProductLive.Edit`:

```elixir
defmodule SuperStoreWeb.ProductLive.Edit do
  # ...
  alias SuperStoreWeb.ProductLive.FormComponent

  # ...

  def render(assigns) do
    ~H"""
    <.header>
      Editing Product <%= @product.id %>
      <:subtitle>Use this form to edit product records in your database.</:subtitle>
    </.header>

    <FormComponent.render form={@form} phx-change="validate_product" phx-submit="save_product">
      <h1>Editing a product</h1>
    </FormComponent.render>

    <.back navigate={~p"/products/#{@product}"}>Back to product</.back>
    """
  end
end
```

### Success!

With this small modification, we managed to centralize the form in one place. Future additions to the form will affect both pages without needing to duplicate code.

If you had any issues you can see the final code for this lesson using `git checkout form-component-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch form-component-done`.

## Summary!

- Keeping the code DRY makes it easier to maintain it in the future.
- When you feel the need to refactor code to make it cleaner, analyze the points of repetition.
- If there are many points of repetition, try starting by reducing the scope to something simpler before moving forward.
- To avoid repetition of HEEx code, creating a component can be an excellent option.
