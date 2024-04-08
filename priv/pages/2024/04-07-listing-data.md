%{
title: "Listando produtos",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Organizando nosso projeto e listando nossos produtos",
previous_page_id: "saving-data",
next_page_id: "show-data"
}

---

Na aula anterior nós criamos vários produtos! Vamos criar uma página simples de listar produtos salvos.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch saving-data-done`</code>.
"""
} %% .callout

## De volta ao nosso Context

Lembre-se que todas as operações que dizem respeito a modificar o nosso domínio de produtos serão concentradas no context `Catalog`. Neste momentos precisamos de uma função para listar todos os produtos. Abra o `lib/super_store/catalog.ex` e adicione o método `list_products/0`:

```elixir
defmodule SuperStore.Catalog do
  alias SuperStore.Repo
  alias SuperStore.Catalog.Product

  def list_products() do
    Product
    |> Repo.all()
  end

  def create_product(attrs) do
    Product.changeset(%Product{}, attrs)
    |> Repo.insert()
  end
end
```

Para listar linhas do nosso banco de dados usamos a função [`Repo.all/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:all/2) que recebe uma query em formato Ecto e retorna todas as linhas. O nosso módulo `Product` em si é considerado uma query e, neste caso, representa `select * from products`.

### Testando no `iex`.

Abra seu `iex -s mix` e execute `SuperStore.Catalog.list_products()`:

```elixir
$ iex -S mix
[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> SuperStore.Catalog.list_products()

[debug] QUERY OK source="products" db=0.2ms queue=0.2ms idle=283.7ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

[
  %SuperStore.Catalog.Product{
    __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
    id: 1,
    name: "Elixir in Action",
    description: "A great book"
  },
  ...
]
```

Como você pode ver nossa função funciona. Podemos ir aplicar ela em uma nova LiveView.

## Criando uma nova LiveView

Para listar nossos produtos iremos criar uma nova LiveView chamada `SuperStoreWeb.ProductLive.Index`. Projetos Phoenix gostam de seguir esse padrão: `SuaAppWeb.NomeDeAlgoLive.{Index ou Show ou New ou Edit}`. Crie a pasta `lib/super_store_web/live/product_live` e dentro dela crie um arquivo `index.ex` com o seguinte código:

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog

  def mount(_params, _session, socket) do
    socket = stream(socket, :products, Catalog.list_products())
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.table id="products" rows={@streams.products}>
      <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
      <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
    </.table>
    """
  end
end
```

### Lembra de streams?

Na aula sobre renderização de listas nós falamos sobre streams como maneira otimizada de renderizar itens em HEEx. Naquela aula houve um pouco mais de complexidade no código pois precisávamos adicionar a cada elemento um `id` mas neste caso como estamos trabalhando com um banco de dados todos os elementos possuem um `id` portanto conseguimos definir uma stream de products com zero dor de cabeça.

### Usando o componente `<.table>`

Projetos Phoenix contém em seu `CoreComponents` um componente muito poderoso chamado `<.table>`. Ao decorrer das aulas de CRUD iremos aprender um pouquinha mais sobre ele.

```elixir
<.table id="products" rows={@streams.products}> ... </.table>
```

No momento tudo que você precisa entender é que este componente sabe trabalhar muito bem com streams. Passamos ao componente dois assigns: `id` único e `rows` recebe a stream de `products`.

```elixir
<:col :let={{_id, product}} label="Name"><%= product.name %></:col>
```

Dentro do componente você pode ver que usamos o slot `<:col>` duas vezes. Cada um desses slots necessita de um atributo `label` para definir o nome da coluna na tabela e recebe o atributo especial `:let` para você ter acesso ao `{id, elemento}`. No momento podemos ignorar o `id` e recebemos o `product` para renderizar o conteúdo daquela coluna para cada produto. Se isso tudo parece muito estranho você pode dar uma olhada na nossa aula de renderização de listas com slots na seção de componentes.

## Atualizando nossa LiveView antiga

No momento, na pasta `lib/super_store_web/live` nós temos o arquivo `page_live.ex`. Com este nome não fica óbvio o propósito desta LiveView. Mova esta arquivo para `lib/super_store_web/live/product_live/new.ex` e renomeie o módulo para `SuperStoreWeb.ProductLive.New`. Agora não só sabemos o propósito dela por ver a organização de pastas como também o nome do módulo segue o padrão Phoenix!

## Atualizando nosso `router.ex`

Abra seu router em `lib/super_store_web/router.ex` e o modifique suas rotas dentro do escopo principal:

```elixir
scope "/", SuperStoreWeb do
  pipe_through :browser

  live "/", ProductLive.Index, :index
  live "/products/new", ProductLive.New, :new
end
```

Note que também mudamos a live action do `ProductLive.New` para deixar óbvio que é uma LiveView que cria algo.

###

Sucesso! Abra seu navegador e verá que na página inicial todos os seus produtos são listados. Mas peraí, como vamos para a página de criar produto? Seu usuário não vai adivinhar a rota!

### Conectando as páginas usando links

Vá até a sua `ProductLive.Index` e modifique a sua `render/1` um pouco:

```elixir
def render(assigns) do
  ~H"""
  <.header>
    Listing Products
    <:actions>
      <.link patch={~p"/products/new"}>
        <.button>New Product</.button>
      </.link>
    </:actions>
  </.header>

  <.table id="products" rows={@streams.products}>
    <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
    <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
  </.table>
  """
end
```

Usamos o componente `<.header>` que também vem dos `CoreComponents` para não só dar um título à nossa página de listar produtos como também usamos seu slot `<:action>` para adicionar um link para nossa página de produto.

Do mesmo modo modifique a `render/1` da sua `ProductLive.New` para:

```elixir
def render(assigns) do
  ~H"""
  <.header>
    New Product
    <:subtitle>Use this form to create product records in your database.</:subtitle>
  </.header>

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

  <.back navigate={~p"/"}>Back to products</.back>
  """
end
```

Além do `<.header>` no topo, adicionamos no final o componente `<.back>` referenciando a página inicial da nossa aplicação. Caso você esteja curioso, este componente não tem nada mágico ele é apenas um `<.link>` com um ícone de voltar (uma seta para a esquerda).

## Código final

Agora sua aplicação não apenas está mais organizada em termos de pastas como também o usuário vai ter uma boa primeira experiência de navegação.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout listing-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch listing-data-done`.

## Resumindo!

- Usando `Repo.all/2` listamos o resultado de uma query em Ecto.
- O módulo `Product` pode ser considerado uma query Ecto no formato `select * from products`.
- Projetos Phoenix gostam de seguir esse padrão: `SuaAppWeb.NomeDeAlgoLive.{Index ou Show ou New ou Edit}`
- Para as pastas de seu projeto LiveView ficarem mais organizadas usamos o formato `lib/sua_app_web/live/seu_model/{index.ex ou new.ex ou edit.ex ou show.ex}` como veremos em aulas futuras.
- Quando usamos bancos de dados fica muito fácil usar streams em LiveView pois os elementos já vem com `id`.
- O componente `<.table>` é muito poderoso em simplificar tabelas com items como veremos no futuro.
- Em seu `router.ex` dê preferência a Live Actions entre `:new`, `:index`, `:edit` e `:show` como veremos nas próximas aulas.
- O componente `<.header>` é bem útil para dar título a suas páginas e também pode conter um slot `<:actions>` para simplificar adicionar botões de ação como usamos para adicionar o botão de criar produto.
