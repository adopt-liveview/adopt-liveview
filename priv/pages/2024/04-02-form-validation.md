%{
title: "Validações",
author: "Lubien",
tags: ~w(getting-started),
section: "Formulários",
description: "Usuários erram e muito",
previous_page_id: "forms",
next_page_id: "simple-forms-with-ecto"
}

---

Aprendemos o básico de formulários mas todos sabemos que boa parte do problema em formulários gira em torno de validar dados! Vamos conhecer como o LiveView trata estes casos agora.

## O binding `phx-change`

Assim como `phx-submit`, o binding `phx-change` funciona em formulários porém ele é disparado toda vez que qualquer dado em um formulário é modificado. Vamos para a prática: crie e execute um arquivo `phx_change.exs`:

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
    {:noreply, socket}
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

Antes de você utilizar sua nova LiveView, vamos entender o que está acontecendo.

### `phx-change` na nossa `render/1`

Adicionamos ao nosso componente `<.form>` o binding `phx-change="validate_product"` portanto o evento `"validate_product"` será disparado sempre que algum input for modificado. Além disso, nada no nosso `render/1` foi modificado.

### O componente `<.input>`

Para que os erros sejam exibidos precisamos definir como eles serão mostrados. Dentro do nosso `Phoenix.Form.FormField` a propriedade `errors` contém a lista de erros em formato string. Uma `div` com um loop `:for={msg <- @field.errors}` é o suficiente. Como estamos usando um componente, ambos os nossos campos automaticamente ganham validação de erros!

### O `handle_event("validate_product", %{"product" => product_params}, socket)`

Nosso `handle_event/3` segue o mesmo formato do evento de `phx-submit`. Para adicionarmos validação de erros basta criarmos uma Keyword list no formato `[name: "cannot be empty", description: "cannot be empty"]`. Cada campo pode ter mais de um erro de validação. Vejamos como foi feita a validação de que o `name` contém algo:

```elixir
errors = []

errors =
  if product_params["name"] == "" do
    Keyword.put(errors, :name, "cannot be empty")
  else
    errors
  end
```

Nossa keyword list de erros começa vazia. Se o valor de `product_params["name"]` usamos `Keyword.put/3` para adicionar o error. O mesmo se repete para `description`.

No final da função nós recriamos o `form` desta vez passando a lista de erros para o `to_form/2`: `form = to_form(product_params, as: :product, errors: errors)`.

### Mão na massa

Agora abra a LiveView no seu navegador. Escreva qualquer coisa no campo de nome e verifique que imediatamente o campo de descrição diz que não pode ser vazio. No momento não estamos verificando se o campo que foi modificado é o campo sendo validado!

Além disso, nossa LiveView tem outro problema. Saia do campo de nome e escreva qualquer coisa no campo de descrição. O nome sumiu?! O que está acontecendo aqui? Já vamos entender isso!

### Como a validação funciona

Quando você reatribui o assign `form` no seu evento de `"validate_product`" o LiveVIew entende que todos os componentes que dependem dele precisam de uma atualização. Além disso nós atualizamos o valor atual dos campos do form porém não ensinamos o componente a usar esse valor atualizado.

```elixir
def input(assigns) do
  ~H"""
  <input type="text" id={@field.id} name={@field.name} value={@field.value} {@rest} />
  <div :for={msg <- @field.errors} class="text-red-500 py-2"><%= msg %></div>
  """
end
```

A essa altura já conhecemos o que temos que conhecer deste componente. Vamos usar o componente de `<.input>` real criado pelo Phoenix! Crie e execute `form_with_core_components.exs`:

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

Trocamos nossa própria definição de `<.input>` pela definição gerada automaticamente. Espero que com o conteúdo até agora você tenha entendido o poder por trás desse componente, ainda que você nunca edite ele.

Você também pode estar se perguntando: por que o componente `<.form>` já vem com o Phoenix e o componente `<.input>` é gerado no CoreComponentes? A resposta é mais simples do que parece. Enquanto `<.form>` trabalha mais com a gerência de certas funcionalidades do formulário e não tem estilos os componentes do CoreComponents sempre tem estilo portanto faz sentido eles virem com um estilo padrão e você pode editar conforme sua necessidade, está tudo em suas mãos.

## Resumindo!

- O `phx-change` é um binding que executa toda vez que o formulário muda. Ele dispara um `handle_event/3` similar ao de `phx-submit`.
- Você pode usar o `to_form/3` para adicionar erros de validação no seu formulário passando ele nas opções.
- É de responsabilidade do componente `<.input>` de renderizar os erros e de renderizar o valor atual do campo do form caso ele seja modificado no servidor.
- Felizmente você não precisa criar o component `<.input>`, iremos utilizar o CoreComponents a partir em diante, o que seria o normal em projetos Phoenix reais.
- Lembrando: nas aulas iremos fazer `import SeuProjetoWeb.CoreComponents` porém em projetos reais Phoenix isso vem automaticamente quando você faz `use SeuProjetoWeb, :live_view`.
