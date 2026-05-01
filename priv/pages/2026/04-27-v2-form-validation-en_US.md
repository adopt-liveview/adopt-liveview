%{
title: "Validations",
author: "Lubien",
tags: ~w(getting-started),
section: "Forms",
description: "Users make a lot of mistakes",
previous_page_id: "v2-forms",
next_page_id: "v2-simple-forms-with-ecto"
}

---

%{
title: "This guide is a direct continuation of the previous guide",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch forms-done`</code>.
"""
} %% .callout

We learned the basics of forms but we all know that a large part of the problem forms solve is related to validating data! Let's find out how LiveView handles these cases now.

## The `phx-change` binding

Just like `phx-submit`, the `phx-change` binding works on forms but it is triggered every time any data in a form is modified. Let's get to practice. Start by updating `my_core_components.ex` to add error display to `my_input`:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :title do
    attr :class, :string
  end

  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 :for={title_slot <- @title} class={["text-4xl font-bold", Map.get(title_slot, :class)]}>
          {render_slot(title_slot)}
        </h1>
        <p class="mt-4 text-lg">{render_slot(@subtitle)}</p>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button type="submit" class="text-blue-500">Save data</.my_button>
      <.my_button type="submit" color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  attr :rest, :global, default: %{type: "button"}, include: ~w(type style)
  slot :inner_block, required: true

  def my_button(assigns) do
    ~H"""
    <button
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :terms, :list, required: true
  slot :dt, required: true
  slot :dd, required: true

  def dl(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold">{render_slot(@dt, item)}</dt>
          <dd class="text-gray-600">{render_slot(@dd, item)}</dd>
        </div>
      </div>
    </dl>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type)

  def my_input(assigns) do
    ~H"""
    <input type="text" id={@field.id} name={@field.name} value={@field.value} {@rest} />
    <div :for={msg <- @field.errors} class="text-red-500 py-2">{msg}</div>
    """
  end
end
```

Now update your `page_live.ex` to add `phx-change` validation:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
        Keyword.put(errors, :name, "can't be blank")
      else
        errors
      end

    errors =
      if product_params["description"] == "" do
        Keyword.put(errors, :description, "can't be blank")
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
        class="flex flex-col max-w-96 mx-auto p-24"
      >
        <h1 class="text-blue-500">Creating a product</h1>
        <.my_input field={@form[:name]} placeholder="Name" />
        <.my_input field={@form[:description]} placeholder="Description" />

        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end
end
```

Before you use your new LiveView, let's understand what's going on.

### `phx-change` in our `render/1`

We added the `phx-change="validate_product"` binding to our `<.form>` component so the `"validate_product"` event will be triggered whenever any input is modified. Nothing else in our `render/1` has been modified.

### The `<.my_input>` component

For errors to be displayed we need to define how they should appear in our code. Inside our `Phoenix.Form.FormField` the `errors` property contains a list of errors in string format. A `div` with a `:for={msg <- @field.errors}` loop is enough. Since we are using a component both of our fields automatically receive error validation!

### The `handle_event("validate_product", %{"product" => product_params}, socket)`

Our `handle_event/3` follows the same format as the `phx-submit` event. To add error validation simply create a Keyword list in the format `[name: "can't be blank", description: "can't be blank"]`. Each field can have more than one validation error. Let's see how the validation that `name` contains something was done:

```elixir
errors = []

errors =
  if product_params["name"] == "" do
    Keyword.put(errors, :name, "can't be blank")
  else
    errors
  end
```

Our keyword list of errors starts empty. If the value of `product_params["name"]` is `""` we use `Keyword.put/3` to add the error. The same is repeated for `description`.

At the end of the function we recreate the `form` this time passing the list of errors to `to_form/2`: `form = to_form(product_params, as: :product, errors: errors)`.

### Hands-on

Now open LiveView in your browser. Write anything in the name field and immediately see that the description field says it can't be blank. We are currently not checking whether the modified field was the same field being validated!

Also our LiveView has another issue. Leave the name field and write anything in the description field. The name disappeared?! What's going on here? Let's understand this now!

### How validation works

When you reassign the assign `form` in your `"validate_product"` event LiveView understands that all components that depend on it need an update. Furthermore, we updated the current value of the form fields but we do not teach the component to use this updated value.

```elixir
def my_input(assigns) do
  ~H"""
  <input type="text" id={@field.id} name={@field.name} value={@field.value} value={@field.value} {@rest} />
  <div :for={msg <- @field.errors} class="text-red-500 py-2">{msg}</div>
  """
end
```

## Recap!

- `phx-change` is a binding that runs every time the form changes. It triggers a `handle_event/3` similar to that of `phx-submit`.
- You can use `to_form/3` to add validation errors to your form by passing it in the options.
- It is the responsibility of the `<.input>` component to render errors and to render the current value of the form field if it is modified at the server.
- Fortunately you don't need to create the `<.input>` component — `CoreComponents` is already generated for you and available in every LiveView via `use MyappWeb, :live_view`.
