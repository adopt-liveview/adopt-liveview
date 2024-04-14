%{
title: "My first LiveView project",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Finally a project!",
previous_page_id: "simple-forms-with-ecto",
next_page_id: "saving-data"
}

---

This section of the course is going to be very special. We will put into practice many things that we already talked about previously to create a very simple product management system. Basically a CRUD (Create-Read-Update-Delete).

To simulate a real project we will name our project Super Store. Our main module will be called `SuperStore` and the product system will be `SuperStore.Catalog`.

## Graduating from LiveView Playground

So far we used LiveView Playground because our codes were very simple and didn't need so many lines. Even our form in the previous class was less than 70 lines.

From now on we will put a lot of emphasis on organization. We will have multiple modules and repeating each one with small changes here and there could easily become distracting during our lesson.

That being said let's learn this time how to do all of this in a real Mix project. Remember that Mix is Elixir's compilation tool so we are finally working on a real project!

### Ecto with SQLite

For this specific CRUD we will use Ecto (the library that helps us work with databases) alongside SQLite3. We chose SQLite for two very simple reasons:

- **Does not require installing anything extra on your computer**: just install the library and the database can be started.
- **What we will learn here is easily reusable in other databases**: we will focus on fundamental Ecto operations so it doesn't matter if you intend to use PostgreSQL or MySQL in the future the code will be the same.

## Migrating our form to a starter Phoenix project

We will clone a base project that I prepared to ensure that everyone viewing this lesson has the same starting point. Using your terminal:

```
git clone https://github.com/adopt-liveview/first-crud.git
cd first-crud
mix setup
```

With these commands you should have a base Phoenix project. The `mix setup` command not only installs things but also compiles the dependencies for you. Once you have prepared the project and opened your preferred code editor run `mix phx.server` and go to [http://localhost:4000](http://localhost:4000) to see the home page of your Phoenix project.

Don't worry about exploring existing files as we'll cover them as needed.

### Creating the `product.ex` file

Now our project is called `SuperStore` so we need to make this part of the module that we currently call `Product`. As mentioned previously, our product management system will be `SuperStore.Catalog` so we will move `Product` to `SuperStore.Catalog.Product`.

In Phoenix we call modules that encapsulate functions that manage a part of our application Context Modules. The `Catalog` Context is responsible for managing our products. If we had a Context called `Accounts` it would be in charge of managing user accounts. Each Context can have zero or more schemas and generally the naming will be `YourProject.YourContext` and `YourProject.YourContext.YourSchema`.

Inside the `lib/super_store` folder create a file called `catalog.ex` with the following content:

```elixir
defmodule SuperStore.Catalog do
end
```

Then create a folder `lib/super_store/catalog` with a file named `product.ex` with the following content:

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

### Adding our LiveView

Everything related to our web part of our code will be placed inside the `lib/super_store_web` folder. Inside this folder create a folder called `live` and add the file `page_live.ex` with the following content:

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

The only changes here were to the module name and the macros at the top of the module. In this project our LiveViews will always start with `SuperStoreWeb.`. We also changed the `LiveviewPlaygroundWeb` references to `SuperStoreWeb` and added an `alias SuperStore.Catalog.Product`.

%{
title: ~H"How does <code>`alias`</code> actually work?",
description: ~H"""
Normally you need to write the full name of the module to use it as <code>`YourProject.YourContext.YourSchema`</code> but if you put an <code>`alias YourProject.YourContext.YourSchema`</code> you can just use the last module part like <code>`YourSchema.changeset() `</code>. We need to make this `alias` here because our module now has a name with multiple parts, unlike before when it was simply called <code>`Product`</code>.
"""
} %% .callout

As you can see our LiveView Playground is extremely close to what a LiveView of a real project should be.

### Changing the main route for our LiveView

Open the `router.ex` file located in the `lib/super_store_web` folder. You should notice that it has a single route that is not a LiveView set to `get "/", PageController, :home`. Change this to `live "/", PageLive, :home`.

## Project migrated!

From now on you should have the same project as the last lesson working with the only exception that you should see a navigation bar at the top.

If you had issues you can see the final code for this lesson using `git checkout my-first-liveview-project-done` or cloning it in another folder using `git clone https://github.com/adopt-liveview/first-crud .git --branch my-first-liveview-project-done`.

## Recap!

- Now that we are in a real project we will use the `.ex` extension instead of `.exs` (used for scripts).
- Phoenix projects organize parts of their systems into modules called Context that are generally located in `lib/your_app`.
- Context Modules can have zero or more schemas living in `lib/your_app/your_context`.
- Everything related to the web part of your project will live in `lib/your_app_web`.
- All LiveViews will be at `lib/your_app_web/live`.
- Don't forget that to make a LiveView reachable we need to modify our `router.ex`.
