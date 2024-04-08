%{
title: "Mostrando um produto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Mostrando um item em específico",
previous_page_id: "listing-data"
}

---

Em nossa aula anterior nós criamos a lista de produtos para nossa aplicação. Nesta aula iremos finalizar a parte Read do termo CRUD: vamos criar a página que mostra um produto em específico.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch listing-data-done`</code>.
"""
} %% .callout

## Mais uma vez, Context

A essa altura do campeonato você já deve ter imaginado que iríamos começar editando Context Module em `lib/super_store/catalog.ex`. Abra este arquivo e adicione a seguinte linha no final:

```elixir
defmodule SuperStore.Catalog do
  # ...

  def get_product!(id), do: Repo.get!(Product, id)
end

```

Desta vez você pode ver que o nome da função é levemente diferente: ela tem uma exclamação no final. Não só a função que estamos criando como também a função [`Repo.get/3`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:get!/3) possui uma exclamação. Em Elixir nós chamamos estas de "bang functions".

### Entendendo as bang functions

Enquanto você já deve ter notado que algumas funções do Elixir preferem retornar `{:ok, dado}` ou `{:error, dado}` as bang functions preferem retornar o dado ou causar um `raise` em uma exceção. Vamos ver isso na prática, entre no Interactive Elixir usando `iex -S mix`. Vamos supor que seu sistema tenha um produto de ID 1.

```elixir
[I] ➜ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> SuperStore.Catalog.get_product!(1)

[debug] QUERY OK source="products" db=1.8ms queue=0.2ms idle=74.6ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 WHERE (p0."id" = ?) [1]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%SuperStore.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  id: 1,
  name: "Elixir in Action",
  description: "A great book"
}

iex(2)> SuperStore.Catalog.get_product!(100000000)

[debug] QUERY OK source="products" db=14.9ms idle=1617.2ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 WHERE (p0."id" = ?) [100000000]

  ↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405
** (Ecto.NoResultsError) expected at least one result but got none in query:

from p0 in SuperStore.Catalog.Product,
  where: p0.id == ^100_000_000

    (ecto 3.11.2) lib/ecto/repo/queryable.ex:164: Ecto.Repo.Queryable.one!/3
    iex:2: (file)
