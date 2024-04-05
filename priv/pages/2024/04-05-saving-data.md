%{
title: "Salvando dados com Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Persistindo dados",
previous_page_id: "simple-forms-with-ecto"
}

---

Esta seção do curso vai ser bem especial. Iremos por na prática muitas coisas que já falamos anteriormente para fazer um sistema bem simples de gerência de produtos, um famoso CRUD (Create-Read-Update-Delete).

Para simular um projeto real iremos nomear nosso projeto como Super Store. Nosso módulos principal se chamará `SuperStore` e o sistema de produtos será `SuperStore.Catalog`.

## Ecto com SQLite

Para este CRUD em específico iremos utilizar Ecto (nossa biblioteca que nos ajudar a trabalhar com banco de dados) em conjunto com SQLite3. Escolhemos SQLite por três motivos bem simples:

- **Ele funciona em memória**: podemos cometer erros, desfazer tabelas criadas incorretamente, reiniciar o servidor e começar do zero sem consequências.
- **Não requer uma instalação de algo extra no seu computador**: basta instalar a a biblioteca e iniciar o banco.
- **O que iremos aprender aqui é facilmente reutilizável em outros bancos**: iremos focar em operações fundamentais do Ecto logo não importa se você pretender usar PostgreSQL ou MySQL o futuro, o código será o mesmo.

### Instalando Ecto em um script Elixir

Antes de voltarmos para nossa LiveView vamos verificar como instalar o Ecto com SQLite. Crie e execute um script chamado `installing_ecto.exs`:

```elixir
Mix.install([
  {:ecto, "~> 3.11"},
  {:ecto_sqlite3, "~> 0.13"}
])

defmodule SuperStore.Repo do
  use Ecto.Repo, otp_app: :superstore, adapter: Ecto.Adapters.SQLite3
end

defmodule SuperStore.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :string, null: false
    end
  end
end

db_config = [database: ":memory:", pool_size: 1]
SuperStore.Repo.start_link(db_config)
Ecto.Migrator.up(SuperStore.Repo, 1, SuperStore.Repo.Migrations.Initial)

defmodule SuperStore.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end

defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end

SuperStore.Catalog.create_product(%{
  name: "Elixir in Action",
  description: "A great book"
}) |> dbg
```

Muita coisa nova! Vamos digerir isso no passo a passo.

### Introduzindo o `Repo`

```elixir
Mix.install([
  {:ecto, "~> 3.11"},
  {:ecto_sqlite3, "~> 0.13"}
])

defmodule SuperStore.Repo do
  use Ecto.Repo, otp_app: :superstore, adapter: Ecto.Adapters.SQLite3
end
```

Ecto utiliza um Design Pattern chamado Repository para acessar o banco de dados. A regra é simples: se você pretende executar uma query você irá usar esse módulo.

Definimos o nome do módulo como `SuperStore.Repo` para seguir o padrão do Ecto. Dentro dele tudo que precisamos fazer é `use Ecto.Repo` para preparar o módulo e como configuração em `otp_app` passamos o nome do projeto `:superstore` e adatpador usamos `Ecto.Adapters.SQLite3`.

### Migrando o banco de dados

```elixir
defmodule SuperStore.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :string, null: false
    end
  end
end

db_config = [database: ":memory:", pool_size: 1]
SuperStore.Repo.start_link(db_config)
Ecto.Migrator.up(SuperStore.Repo, 1, SuperStore.Repo.Migrations.Initial)
```

