%{
title: "Simplificando tudo com Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "Formulários",
description: "Agora as coisas ficam sérias",
previous_page_id: "form-validation",
next_page_id: "my-first-liveview-project"
}

---

Agora que você entende não só como formulários funcionam por trás dos panos como também como raciocinar pelo fluxo de formulários usando eventos vamos simplificar tudo!

## Introduzindo Ecto

Ecto é uma biblioteca em Elixir para gerenciar acesso ao banco de dados. Com o tempo a comunidade notou que o padrão do Ecto de validação era bastante poderoso e abstrações para validar dados sem sequer considerar o banco de dados foram surgindo. Hoje usaremos uma delas.

Vale mencionar que em projetos novos Phoenix o Ecto vem por padrão então entender Ecto não só vai nos ajudar hoje a refatorar nosso formulário em um código mais organizado como também lhe ensinará um dos fundamentos de Ecto para que você consiga utilizar esta biblioteca no futuro em seus projetos.

## Refatorando nosso formulário anterior para Ecto

Vamos direto ao ponto. Crie e execute um arquivo chamado `ecto_form.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.8"},
  {:phoenix_ecto, "~> 4.5"},
  {:ecto, "~> 3.11"}
])

defmodule Product do
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

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import LiveviewPlaygroundWeb.CoreComponents

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

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

### Instalando as bibliotecas necessárias

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.8"},
  {:phoenix_ecto, "~> 4.5"},
  {:ecto, "~> 3.11"}
])
```

No nosso `Mix.Install/2` nós adicionamos não só o Ecto em si como também a biblioteca `phoenix_ecto` que serve para unir ambas. Em projetos reais isto já estaria instalado, não se preocupe.

### Entendendo um Schema Ecto

```elixir
defmodule Product do
  use Ecto.Schema
  import Ecto.Changeset

  # ...
end
```

A magia começa aqui. Definimos um módulo chamado `Product` para representar o dado no nosso formulário. A primeira coisa que fazemos é `use Ecto.Schema` para que nosso módulo receba a DSL (Linguagem de Domínio Específico) que nos deixa utilizar macros como `embedded_schema` e `field` para definirmos o formato do nosso Product. Pense nesta DSL como um jeito simples de definir um Struct em Elixir.

Além disso importanmos [`Ecto.Changeset`](https://hexdocs.pm/ecto/Ecto.Changeset.html). Changeset é uma estrutura de dados que contém dados sobre modificações em algo. Neste caso, nosso Changeset conterá dados sobre modificações, erros e validações do nosso struct Product. Pense em changesets como uma fase de validaçào.

### Entendendo um `embedded_schema`

```elixir
defmodule Product do
  # ...

  embedded_schema do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  # ...
end
```

Em termos de Ecto, Embedded Schemas são dados que vivem apenas em memória, sem serem salvos em um banco de dados. Usando a sintaxe acima e definindo os campos do struct com [`field/3`](https://hexdocs.pm/ecto/Ecto.Schema.html#field/3) conseguimos facilmente dizer quais dados pertencem ao struct Product. Essencialmente o que esse trecho de código faz é dizer que um Struct Product começa como `%Product{name: "", description: ""}` porém com um código bem fácil de entender.

### A função `changeset/2`

```elixir
defmodule Product do
  # ...

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
```

É praticamente inevitável você ver um Ecto.Schema sem uma função `changeset/2` ou até mesmo mais de uma. Esta função é do seu controle total e ela serve para definir como validamos seus dados. Na aula anterior a validação acontecia dentro da LiveView porém isso deixou nosso código bagunçado e difícil de ser compartilhado. Em projetos Phoenix as validações a nível de um Ecto.Schema são feitas quase sempre nesta função.

Nela recebemos dois argumentos: o produto e os parâmatros novos opcionalmente (veja que se nada for passado usamos o padrão `%{}`). Tendo estes dois valores em mente usamos pipes para transformar este valor da seguinte maneira:

- Nós temos um struct de `%Product{name: "", description: ""}` (no caso do nosso formulário ele começa vazio).
- Usando a função [`cast/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) nós transformamos o `%Product{}` em um `%Ecto.Changeset{}` recebendo os `params` e aceitando apenas os `params` que forem `:name` ou `:description`.
- Usando a função [`validate_required/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3) nós recebemos o `%Ecto.Changeset{}` com os dados e validamos que `:name` e `:description` estão presentes.

No final da função teremos um changeset validado. O módulo `Ecto.Changeset` contém diversas funções úteis de validação e você pode também criar validações customizadas. No momento iremos seguir apenas com o `validate_required/3`.

## Usando changesets em nossa LiveView

```elixir
defmodule PageLive do
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

Agora que possuímos changesets a única refatoração necessária para nossa LiveView aconteceu nos callbacks. Vamos analisar eles passo a passo.

#### O novo `mount/3`

```elixir
def mount(_params, _session, socket) do
  form =
    Product.changeset(%Product{})
    |> to_form()

  {:ok, assign(socket, form: form)}
end
```

Em nosso `mount/3` nós usamos a função `changeset/2` do módulo sem passar o segundo argumento pois sabemos que não há nenhum dado modificado. Passamos o resultado imediatamente para o `to_form/2`.

Você pode estar se perguntando: não precisamos de um `as: :product`? Os formulários Phoenix estão preparados para converter automaticamente o nome do `Ecto.Schema` de modo que um schema `Product` implicitamente singifica `as: :product` no `to_form/2`. Vale lembrar que desde o início mencionamos que esta era o padrão do Phoenix e você consegue ver como o framework leva isso a sério a ponto de simplificar isso para você.

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

- Passamos ao changeset o `product_params` para que os novos dados sejam validados.
- Usamos `Map.put/3` para definir no changeset que estamos em modo de validação. Isto é necessário para que nossa LiveView saiba que o changeset foi validado e os erros podem ser renderizados.

## Resumindo!

- Ecto é uma biblioteca para gerenciar acesso ao banco de dados poderosa.
- Projetos Phoenix usam Ecto por padrão não só para trabalhar com banco de dados como também validar dados.
- Podemos usar `Ecto.Schema` para facilmente criarmos um `Struct`. Como não estamos trabalhando com banco de dados (ainda) usamos o `embedded_schema` e `fields` para poder criar um dado apenas em memória.
- Podemos usar `Ecto.Changeset` para facilmente validar dados de usuários indo para seu struct.
- Geralmente um `Ecto.Schema` tem uma ou mais funções `changeset/2` para definir como validar seus dados e são usadas como `Product.changeset(%Product{}, params)`.
- Nossas LiveViews ficam mais enxutas quando separamos a lógica de validar dados da nossa lógica de renderizar e receber eventos de formulários.
