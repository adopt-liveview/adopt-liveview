%{
title: "Validations",
author: "Lubien",
tags: ~w(getting-started),
section: "Forms",
description: "Users make a lot of mistakes",
previous_page_id: "forms",
next_page_id: "simple-forms-with-ecto"
}

---

We learned the basics of forms but we all know that a large part of the problem forms solve is related to validating data! Let's find out how LiveView handles these cases now.

## The `phx-change` binding

Just like `phx-submit`, the `phx-change` binding works on forms but it is triggered every time any data in a form is modified. Let's get to practice: create and run a `phx_change.exs` file:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type)

  def input(assigns) do
    ~H"""
    <input type="text" id={@field.id} name={@field.name} {@rest} />
    <div :for={msg <- @field.errors} class="text-red-500 py-2"><%= msg %></div>
    """
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  @initial_state %{
    "name" => "",
    "description" => ""
  }

  def mount(_params, _session, socket) do
    form = to_form(@initial_state, as: :product)
    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate_product", %{"product" => product_params}, socket) do
    errors = []

    errors =
      if product_params["name"] == "" do
        Keyword.put(errors, :name, "cannot be empty")
      else
        errors
      end

    errors =
      if product_params["description"] == "" do
        Keyword.put(errors, :description, "cannot be empty")
      else
        errors
      end

    form = to_form(product_params, as: :product, errors: errors)
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

        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

Before you use your new LiveView, let's understand what's going on.

### `phx-change` in our `render/1`

We added the `phx-change="validate_product"` binding to our `<.form>` component so the `"validate_product"` event will be triggered whenever any input is modified. Nothing else in our `render/1` has been modified.

### The `<.input>` component

For errors to be displayed we need to define how they show appear in our code. Inside our `Phoenix.Form.FormField` the `errors` property contains a list of errors in string format. A `div` with a `:for={msg <- @field.errors}` loop is enough. Since we are using a component both of our fields automatically receive error validation!

### The `handle_event("validate_product", %{"product" => product_params}, socket)`

Our `handle_event/3` follows the same format as the `phx-submit` event. To add error validation simply create a Keyword list in the format `[name: "cannot be empty", description: "cannot be empty"]`. Each field can have more than one validation error. Let's see how the validation that `name` contains something was done:

```elixir
errors = []

errors =
  if product_params["name"] == "" do
    Keyword.put(errors, :name, "cannot be empty")
  else
    errors
  end
```

Our keyword list of errors starts empty. If the value of `product_params["name"]` is `""` we use `Keyword.put/3` to add the error. The same is repeated for `description`.

At the end of the function we recreate the `form` this time passing the list of errors to `to_form/2`: `form = to_form(product_params, as: :product, errors: errors)`.

### Hands-on

Now open LiveView in your browser. Write anything in the name field and immediately see that the description field says it cannot be empty. We are currently not checking whether the modified field was the same field being validated!

Also our LiveView has another issue. Leave the name field and write anything in the description field. The name disappeared?! What's going on here? Let's understand this now!

### How validation works

When you reassign the assign `form` in your `"validate_product`" event LiveView understands that all components that depend on it need an update. Furthermore, we updated the current value of the form fields but we do not teach the component to use this updated value.

```elixir
def input(assigns) do
  ~H"""
  <input type="text" id={@field.id} name={@field.name} value={@field.value} {@rest} />
  <div :for={msg <- @field.errors} class="text-red-500 py-2"><%= msg %></div>
  """
end
```

At this point we already know what we need to know about this component. Let's use the real `<.input>` component created by Phoenix! Create and run `form_with_core_components.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.7"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import LiveviewPlaygroundWeb.CoreComponents

  @initial_state %{
    "name" => "",
    "description" => ""
  }

  def mount(_params, _session, socket) do
    form = to_form(@initial_state, as: :product)
    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate_product", %{"product" => product_params}, socket) do
    errors = []

    errors =
      if product_params["name"] == "" do
        Keyword.put(errors, :name, "cannot be empty")
      else
        errors
      end

    errors =
      if product_params["description"] == "" do
        Keyword.put(errors, :description, "cannot be empty")
      else
        errors
      end

    form = to_form(product_params, as: :product, errors: errors)
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

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

We've swaped our own definition of `<.input>` for the automatically generated definition from `LiveviewPlaygroundWeb.CoreComponents`. I hope that with the content so far you have understood the power behind this component even if you never have to edit it.

You may also be wondering: why does the `<.form>` component already comes with Phoenix and the `<.input>` component is generated in CoreComponentes? The answer is simpler than it seems. While `<.form>` works more with managing certain form features and does not have styles, CoreComponents components always have styles so it makes sense for them to come with a default style and you can edit them as you please, it's all in your hands.

## Recap!

- `phx-change` is a binding that runs every time the form changes. It triggers a `handle_event/3` similar to that of `phx-submit`.
- You can use `to_form/3` to add validation errors to your form by passing it in the options.
- It is the responsibility of the `<.input>` component to render errors and to render the current value of the form field if it is modified at the server.
- Fortunately you don't need to create the `<.input>` component we will use CoreComponents from now on, which would be normal in real Phoenix projects.
- Remember: in lessons we will do `import SeuProjetoWeb.CoreComponents` however in real Phoenix projects this comes automatically when you do `use YourProjectWeb, :live_view`.