Para gerenciar modificações no banco de dados o Ecto usa o padrão de projeto de [schema migrations](https://en.wikipedia.org/wiki/Schema_migration). Por questões de simplicidade vamos usar uma migration para criar todo nosso banco apesar de que na prática você provavelmente gostaria de migrations mais simples.

Para criar uma migration basta criar um módulo `SuperStore.Repo.Migrations.NomeDaMigration` e dentro adicionar `use Ecto.Migration`. Dentro do nosso módulo devemos criar um método `change/0` onde podemos usar [`create/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#create/1), [`table/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#table/2) e [`add/3`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#add/3) para definir uma tabela simples chamada `products` com duas colunas chamadas `name` e `description`.

Em seguida nós iniciamos nosso banco de dados com `SuperStore.Repo.start_link(db_config)` e rodamos a migration com `Ecto.Migrator.up(SuperStore.Repo, 1, SuperStore.Repo.Migrations.Initial)`. Vale mencionar que em um projeto real você não precisa executar estas linhas manualmente, elas já executam quando voce inicializa o servidor e quando você roda o comando de migrações.

### Nosso `Ecto.Schema`

```elixir
defmodule SuperStore.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
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

Você pode esta sentindo uma familiaridade com o código anterior. Isso ocorre porque a principal mudança foi de `embedded_schema do` para `schema "products" do`. Enquanto que um `embedded_schema` é útil quando você não pretende trabalhar com um banco de dados, o macro [`schema/2`](https://hexdocs.pm/ecto/Ecto.Schema.html#schema/2) recebe o nome da tabela como primeiro argumento de modo com que quando usarmos nosso `Repo` ele saberá de onde ler/escrever os dados.

Outra mudança é que agora o nosso módulo se chama `SuperStore.Catalog.Product`. Por questões de organização iremos criar um módulo `SuperStore.Catalog` para adicionar todas as nossas funções do CRUD e posicionar a nomenclatura do `Product` dentro do `Catalog` deixa claro que um faz parte de outro.

### O contexto `Product.Catalog`

```elixir
defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end

SuperStore.Catalog.create_product(%{
  name: "Elixir in Action",
  description: "A great book"
}) |> dbg
```

A última parte do nosso código é a criação do módulo `SuperStore.Catalog`. Em Phoenix chamamos estes módulos que encapsulam as funções que gerenciam uma parte de nossa aplicação de Context Modules. O Context `Catalog` tem como responsabilidade gerenciar nossos produtos. Se tivéssemos um Context chamado `Accounts` ele seria encarregado de gerenciar contas dos usuários.

Cada Context pode ter zero ou mais schemas e geralmente a nomenclatura será `SeuProjeto.SeuContext` e `SeuProjeto.SeuContext.SeuSchema`. Alem disso, para facilitar usamos `alias` no `SuperStore.Repo` e `SuperStore.Catalog.Product` para poder escrever um pouco menos de código.

%{
title: ~H"Me lembra uma coisa, como funcionam <code>`alias`</code> mesmo?",
description: ~H"""
Normalmente você precisa escrever o nome completo do módulo para usar ele como <code>`SeuProjeto.SeuContext.SeuSchema`</code> porém se você usar <code>`alias SeuProjeto.SeuContext.SeuSchema.changeset()`</code> você pode usar apenas a última parte como <code>`SeuSchema.changeset()`</code>.
"""
} %% .callout

No momento nosso Context possui apenas a função de criar um `%Product{}`. Se você executar esse arquivo irá ver um exemplo de produto sendo criado.

Vamos implementar o Create do CRUD!

## Usando Ecto e SQLite no nosso formulário

Vamos direto ao ponto. Crie e execute um arquivo chamado `ecto_sqlite_and_liveview.exs`.

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.8"},
  {:phoenix_ecto, "~> 4.5"},
  {:ecto, "~> 3.11"},
  {:ecto_sqlite3, "~> 0.13"}
])

defmodule SuperStore.Repo do
  use Ecto.Repo, otp_app: :superstore, adapter: Ecto.Adapters.SQLite3
end

defmodule SuperStore.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :string, null: false
    end
  end
end

db_config = [database: ":memory:", pool_size: 1]
SuperStore.Repo.start_link(db_config)
Ecto.Migrator.up(SuperStore.Repo, 1, SuperStore.Repo.Migrations.Initial)

defmodule SuperStore.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string, default: ""
    field :description, :string, default: ""
  end

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end

defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import LiveviewPlaygroundWeb.CoreComponents

  alias SuperStore.Catalog
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
    Catalog.create_product(product_params) |> dbg
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

Não se preocupe com o tamanho dele, é apenas a junção do formulário da aula anterior com o que acabamos de aprender sobre Ecto. Vamos falar sobre o que mudou:

### Instalando Ecto e LiveView

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.8"},
  {:phoenix_ecto, "~> 4.5"},
  {:ecto, "~> 3.11"},
  {:ecto_sqlite3, "~> 0.13"}
])
```

Nosso `Mix.install/2` precisa tanto das bibliotecas de Ecto quanto do nosso LiveView Playground e Phoenix Ecto para que tudo seja unido de maneira simplificada.
