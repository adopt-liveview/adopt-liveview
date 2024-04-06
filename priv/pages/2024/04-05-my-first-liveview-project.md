%{
title: "Meu primeiro projeto LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Finalmente!",
previous_page_id: "simple-forms-with-ecto",
next_page_id: "saving-data"
}

---

Esta seção do curso vai ser bem especial. Iremos por na prática muitas coisas que já falamos anteriormente para fazer um sistema bem simples de gerência de produtos, um famoso CRUD (Create-Read-Update-Delete).

Para simular um projeto real iremos nomear nosso projeto como Super Store. Nosso módulos principal se chamará `SuperStore` e o sistema de produtos será `SuperStore.Catalog`.

## Graduando do LiveView Playground

Até então usamos LiveView Playground pois nossos sistemas eram bem simples e não precisavam de tantas linhas. Até mesmo nosso formulário na aula anterior era menor que 70 linhas.

Todavia, a partir de agora vamos prezar bastante por organização. Teremos múltiplos módulos e repetir cada um a cada pequena coisa adicionada vai facilmente se tornar uma distração.

Dito isso, vamos aprender desta vez como fazer tudo isso em um projeto Mix real. Lembrando que Mix é a ferramenta de compilação do Elixir portanto finalmente estamos trabalhando em um projeto real!

### Ecto com SQLite

Para este CRUD em específico iremos utilizar Ecto (nossa biblioteca que nos ajudar a trabalhar com banco de dados) em conjunto com SQLite3. Escolhemos SQLite por dois motivos bem simples:

- **Não requer uma instalação de algo extra no seu computador**: basta instalar a a biblioteca e iniciar o banco.
- **O que iremos aprender aqui é facilmente reutilizável em outros bancos**: iremos focar em operações fundamentais do Ecto logo não importa se você pretender usar PostgreSQL ou MySQL o futuro, o código será o mesmo.

## Migrando nosso formulário para um projeto Phoenix zero bala

Para começar iremos clonar um projeto base que preparei para garantir que todos vendo essa aula tenham o mesmo ponto de início. Usando o seu terminal:

```
git clone https://github.com/adopt-liveview/first-crud.git
cd first-crud
mix setup
```

Com estes comandos você deve ter um projeto inicial em Phoenix. O comando `mix setup` não só instala como também compila as dependências para você. Uma vez que você tiver preparado o projeto e aberto sua IDE de preferência execute `mix phx.server` e vá ate [http://localhost:4000](http://localhost:4000) para ver a página inicial do seu projeto Phoenix.

Não se preocupe em explorar os arquivos existentes, iremos falar deles conforme necessário.

### Criando o arquivo `product.ex`

Agora nosso projeto se chama `SuperStore` então precisamos deixar isso claro no módulo atualmente chamado de `Product`. Como mencionado anteriormente, nosso sistema de gerência de produtos se chamará `SuperStore.Catalog` portanto iremos mover `Product` para `SuperStore.Catalog.Product`.

Em Phoenix chamamos estes módulos que encapsulam as funções que gerenciam uma parte de nossa aplicação de Context Modules. O Context `Catalog` tem como responsabilidade gerenciar nossos produtos. Se tivéssemos um Context chamado `Accounts` ele seria encarregado de gerenciar contas dos usuários. Cada Context pode ter zero ou mais schemas e geralmente a nomenclatura será `SeuProjeto.SeuContext` e `SeuProjeto.SeuContext.SeuSchema`.

Dentro da pasta `lib/super_store` crie um arquivo chamado `catalog.ex` com o seguinte conteúdo:

```elixir
defmodule SuperStore.Catalog do
end
```

Logo em seguida crie uma pasta `lib/super_store/catalog` e crie um arquivo `product.ex` com o seguinte conteúdo:

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

### Adicionando nossa LiveView

Tudo que diz respeito ao nosso sitema web será colocado dentro da pasta `lib/super_store_web`. Dentro desta pasta crie uma pasta chamada `live` e adicione o arquivo `page_live.ex` com o seguinte conteúdo:

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

As únicas modificações aqui foram no nome do módulo e nos macros do topo do módulo. Neste projeto nossas LiveViews irão sempre começar com `SuperStoreWeb.`. Alem disso, trocamos as referências `LiveviewPlaygroundWeb` para `SuperStoreWeb` e adicionamos um `alias SuperStore.Catalog.Product`.

%{
title: ~H"Me lembra uma coisa, como funcionam <code>`alias`</code> mesmo?",
description: ~H"""
Normalmente você precisa escrever o nome completo do módulo para usar ele como <code>`SeuProjeto.SeuContext.SeuSchema`</code> porém se você usar <code>`alias SeuProjeto.SeuContext.SeuSchema.changeset()`</code> você pode usar apenas a última parte como <code>`SeuSchema.changeset()`</code>. Precisamos fazer esse <code>`alias`</code> aqui pois nosso módulo agora tem um nome com múltiplas partes, diferente de antes em que ele simplesmente se chamava <code>`Product`</code>.
"""
} %% .callout

Como você pode notar o LiveView Playground é extremamente próximo do que uma LiveView de um projeto real deve ser.

### Trocando a rota principal para nossa LiveView

Abra o arquivo `router.ex` localizado na pasta `lib/super_store_web`. Você deve notar que ele possui uma única rota que não é uma LiveView configurada como `get "/", PageController, :home`. Mude isso para `live "/", PageLive, :home`.

## Projeto migrado!

A partir de agora você deve ter o mesmo projeto que o da última aula funcionando com uma única exceção de que você deve ver uma barra de navegação no topo.

Se você sentir dificuldade você pode ver o código pronto desta aula usando `git checkout my-first-liveview-project-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch my-first-liveview-project-done`.

## Resumindo!

- Agora que estamos em um projeto real usaremos a extensão `.ex` ao invés de `.exs` (usada para scripts).
- Projetos Phoenix organizam partes de seus sistemas em módulos chamados Context que ficam geralmente em `lib/sua_app`.
- Context Modules podem ter zero ou mais schemas vivendo em `lib/sua_app/seu_contexto`.
- Tudo relacionado a parte web do seu projeto viverá em `lib/sua_app_web`.
- Todas as LiveViews viverão em `lib/sua_app_web/live`.
- Não esqueça que para fazer uma LiveView ser acessível precisamos modificar nosso `router.ex`.