iex(2)>
```

Quando usamos a função `SuperStore.Catalog.get_product!/1` com o ID 1 que existe o resultado é o produto, sem o formato `{:ok, product}`. Quando usamos com um ID inexistente o resultado é uma exceção `Ecto.NoResultsError`. Que vantagem existe em usar este formato ao invés de simplesmente nós tratarmos o erro?

### Tratamento automático de exceções

Internamente o framework Phoenix consegue entender que `Ecto.NoResultsError` é uma exceção que significa que o dado que você esperada não existe portanto esta página é um erro 404. Este tratamento vem da biblioteca `phoenix_ecto` que já veio instalada no seu projeto e que instalamos em aulas anteriores também. Veja diretamente do [código fonte](https://github.com/phoenixframework/phoenix_ecto/blob/3bdb207e31a242d3286faf117c95a3c40a048dc5/lib/phoenix_ecto/plug.ex#L1-L6) quais exceções são tratadas automaticamente:

```elixir
errors = [
  {Ecto.CastError, 400},
  {Ecto.Query.CastError, 400},
  {Ecto.NoResultsError, 404},
  {Ecto.StaleEntryError, 409}
]
```

Se você quiser tratar automaticamente exceções diferentes basta você dar uma olhada na documentação de [Custom Exceptions](https://hexdocs.pm/phoenix/custom_error_pages.html#custom-exceptions) do Phoenix. A principal vantagem aqui é: se o Phoenix trata o erro, nossa LiveView pode focar apenas no fluxo de sucesso.

## Criando nossa `ProductLive.Show`

Dentro da pasta `lib/super_store_web/live/product_live` crie um arquivo chamado `show.ex` com o seguinte conteúdo:

```elixir
defmodule SuperStoreWeb.ProductLive.Show do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog

  def handle_params(%{"id" => id}, _uri, socket) do
    product = Catalog.get_product!(id)
    socket = assign(socket, product: product)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Product <%= @product.id %>
      <:subtitle>This is a product record from your database.</:subtitle>
    </.header>

    <.list>
      <:item title="Name"><%= @product.name %></:item>
      <:item title="Description"><%= @product.description %></:item>
    </.list>

    <.back navigate={~p"/"}>Back to products</.back>
    """
  end
end
```

Note que usamos `handle_params/3` ao invés de `mount/3` para receber os params. Não há nenhum motivo em particular para essa escolha além de mostrar como pode ser simples trocar entre um e outro. Dentro da função chamamos nossa bang function sem pensar no caso em que o produto não irá existir e fazemos assign ao nosso socket.

### O componente `<.list>`

Dentro de nossa `render/` o único componente novo é o `<.list>` que também vem junto do `CoreComponents`. Para cada slot `<:item>` ele recebe um `title` e renderiza o conteúdo passado. Este componente é útil para mostrar coisas no formato `chave-valor`.

### Atualizando o nosso router

Abra seu `router.ex` e adicione a nova rota abaixo das demais:

```elixir
live "/products/:id", ProductLive.Show, :show
```

Mais uma vez seguimos não só o padrão de nomenclatura para a LiveView como também para a live action `:show`.

Abra uma aba [http://localhost:4000/products/1](http://localhost:4000/products/1) e veja seu produto sendo mostrado. Igualmente troque para um ID não-existemte como [http://localhost:4000/products/1123](http://localhost:4000/products/1123) e veja a mensagem de erro.

### Erros bonitos no ambiente de desenvolvimento

Vale mencionar que na página do ID inexistente você deve ter visto uma mensagem de erro bem formatada com código sendo mostrado e muito mais informação. O Phoenix trás consigo essa tela de erros apenas em ambiente de desenvolvimento. Em produção você verá apenas uma mensagem genérica de "Not found" pois não queremos vazar nada sobre nosso código para usuários.

Se você quiser ver como é a mensagem genérica sem ter que fazer deploy basta você abrir `config/dev.exs` e produtar por `debug_errors: true`, trocar para `false` e reiniciar o servidor.

## Criando link da lista ao produto

Mais uma vez, não devemos fazer nosso usuário descobrir onde estão as coisas. Abra sua `ProductLive.Index` e edite apenas a tabela dentro da `render/1` para:

```elixir
<.table
  id="products"
  rows={@streams.products}
  row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
>
  <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
  <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
</.table>
```

Agora ao clicar em uma linha da tabela seu usuário irá para a `ProductLive.Show`. O componente `<.table>` aceita um assign chamado `row_click` que recebe uma função anônima e passa para ela o `{id, product}`. Podemos ignorar o `id` e usar diretamente o `product`.

### `JS.navigate/2`

Aqui introduzimos um novo JS Command: [`JS.navigate/1`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#navigate/1). Ele recebe um URL e simplesmente navega o usuário para ela.

### `Phoenix.Param`

Talvez você esteja estranhando que o URl é `~p"/products/#{product}"` ao invés de `~p"/products/#{product.id}"` (note o `.id`). Isso ocorre porque o Phoenix sabe converter um schema do Ecto como `%Product{}` para URL ao ler seu ID. Apenas uma [curiosidade dos internos do framework](https://hexdocs.pm/phoenix/Phoenix.Param.html) para você carregar.

## Código final

Usando a rota de mostrar um produto conseguimos aprender muitas coisas relacionadas ao framework Phoenix e a linguagem de programação Elixir.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout show-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch show-data-done`.

## Resumindo!

- Podemos usar `Repo.get!/3` para pegar um dado do banco usando ID.
- Funções em Elixir com nome terminado em exclamação são chamadas de bang funcions.
- Bang functions não usam o formato conveniente de `{:ok, dado}` e `{:error, erro}`, elas simplesmente retornam o dado ou causam uma exceção.
- O Phoenix consegue tratar algumas exceções do Ecto automaticamente e converter em erros HTTP tornando nosso código mais simples porque podemos focar apenas no caso de sucesso.
- O componente `<.list>` é útil para renderizar estruturas `chave-valor` simples.
- Em desenvolvimento o Phoenix mostra mensagens de erro bonitas no navegador para exceções para ajudar o programador porém em produção as mensagens são genéricas (mas podem ser customizáveis).
- O componente `<.table>` aceita um assign `row_click` com uma função que é executada quando uma linha da tabela é clicada.
- O JS Command `JS.navigate/1` funciona exatamente como o componente `<.link navigate={...}>` exceto que de uma forma programática.
- Phoenix consegue converter automaticamente schemas Ecto em parâmetros URL ao olhar seu ID.
