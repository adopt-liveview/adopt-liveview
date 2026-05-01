%{
title: "Validações",
author: "Lubien",
tags: ~w(getting-started),
section: "Formulários",
description: "Usuários cometem muitos erros",
previous_page_id: "v2-forms",
next_page_id: "v2-simple-forms-with-ecto"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Caso queira pular a aula anterior e começar direto nesta, você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch forms-done`</code>.
"""
} %% .callout

Aprendemos o básico de formulários, mas todos sabemos que grande parte do problema que eles resolvem está relacionada à validação de dados! Vamos descobrir agora como o LiveView lida com esses casos.

## O binding `phx-change`

Assim como o `phx-submit`, o binding `phx-change` funciona em formulários, mas é disparado toda vez que qualquer dado do formulário é modificado. Vamos colocar isso em prática. Comece atualizando o `my_core_components.ex` para adicionar a exibição de erros ao `my_input`:

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

Agora atualize seu `page_live.ex` para adicionar a validação com `phx-change`:

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

Antes de usar sua nova LiveView, vamos entender o que está acontecendo.

### `phx-change` no nosso `render/1`

Adicionamos o binding `phx-change="validate_product"` ao nosso componente `<.form>` para que o evento `"validate_product"` seja disparado sempre que qualquer input for modificado. Nada mais no nosso `render/1` foi alterado.

### O componente `<.my_input>`

Para que os erros sejam exibidos, precisamos definir como eles devem aparecer no nosso código. Dentro do `Phoenix.Form.FormField`, a propriedade `errors` contém uma lista de erros em formato de string. Um `div` com um loop `:for={msg <- @field.errors}` é suficiente. Como estamos usando um componente, ambos os campos recebem a validação de erros automaticamente!

### O `handle_event("validate_product", %{"product" => product_params}, socket)`

Nosso `handle_event/3` segue o mesmo formato que o evento `phx-submit`. Para adicionar validação de erros, basta criar uma Keyword list no formato `[name: "can't be blank", description: "can't be blank"]`. Cada campo pode ter mais de um erro de validação. Veja como foi feita a validação de que `name` contém algum valor:

```elixir
errors = []

errors =
  if product_params["name"] == "" do
    Keyword.put(errors, :name, "can't be blank")
  else
    errors
  end
```

Nossa keyword list de erros começa vazia. Se o valor de `product_params["name"]` for `""`, usamos `Keyword.put/3` para adicionar o erro. O mesmo se repete para `description`.

No final da função recriamos o `form`, desta vez passando a lista de erros para `to_form/2`: `form = to_form(product_params, as: :product, errors: errors)`.

### Na prática

Abra a LiveView no seu navegador. Digite algo no campo nome e veja imediatamente que o campo descrição diz que não pode ficar em branco. No momento não estamos verificando se o campo modificado é o mesmo campo sendo validado!

Além disso, nossa LiveView tem outro problema. Deixe o campo nome e escreva algo no campo descrição. O nome desapareceu?! O que está acontecendo? Vamos entender isso agora!

### Como a validação funciona

Quando você reatribui o assign `form` no seu evento `"validate_product"`, o LiveView entende que todos os componentes que dependem dele precisam de uma atualização. Além disso, atualizamos o valor atual dos campos do formulário, mas não ensinamos o componente a usar esse valor atualizado.

```elixir
def my_input(assigns) do
  ~H"""
  <input type="text" id={@field.id} name={@field.name} value={@field.value} value={@field.value} {@rest} />
  <div :for={msg <- @field.errors} class="text-red-500 py-2">{msg}</div>
  """
end
```

## Resumindo!

- `phx-change` é um binding que é executado toda vez que o formulário muda. Ele dispara um `handle_event/3` similar ao do `phx-submit`.
- Você pode usar `to_form/3` para adicionar erros de validação ao seu formulário passando-os nas opções.
- É responsabilidade do componente `<.input>` renderizar os erros e o valor atual do campo do formulário caso ele seja modificado no servidor.
- Felizmente você não precisa criar o componente `<.input>` — o `CoreComponents` já é gerado para você e está disponível em toda LiveView através do `use MyappWeb, :live_view`.