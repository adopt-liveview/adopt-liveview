%{
title: "Salvando dados com Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Persistindo dados",
previous_page_id: "my-first-liveview-project",
next_page_id: "listing-data"
}

---

Iremos finalmente começar a implementar nosso CRUD (Create-Read-Update-Delete). Atualmente nosso projeto já tem instalado não só LiveView como Ecto então iremos focar em como por isso na prática. Nesta aula iremos aprender como persistir nosso produto no banco de dados.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch my-first-liveview-project-done`</code>.
"""
} %% .callout

## Conceitos importantes de Ecto

Antes de começarmos código novo iremos explorar um pouquinho do que o projeto Phoenix já instalou para você e, ao mesmo tempo, conversar sobre os padrões do projeto.

### Introduzindo o `Repo`

Se você se dirigir ao arquivo `lib/super_store/repo.ex` verá o seguinte código:

```elixir
defmodule SuperStore.Repo do
  use Ecto.Repo,
    otp_app: :super_store,
    adapter: Ecto.Adapters.SQLite3
end
```

Ecto utiliza um Design Pattern chamado Repository para acessar o banco de dados. A regra é simples: se você pretende executar uma query você irá usar esse módulo. Sempre que o banco de dados precisar ser acessado você verá algo como `Repo.insert()` ou `Repo.one()`.

O Phoenix automaticamente gerou este módulo `SuperStore.Repo`. Sempre a nomenclatura será no formato `SeuProjeto.Repo`. Dentro dele o `use Ecto.Repo` prepara o módulo com funções como `Repo.insert` e as opções passadas definem a configuração de nosso Repo. A opção `otp_app` contém o nome do nosso projeto Mix `:super_store` e como adatpador usamos `Ecto.Adapters.SQLite3`.

### Migrando o banco de dados

Para gerenciar modificações no banco de dados o Ecto usa o padrão de projeto chamado [schema migrations](https://en.wikipedia.org/wiki/Schema_migration). A lógica de migrations é simples: sempre que você precisar modificar a estrutura do seu banco de dados você gera uma migration que ensina ao Ecto o que precisa ser feito.

Vamos criar sua primeira migration: queremos criar a tabela produtos. Usando o seu terminal execute `mix ecto.gen.migration create_products`. O resultado será algo como:

```bash
* creating priv/repo/migrations/20240405213602_create_products.exs
```

Não se preocupe se o nome não for exatamente igual. As migrations possuem um timestamp no início do seu nome para ficar claro a ordem na qual foram criadas. Neste momento sua migration deve estar com um código como o abaixo:

```elixir
defmodule SuperStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do

  end
end
```

Vamos modificar um pouquinho isso para:

```elixir
defmodule SuperStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :string, null: false
    end
  end
end
```

Dentro do nosso módulo devemos possuir um método `change/0`. A responsabilidade desse método é dizer o que mudou no seu banco de dados. O módulo `Ecto.Migration` que importamos no topo de nossa migration contém essa e outras funções de DDL (Data Definition Language) preparadas para operações comuns de modificar a estrutura do nosso banco.

Dentro de `change/0` podemos usar [`create/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#create/2) para definir que estamos criando algo, [`table/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#table/2) para dizer que estamos criando uma tabela nova chamada `products` e [`add/3`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#add/3) para definir as duas colunas chamadas `name` e `description` dentro desta tabela.

Quando sua migration estiver pronta execute `mix ecto.migrate` para executá-la:

```bash
$ mix ecto.migrate

08:56:48.950 [info] == Running 20240405213602 SuperStore.Repo.Migrations.CreateProducts.change/0 forward

08:56:48.952 [info] create table products

08:56:48.955 [info] == Migrated 20240405213602 in 0.0s
```

%{
title: "Como desfazer uma migration?",
type: :warning,
description: ~H"""
Se algo de errado acontecer ou se você achar que sua migration estava incorreta você sempre pode executar <code>`mix ecto.rollback`</code> para desfazer as migrations aplicadas na última vez que você executou <code>`mix ecto.migrate`</code> (mesmo que tenham sido mais de uma). <br><br>Se você estiver curioso em como o Ecto sabe desfazer a resposta é bem simples: se sua migration possui um método <code>`create/2`</code> com <code>`table/2`</code> ele sabe que o inverso disso é apagar uma tabela. Por isso que podemos criar uma migration apenas com a função <code>`change/0`</code> ao invés de <code>`up`</code> e <code>`down`</code> como em outros frameworks, apesar de que o Ecto opcionalmente aceita estes callbacks se você possuir alguma migration específica do seu banco de dados atual.
"""
} %% .callout

### Atualizando nosso `Ecto.Schema`

Vá até `lib/super_store/catalog/product.ex`. No momento ele deve estar definido como:

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

