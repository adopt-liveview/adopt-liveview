%{
title: "Editando um produto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Formulários porém para editar algo existente",
previous_page_id: "deleting-data",
}

---

Para finalizarmos o CRUD iremos criar um formulário de edição de produto. Vamos ver como este pode ser extremamente parecido com o formulário de criação de produto.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/first-crud.git --branch deleting-data-done`</code>.
"""
} %% .callout

## De volta ao Context

Vamos voltar ao nosso `lib/super_store/catalog.ex` e adicionar uma nova função:

```elixir
defmodule SuperStore.Catalog do
  # ...

  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end
end
```

Diferente de `create_product/1` que apenas recebe os atributos, para atualizarmos um produto precisamos do dado original para poder aplicar as alterações. Nossa função `Catalog.update_product/2` recebe o struct original e as modificações, aplica o changeset e, usando a função [`Repo.update/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:update/2) retorna `{:ok, %Product{}}` ou `{:error, %Ecto.Changeset{}}`.

### Testando no `iex`

Usando o Elixir Interativo podemos pegar o último produto com `product = SuperStore.Catalog.list_products() |> List.last` e o atualizá-lo usando `SuperStore.Catalog.update_product(product, %{name: "Edited"})`:

```elixir
$ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> product = SuperStore.Catalog.list_products() |> List.last

[debug] QUERY OK source="products" db=0.0ms idle=823.0ms
SELECT p0."id", p0."name", p0."description" FROM "products" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%SuperStore.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  id: 7,
  name: "asda",
  description: "asd"
}

iex(2)> SuperStore.Catalog.update_product(product, %{name: "Edited"})

[debug] QUERY OK source="products" db=0.7ms idle=539.3ms
UPDATE "products" SET "name" = ? WHERE "id" = ? ["Edited", 7]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

{:ok,
 %SuperStore.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
   id: 7,
   name: "Edited",
   description: "asd"
 }}
iex(3)>
```

Note que nos segundo argumento passamos apenas o nome. Nosso changeset requer uma `description` obrigatoriamente porém, como o produto original já possui uma descrição, essa validação passa.

## Construindo nossa LiveView

Vamos escrever o código da LiveView passo-a-passo de modo que possamos ver as semelhanças com a ProductLive.Create. Na pasta `lib/super_store_web/live/product_live/` crie um arquivo `edit.ex`.

### Começando

```elixir
defmodule SuperStoreWeb.ProductLive.Edit do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product
end
```

O primeiro passo é criar o módulo e `use SuperStoreWeb, :live_view`. Em seguida, adicionamos dois alias úteis para o que vem a seguir.

```elixir
def mount(%{"id" => id}, _session, socket) do
  product = Catalog.get_product!(id)

  form =
    Product.changeset(product)
    |> to_form()

  {:ok, assign(socket, form: form, product: product)}
end
```

### O `mount/3`

Em nossa função `mount/3` nós recebemos como parâmetro o `id` do produto. Logo mais iremos definir isso no router como `live "/products/:id/edit", ProductLive.Edit, :edit` portanto podemos garantir que haverá este `id`.

O próximo passo é usar `product = Catalog.get_product!(id)` para recuperar o produto pelo `id`. Vale lembrar que se não houver um produto com este `id` um erro 404 será automaticamente gerado como vimos em aulas anteriores.

Definimos nosso `form` como um changeset que recebe o produto original. No formulário de criação nós usamos `Product.changeset(%Product{})`, ou seja, o produto vazio pois naquele momento não existe um produto. Como estamos trabalhando com edição, todos os nossos changesets irão receber o produto sendo editado.

Note também que no assign passamos o `product`. Iremos usar esse assign não só no nosso HEEx como também em outros eventos.

### O evento de validação

```elixir
def handle_event("validate_product", %{"product" => product_params}, socket) do
  form =
    Product.changeset(socket.assigns.product, product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

O evento de validação é uma cópia cuspida do formulário de criação exceto que o `Product.changeset/2` recebe no primeiro argumento, ao invés de `%Product{}` (o produto vazio), o `socket.assigns.product` que contém o valor do produto sendo editado.

### O evento de salvar

```elixir
def handle_event("save_product", %{"product" => product_params}, socket) do
  socket =
    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, %Product{} = product} ->
        put_flash(socket, :info, "Product ID #{product.id} updated!")

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)

        socket
        |> assign(form: form)
        |> put_flash(:error, "Invalid data!")
    end

  {:noreply, socket}
end
```

Mais uma vez o nosso evento é uma cópia cuspida do evento de criar produto. Renomeamos o evento para `"save_product"` para fazer sentido com o formulário e trocamos a função principal no `case` para `Catalog.update_product/2` passando mais uma vez o `socket.assign.product`. Mofificamos também o `put_flash/2` para uma mensagem que faz mais sentido.

### A `render/1`

```elixir
def render(assigns) do
  ~H"""
  <.header>
    Editing Product <%= @product.id %>
    <:subtitle>Use this form to edit product records in your database.</:subtitle>
  </.header>

  <div class="bg-grey-100">
    <.form
      for={@form}
      phx-change="validate_product"
      phx-submit="save_product"
      class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
    >
      <h1>Editing a product</h1>
      <.input field={@form[:name]} placeholder="Name" />
      <.input field={@form[:description]} placeholder="Description" />

      <.button type="submit">Send</.button>
    </.form>
  </div>

  <.back navigate={~p"/products/#{@product}"}>Back to product</.back>
  """
end
```

Nesta parte modificamos apenas os textos e o nome do evento do binding `phx-submit`. Não houve nenhuma modificação funcional exceto que o link do componente `<.back>` agora retorna pra página de visualizar o produto.

### Atualizando o router

Abra seu arquivo de router e adicione a rota `live "/products/:id/edit", ProductLive.Edit, :edit`. No momento seu router deve estar do seguinte modo:

```elixir
# ...
scope "/", SuperStoreWeb do
  pipe_through :browser

  live "/", ProductLive.Index, :index
  live "/products/new", ProductLive.New, :new
  live "/products/:id", ProductLive.Show, :show
  live "/products/:id/edit", ProductLive.Edit, :edit
end
# ...
```

## Adicionando um link pro formulário

Temos uma página, mas nossos usuários não conhecem ela. Abra sua `ProductLive.Edit` e atualize apenas o componente `<.header>` para adicionar este `<:actions>`:

```elixir
<.header>
  Product <%= @product.id %>
  <:subtitle>This is a product record from your database.</:subtitle>
  <:actions>
    <.link patch={~p"/products/#{@product}/edit"}>
      <.button>Edit event</.button>
    </.link>
  </:actions>
</.header>
```

## Código final

Finalizado! Nossa aplicação possui um CRUD completo. Ainda existem algumas coisas que podem melhorar e iremos ver isso em outra seção mas se você seguiu o curso até então você já tem conhecimento suficiente para se virar criando seu próximo CRUD!

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout editing-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch editing-data-done`.

## Resumindo!

- Usando `Repo.update/2` conseguimos atualizar um produto passando um changeset.
- Uma LiveView de formulário de editar pode ser extremamente parecida com uma de criar um dado.
- Você já sabe fazer um CRUD completo em LiveView 😉.
