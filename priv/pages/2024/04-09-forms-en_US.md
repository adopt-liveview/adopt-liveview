%{
title: "Form component",
author: "Lubien",
tags: ~w(getting-started),
section: "Forms",
description: "Understanding the basics of forms in Phoenix",
previous_page_id: "lists-with-slots",
next_page_id: "form-validation"
}

---

Forms are important in many Phoenix applications. They are also one of the biggest points of confusion for people starting on LiveView. During the next classes we will learn about forms in a bottom-up way. That means that we will start by implementing some things so we understand what Phoenix is solving with its built-in components.

If you think it's too complicated at first and the framework is too hard don't worry because in the end you'll see that all these things are solved with built-in components because Phoenix is a batteries-included framework.

## The simplest form of all

When you learn the basics of HTML I bet at some point you had to build a form that had some inputs and could be submitted. Let's start with that goal. Let's create a product creation form. Create and run `first_form.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <form phx-submit="create_product" class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24">
        <h1>Creating a product</h1>
        <input type="text" name="product[name]" placeholder="Name" />
        <input type="text" name="product[description]" placeholder="Description" />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

### Tailwind plugin `forms`

If you look at our `scripts` area in `LiveViewPlayground.start` you should notice that we added `?plugins=forms` to the CDN URL. This plugin just adds some default styles to HTML forms. In real Phoenix projects with Tailwind it is already pre-installed so you don't need to worry. Moving forward we will be using this plugin a lot.

### HEEx and the `phx-submit` binding

Look at our HEEx code. Our form and input tags are just what you've seen when you studied HTML without any modifications. The new thing introduced here is the [`phx-submit`](https://hexdocs.pm/phoenix_live_view/form-bindings.html#form-events) binding. Just like `phx-click` this binding maps the submission of a form to a `handle_event/3` in our LiveView.

### Mapping input attributes `name` to maps

Another point that you may have found strange is that the `name` attributes in our HEEx code use the `product[name]` format. Although not mandatory this has been the Phoenix convention before LiveView even existed and the recommendation would be that you continue with it. Don't worry too much, we'll see later that this is all done automatically.

When we have a HTML form with inputs `product[name]` and `product[description]` this generates an equivalent map in the format `%{"product" => %{"name" => "", "description" => ""}}`. This makes it easier for us to retrieve this value in our `handle_event/3`. I believe it is always good to highlight this topic as it is something that I generally don't see explained in framework documentation.

### Receiving the form with `handle_event/3`

In our HEEx code we added to the form `phx-submit="create_product"` so we must handle the event `"create_product"` like `handle_event("create_product", %{"product" => product_params}, socket)`. Note that the `params` were matched using the format explained previously because Phoenix prefers to follow this convention.

Our `handle_event/3` doesn't do anything important it just generates a message in your terminal and nothing more. Congratulations, you've created your first form in Phoenix LiveView!

## Getting to know the form component

We currently do not perform any type of validation with our form. To help us Phoenix has a data structure called [`Phoenix.HTML.Form`
](https://hexdocs.pm/phoenix_html/3.3.0/Phoenix.HTML.Form.html) that simplifies form management in addition to providing us with a validation system.

### New data structures

When we convert a map in the format `%{name: "", description: ""}` to `Phoenix.HTML.Form` a variable in the format below is created:

```elixir
%Phoenix.HTML.Form{
  source: %{"description" => "", "name" => ""},
  impl: Phoenix.HTML.FormData.Map,
  id: "product",
  name: "product",
  data: %{},
  action: nil,
  hidden: [],
  params: %{"description" => "", "name" => ""},
  errors: [],
  options: [],
  index: nil
}
```

Assuming that your variable is `form`, you can access the fields in a structure called [`Phoenix.HTML.FormField`](https://hexdocs.pm/phoenix_html/3.3.0/Phoenix.HTML.FormField.html) that have the following format:

```elixir
%Phoenix.HTML.FormField{
  id: "product_name",
  name: "product[name]",
  errors: [],
  field: :name,
  form: %Phoenix.HTML.Form{...},
  value: ""
}
```

Let's apply them to our code!

### The `<.form>` component

Phoenix projects include a new component called [`<.form>`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1). The objective of this component is to generate basic HTML for forms in addition to offering advantages such as protection against [CSRF](https://owasp.org/www-community/attacks/csrf) (when necessary), extra error validation and method spoofing. The preference will always be to use this component instead of the `<form>` tag.

Let's try. Create and run a file called `first_form_component.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  @initial_state %{
    "name" => "",
    "description" => ""
  }

  def mount(_params, _session, socket) do
    form = to_form(@initial_state, as: :product)
    {:ok, assign(socket, form: form)}
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
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <h1>Creating a product</h1>
        <input type="text" id={@form[:name].id} name={@form[:name].name} placeholder="Name" />

        <input
          type="text"
          id={@form[:description].id}
          name={@form[:description].name}
          placeholder="Description"
        />

        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

### Using `to_form/2` to generate forms

At the top of our module we created a [module attribute](https://hexdocs.pm/elixir/module-attributes.html) called `@initial_state` to help making our code more readable and make this state easily accessible in the future. Additionally we introduced a `mount/3` that creates an assign called `form` with the value of the function [`to_form/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#to_form/2) passing our `@initial_state` and as an option `as: :product`. The reason we put this option is so that our form fields follow the `product[name]` format.

## Rendering our `<.form>`

Looking at the HEEx code we can notice that the first difference is that we stopped using the HTML tag `<form>` and added the component `<.form>` passing the assign `for={@form}`. That's all this component needs!

Further below we modified our `input` tags to receive form fields in the format `@form[:name]`. Each of these represents a `Phoenix.HTML.FormField` and we use the field's `id` and `name` properties in the attributes with the same names.

Now you must be thinking: "my code has become more verbose, what's the advantage?". The motivation is simpler than it seems: we can componentize our `input` tags!

## The `.input` component

Because you have structured your data in `Phoenix.HTML.FormField` we can now easily build a component that reads this data and automatically adds necessary properties like `name` and `id`. Create and run a file called `first_form_component.exs`:

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

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
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

### Implementing `<.input>`

With barely any code we were able to create a component `<.input field={@form[:name]}>` that automatically uses the necessary properties. Additionally we create an `attr` that sets the `type` to `"text"` by default and a global `attr` to receive any other necessary properties. If in the future we want to modify the styles of all inputs in our system we have a centralized place to do this.

%{
title: "Will I have to create my input components in every Phoenix project I do?",
description: ~H"""
I came here especially to give you a spoiler that the answer is no, Phoenix already generates this component for you in an infinitely better way than what I can teach you. Just remember that these lesson are bottom-up, we are teaching you how to do them so that you understand how they work.
"""
} %% .callout

## Recap!

- LiveView forms use the `phx-submit` binding to trigger a `handle_event/3` with the respective event name.
- Phoenix prefers to use the format `parent_name[child_name]` in its `input` to make it easier to manage which form contains which data. This generates maps like `%{"parent_name" => %{"child_name" => ""}}` in `phx-submit` events.
- The preference for creating forms will always be to use the `<.form>` component instead of the `<form>` tag.
- To prepare data in the `Phoenix.HTML.Form` format, the `to_form/2` function converts the data `to_form(%{name: ""}, as: :product)` into the appropriate format.
- We prefer to add `as: :name_of_parent` as an option to `to_form/2` to follow the Phoenix convention of `name` attributes of our `input` tags.
- Using forms in the `Phoenix.HTML.Form` format makes it easier to create components for inputs.