Um `embedded_schema` é útil quando você não pretende trabalhar com um banco de dados. Para fazer este schema funcionar com um banco a modificação é muito simples! Usaremos o macro [`schema/2`](https://hexdocs.pm/ecto/Ecto.Schema.html#schema/2) que recebe o nome da tabela como primeiro argumento de modo com que quando usarmos nosso `Repo` ele saberá de onde ler/escrever os dados.

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

Com apenas uma linha de código nosso schema está pronto para o CRUD completo!

### O contexto `Product.Catalog`

Vamos ao `lib/super_store/catalog.ex`. Na aula anterior apenas criamos este módulo. Iremos concentrar todas as operaçòes de CRUD do nosso sistema de produtos neste Context.

Tudo que diz respeito a produtos estará aqui. O Phoenix se inspira muito em DDD (Domain-Driven Design) onde cada parte de sua aplicação foca em seu domínio em específico.

Vamos adicionar nossa primeira: `create_product/1`:

```elixir
defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end
```

Usando os `alias` para poder escrever um pouco menos de código, nós criamos uma função que recebe `attrs` e valida eles com nosso `Product.changeset/2` e, em seguida, tenta inserir no nosso banco de dados. Esta função tem dois possíveis resultados: `{:ok, %Product{...}` se tudo der certo ou `{:error, %Ecto.Changeset{...}}` se houver um erro de validação.

### Testando nosso módulo diretamente do terminal

Podemos testar tudo que construímos até agora sem sequer começar a mexer em nossa LiveView! Como construímos um módulo `SuperStore.Catalog` que não depende de nada relacionado a web podemos simplesmente iniciar um terminal interativo com nosso código do projeto mix e executar a função `create_product/2`.

Usando seu terminal execute os seguinte comando marcado como $ no início da linha:

```elixir
$ iex -S mix
[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

Usando `iex -S mix` entramos no modo Interactive Elixir (`iex`) contendo todas as funções do nosso projeto. No início da ultima linha você pode ver que `iex(1)>` virou seu novo prompt de comando. Vamos importar nosso context:

```elixir
iex(1)> alias SuperStore.Catalog
SuperStore.Catalog
iex(2)>
```

Agora podemos escrever `Catalog.` ao invés de `SuperStore.Catalog.`. Vamos criar nosso primeiro produto! Execute: `Catalog.create_product(%{ name: "Elixir in Action", description: "A great book" })`.

```elixir
iex(2)> Catalog.create_product(%{ name: "Elixir in Action", description: "A great book" })

[debug] QUERY OK source="products" db=0.7ms idle=1532.9ms
INSERT INTO "products" ("name","description") VALUES (?,?) RETURNING "id" ["Elixir in Action", "A great book"]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

{:ok,
 %SuperStore.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
   id: 1,
   name: "Elixir in Action",
   description: "A great book"
 }}
```

Excelente! Nosso banco de dados tem um produto. Vamos verificar nossas validações. Use o seguinte comando para criar um produto inválido: `Catalog.create_product(%{ name: "Missing description" })`.

```elixir
iex(3)> Catalog.create_product(%{ name: "Missing description" })
{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{name: "Missing description"},
   errors: [description: {"can't be blank", [validation: :required]}],
   data: #SuperStore.Catalog.Product<>,
   valid?: false
 >}
```

Como esperado, nosso changeset tratou nossa validação corretamente e não criou nada no banco de dados. Agora que sabemos que nosso Context funciona como esperado nós podemos retornar a nossa LiveView.

## Usando nosso Context em nossa LiveView

Neste momento sua PageLive deve estar parecendo como isso:

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

Nosso evento de `"create_product"` no momento não faz nada alem de gerar um log no terminal: `IO.inspect({"Form submitted!!", product_params})`. Vamos melhorar isso.

### Melhorando nosos evento `"create_product"`

No topo da sua PageLive crie um `alias SuperStore.Catalog`. Modifique o evento de `"create_product"` para:

```elixir
def handle_event("create_product", %{"product" => product_params}, socket) do
  socket =
    case Catalog.create_product(product_params) do
      {:ok, %Product{} = product} ->
        put_flash(socket, :info, "Product ID #{product.id} created!")

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)

        socket
        |> assign(form: form)
        |> put_flash(:error, "Invalid product!")
    end

  {:noreply, socket}
end
```

Como comentado anteriormente, nossa função `Catalog.create_product/2` possui duas possibilidades. Usando o `case-do` conseguimos tratar ambas de uma maneira graciosa. Se o resultado for `{:ok, %Product{} = product}` nós adicionamos ao nosso socket uma mensagem de sucesso usando [`put_flash/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#put_flash/3).

Caso ocorra um erro de validação nós recebemos o changeset e convertemos ele num `form` usando `to_form/2`. Em seguida usamos `put_flash/3` desta vez para informar um erro.

### Código final

Nosso código final para a LiveView:

```elixir
defmodule SuperStoreWeb.PageLive do
  use SuperStoreWeb, :live_view
  import SuperStoreWeb.CoreComponents
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
    socket =
      case Catalog.create_product(product_params) do
        {:ok, %Product{} = product} ->
          put_flash(socket, :info, "Product ID #{product.id} created!")

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)

          socket
          |> assign(form: form)
          |> put_flash(:error, "Invalid product!")
      end

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

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout saving-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch saving-data-done`.

## Resumindo!

- Ecto usa o design pattern Repository para trabalhar com banco de dados.
- Sempre que formos utilizar o banco de dados usaremos uma função do módulo `Repo`.
- Para modificar a estrutura do banco de dados o Ecto usa o design pattern schema migrations.
- Para criar uma migration você precisa rodar no terminal `mix ecto.gen.migration nome_da_migration`.
- Para aplicar as migrations pendentes você deve executar no terminal `mix ecto.migrate`.
- Para desfazer as últimas migrations instaladas você pode executar no terminal `mix ecto.rollback`.
- Um schema com `embedded_schema do` não trabalha com banco de dados mas `schema "nome_da_tabela" do` é tudo que você precisa para ensinar ao Ecto como mexer com esta tabela.
- Em projetos Phoenix concentramos as funções de um certo domínio em um context módulo, seguindo inspiração de [DDD](https://en.wikipedia.org/wiki/Domain-driven_design).
- Em nosso projeto atual nós focaremos nosso domínio de gerenciamento de produtos no context `SuperStore.Catalog`.
- Você pode usar `iex -S mix` para entrar no modo Interactive Elixir e testar todas as funções do seu projeto.
- Uma vez que seu context e schema estão bem modelados é trivial adicionar suas funções em sua LiveView.
