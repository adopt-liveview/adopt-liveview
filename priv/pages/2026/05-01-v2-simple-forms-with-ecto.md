%{
title: "Simplificando tudo com Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "Formulários",
description: "Agora as coisas ficam sérias",
previous_page_id: "v2-form-validation",
next_page_id: "v2-my-first-liveview-project"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Caso queira pular a aula anterior e começar direto nesta, você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch form-validation-done`</code>.
"""
} %% .callout

Agora que você entende não só como formulários funcionam por trás dos panos como também como raciocinar pelo fluxo de formulários e eventos, vamos simplificar tudo!

## Introduzindo Ecto

Ecto é uma biblioteca em Elixir para gerenciar acesso ao banco de dados. Com o tempo a comunidade notou que o padrão de validação do Ecto era bastante poderoso e abstrações para validar dados sem sequer considerar o banco de dados foram surgindo. Hoje usaremos uma delas.

Vale mencionar que em projetos Phoenix novos o Ecto vem por padrão, então entender Ecto não só vai nos ajudar hoje a refatorar nosso formulário em um código mais organizado como também lhe ensinará os fundamentos do Ecto para que você possa usar esta biblioteca em projetos futuros.

## Refatorando nosso formulário anterior para Ecto

Vamos direto ao ponto. Crie um módulo `Product` em `lib/myapp/products/product.ex`:

```elixir
defmodule Myapp.Products.Product do
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

Atualize também sua `PageLive`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  alias Myapp.Products.Product

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
    <div>
      <.form
        for={@form}
        phx-change="validate_product"
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto p-24"
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

### Entendendo um Ecto Schema

```elixir
defmodule Myapp.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  # ...
end
```

A magia começa aqui. Definimos um módulo chamado `Myapp.Products.Product` para representar o dado no nosso formulário. Note que este módulo não está sob `MyappWeb`, mas sim em `Myapp.Products.Product`. Projetos Phoenix gostam de separar a lógica de negócio da lógica web. Vamos entender em breve por que colocamos `Product` aninhado em `Products`; por enquanto você só precisa saber que isso é uma convenção.

A primeira coisa que fazemos dentro do nosso módulo é `use Ecto.Schema` para que ele receba a DSL (Linguagem de Domínio Específico) que nos permite usar macros como `embedded_schema` e `field` para definir o formato do nosso modelo Product. Pense nessa DSL como uma forma simples de definir um Struct em Elixir.

Também importamos [`Ecto.Changeset`](https://hexdocs.pm/ecto/Ecto.Changeset.html). Changesets são estruturas de dados que contêm informações sobre modificações em algo. Neste caso, nosso changeset conterá dados sobre modificações, erros e validações do nosso struct Product. Pense em changesets como uma etapa de validação.

### Entendendo um `embedded_schema`

```elixir
defmodule Myapp.Products.Product do
  # ...

  embedded_schema do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  # ...
end
```

Em termos de Ecto, Embedded Schemas são dados que vivem apenas em memória, sem serem salvos em um banco de dados. Usando a sintaxe acima e definindo os campos do struct com [`field/3`](https://hexdocs.pm/ecto/Ecto.Schema.html#field/3) conseguimos facilmente dizer quais dados pertencem ao struct Product. Essencialmente, o que este trecho de código faz é dizer que um Struct Product começa como `%Product{name: "", description: ""}` com sua DSL.

### A função `changeset/2`

```elixir
defmodule Myapp.Products.Product do
  # ...

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
```

É praticamente inevitável você ver um Ecto.Schema sem pelo menos uma função `changeset/2`. Estas funções estão totalmente sob seu controle e servem para definir como validamos os dados. Nas aulas anteriores, a validação acontecia dentro da LiveView, mas isso deixou nosso código bagunçado e difícil de reutilizar. Em projetos Phoenix, as validações são feitas quase sempre no nível do Ecto.Schema, dentro das funções `changeset/2`.

Recebemos dois argumentos: o produto e os parâmetros opcionais (note que se nada for passado usamos o padrão `%{}`). Com esses dois valores em mente, usamos pipes para transformar o valor da seguinte maneira:

- Temos um struct de `%Product{name: "", description: ""}` (já que nosso formulário começa com um `%Product{}` vazio).
- Usando a função [`cast/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) transformamos o `%Product{}` em um `%Ecto.Changeset{}` recebendo os `params` e aceitando apenas os `params` que forem `:name` ou `:description`.
- Usando a função [`validate_required/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3) recebemos o `%Ecto.Changeset{}` com os dados e validamos que `:name` e `:description` estão presentes.

No final da função teremos um changeset validado. O módulo `Ecto.Changeset` contém diversas funções úteis de validação e você também pode criar validações customizadas. Por enquanto, seguiremos apenas com `validate_required/3`.

## Usando changesets em nossa LiveView

```elixir
defmodule MyappWeb.PageLive do
  # ...

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

  # ...
end
```

Agora que possuímos changesets, a única refatoração necessária na nossa LiveView aconteceu nos callbacks. Vamos analisá-los passo a passo.

#### O novo `mount/3`

```elixir
def mount(_params, _session, socket) do
  form =
    Product.changeset(%Product{})
    |> to_form()

  {:ok, assign(socket, form: form)}
end
```

Em nosso `mount/3` usamos a função `changeset/2` do módulo sem passar o segundo argumento, pois sabemos que não há nenhum dado modificado. Passamos o resultado imediatamente para `to_form/2`.

Você pode estar se perguntando: não precisamos de um `as: :product`? Os formulários Phoenix estão preparados para converter automaticamente os nomes do `Ecto.Schema` de modo que um schema `Product` implicitamente significa `as: :product` no `to_form/2`. Vale lembrar que desde o início mencionamos que este era o padrão do Phoenix e você pode ver como o framework leva isso a sério a ponto de simplificar isso para você.

#### O novo `handle_event/3`

```elixir
def handle_event("validate_product", %{"product" => product_params}, socket) do
  form =
    Product.changeset(%Product{}, product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

Bem similar ao `mount/3`, nossa função também usa changeset para criar o `Phoenix.HTML.Form`. Tivemos duas modificações:

- Passamos o `product_params` ao changeset para que os novos dados sejam validados.
- Usamos `Map.put/3` para definir no changeset que estamos em modo de validação. Isso é necessário para que nossa LiveView saiba que o changeset foi validado e os erros podem ser renderizados.

## Resumindo!

- Ecto é uma biblioteca poderosa para gerenciar acesso ao banco de dados.
- Projetos Phoenix usam Ecto por padrão não só para trabalhar com banco de dados como também para validar dados.
- Podemos usar `Ecto.Schema` para facilmente criar um `Struct`. Como não estamos trabalhando com banco de dados (ainda), usamos `embedded_schema` e `fields` para poder criar dados apenas em memória.
- Podemos usar `Ecto.Changeset` para facilmente validar dados de usuários que vão para o seu struct.
- Geralmente um `Ecto.Schema` tem uma ou mais funções `changeset/2` para definir como validar seus dados, e são usadas como `Product.changeset(%Product{}, params)`.
- Nossas LiveViews ficam mais enxutas quando separamos a lógica de validação da nossa lógica de UI.