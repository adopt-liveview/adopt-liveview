%{
title: "Deletando um produto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Criando uma UX de deletar um elemento",
previous_page_id: "show-data",
}

---

Vamos pular para a última letra do CRUD: o Delete. Nesta aula vamos ver como é simples gerar uma UX de deletar um elemento usando recursos do próprio projeto.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch show-data-done`</code>.
"""
} %% .callout

## Você já imagivana que começaríamos com o Context

O primeiro passo é voltarmos para nosso `lib/super_store/catalog.ex` e adicionarmos uma nova função:

```elixir
defmodule SuperStore.Catalog do
  # ...

  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end
end
```

A função `delete_product/1` recebe um struct do tipo `%Product{}` e apenas aplica o método [`Repo.delete/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:delete/2) nele. O resultado será `{:ok, %Product{}}` caso seja necessário usar o produto novamente.

### Testando no `iex`

Usando o confiável modo de Elixir Interativo podemos pegar o último produto com `product = SuperStore.Catalog.list_products() |> List.last` e o deletar usando `SuperStore.Catalog.delete_product(product)`:

```elixir
$ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> product = SuperStore.Catalog.list_products() |> List.last

[debug] QUERY OK source="products" db=0.2ms queue=0.1ms idle=1192.5ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%SuperStore.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  id: 10,
  name: "asda",
  description: "ad"
}

iex(2)> SuperStore.Catalog.delete_product(product)
[debug] QUERY OK source="products" db=1.7ms idle=1366.3ms
DELETE FROM "products" WHERE "id" = ? [10]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405
{:ok,
 %SuperStore.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:deleted, "products">,
   id: 10,
   name: "asda",
   description: "ad"
 }}
```

## Deletando produtos na lista

Ao invés de criarmos uma nova LiveView chamada `ProductLive.Delete` podemos reusar a lista de produtos para isso. Abra sua `ProductLive.Index` localizada em `lib/super_store_web/live/product_live/index.ex`.

### O slot `<:action>` do componente `<.table>`

Dentro da sua `render/1` atualize sua `<.table>` para o seguinte código:

```elixir
<.table
  id="products"
  rows={@streams.products}
  row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
>
  <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
  <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
  <:action :let={{id, product}}>
    <.link
      phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>
```

Adicionamos um slot chamado `<:action>` onde recebemos tanto o `id` quanto o `product` usando o atributo especial `:let`. Este slot fica como última coluna para adicionarmos botões de ação na nossa linha.

### O ID do `:let`

Este `id` em específico é conhecido como "HTML ID" e, neste caso, deve ser algo como "products-123" pois nossa tabela tem ID "products" e supondo que o ID no banco de dados do elemento é 123. Ele é útil para aplicarmos JS.commands.

### Confirmando ações com `data-confirm`

O próximo ponto e foco é o `data-confirm`. Não queremos que o item seja deletado imediatamente sem qualquer tipo de confirmação, certo? O Phoenix verifica que, caso você clique um elemento com `data-confirm` ele dispara um `confirm` do seu navegador e apenas aplica o `phx-click` se o usuário confirmar.

### O comando `JS.hide/2`

Dentro do nosso binding `phx-click` duas coisas acontecem:

1. Enviamos um evento a nossa LiveView chamado "delete" (ainda precisamos definir ele).
2. Escondemos o elemento da linha atual usando o HTMLl ID.

Como você pode notar não estamos usando diretamente `JS.hide/2` e sim apenas a função `hide/1`. Isso acontece porque o Phoenix já trás dentro do `CoreComponents` esta função simplificada que já aplica transições usando classes CSS! Dentro de seu `CoreComponents`:

```elixir
def hide(js \\ %JS{}, selector) do
  JS.hide(js,
    to: selector,
    time: 200,
    transition:
      {"transition-all transform ease-in duration-200",
       "opacity-100 translate-y-0 sm:scale-100",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
  )
end
```

Sempre que puder prefira usar `hide/1` do `CoreComponents` porém se você precisar customizar a transição opte por `JS.hide/2`.

### Criando o evento de deletar

Para podermos testar este código precisamos criar nosso `handle_event/3`. Em sua LiveView, abaixo do `mount/3` adicione o callback:

```elixir
def handle_event("delete", %{"id" => id}, socket) do
  product = Catalog.get_product!(id)
  {:ok, _} = Catalog.delete_product(product)

  {:noreply, stream_delete(socket, :products, product)}
end
```

Neste evento recebemos apenas o ID, imediatamente verificamos no banco se o produto existe usando a função `Catalog.get_product/1` que construímos na aula anterior. Em seguida, deletamos o produto. Como já temos a variável `product` nós ignoramos o segundo resultado da função de deletar.

### A função `stream_delete/3`

Em aulas anteriores já haviamos visto como criar streams usando `stream/4` para renderizar listas de uma maneira eficiente. Agora vemos a função [`stream_delete/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream_delete/3) para deletar um item da stream.

Lembrando que streams não armazenam nenhum dado em memória sobre os items, a função `stream_detele/3` recebe o nome da stream que é `:products` como definimos no nosso `mount/3` e o `product`. Usando essas duas variáveis ela infere que o HTML ID do elemento será `#products-123` e envia um dado simples indicando que a LiveView deve deletar este elemento do HTML. Lembrando que o elemento já foi escondido usando o nosso `hide/1` anteriormente.

### Código da LiveView

Com todas as peças unidas sua `ProductLive.Index` deve estar próximo deste código:

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog

  def mount(_params, _session, socket) do
    socket = stream(socket, :products, Catalog.list_products())
    {:ok, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

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

    <.table
      id="products"
      rows={@streams.products}
      row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
    >
      <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
      <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
      <:action :let={{id, product}}>
        <.link
          phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end
end
```

## Código final

Pronto! Agora basta você testar sua LiveView e ver como o fluxo atual está funcionando.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout deleting-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch deleting-data-done`.

## Resumindo!

- A função `Repo.delete/2` recebe um struct de um schema Ecto e o deleta do banco de dados.
- O slot `<:action>` é útil para adicionar botões de ação nas suas tabelas.
- Os IDs que vem do atributo especial `:let` em slots do componente `<.table>` se chamam HTML ID e seguem o formato `nome-da-sua-stream-ID` (onde ID é o ID no banco de dados do elemento).
- O HTML ID é útil para aplicar JS commands.
- O `CoreComponents` de projetos Phoenix vem com uma função `hide/1` que apenas é a `JS.hide/2` porém com uma transição bonita.
- Podemos usar `data-confirm` para confirmar com o usuário antes de disparar uma ação como um `phx-click`.
- A função `stream_delete/3` é uma forma de deletar elementos de uma stream. Esta função otimiza enviar o mínimo de dados para a LiveView portanto segue a ideia de que streams são uma maneira eficiente de gerenciar listas em LiveView.
