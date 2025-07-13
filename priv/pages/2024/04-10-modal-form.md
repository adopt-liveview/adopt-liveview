%{
title: "Modal Form",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "Como reusar formulários em um modal",
previous_page_id: "live-component",
}

---

Agora que nosso formulário está em um Live Component podemos reutilizar ele com muito mais facilidade. Nesta aula iremos aprender como usar o component `<.modal>` para fazer um formulário de edição rápida de produtos na página inicial.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/refactoring-crud.git --branch live-component-done`</code>.
"""
} %% .callout

## Usando `ProductLive.Index` para edição?

Em aulas anteriores vimos como é possível usar a mesma LiveView para mais de uma ação. Vamos fazer com que nossa `ProductLive.Index` seja capaz de listar e editar um produto! Em seu arquivo router adicione a segunda cláusula da sua rota index:

```elixir
live "/", ProductLive.Index, :index
live "/:id/edit", ProductLive.Index, :edit # Adicionar esta linha
```

Agora nossa rota `ProductLive.Index` tem dois valores possíveis para `@live_action`: `:index` ou `:edit`.

### Adicionando um link para a edição rápida

Abra o arquivo `index.ex` e edite a tabela que lista produtos do seguinte modo:

```elixir
~H"""
...

<.table
  id="products"
  rows={@streams.products}
  row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
>
  <:col :let={{_id, product}} label="Name"><%= product.name %></:col>
  <:col :let={{_id, product}} label="Description"><%= product.description %></:col>
  <:action :let={{_id, product}}>
    <.link patch={~p"/#{product}/edit"}>Quick Edit</.link>
  </:action>
  <:action :let={{id, product}}>
    <.link
      phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>

...
"""
```

Adicionamos um slot `<:action>` novo com apenas um link para a nova rota de edição. Note que usamos `<.link patch{}>` pois estamos na mesma LiveView! Outro ponto que devemos lembrar sobre `patch` é que ele chama a `handle_params/3`. Vamos criar este callback para nossa LiveView:

```elixir
def handle_params(params, _uri, socket) do
  case socket.assigns.live_action do
    :edit ->
      %{"id" => id} = params
      product = Catalog.get_product!(id)
      {:noreply, assign(socket, product: product)}

    :index ->
      {:noreply, assign(socket, product: nil)}
  end
end
```

Bem parecido como fizemos na aula anterior nós apenas verificados no valor de `socket.assigns.live_action` para definir o que fazer. No caso de edição nós precisamos saber sobre o produto que será editado portanto recebemos do `params` o `id` do produto (que vem do URL) e fazemos assign do seu valor. Em caso da action de `:index` podemos apenas definir o assign `product` como `nil`.

Se você também lembra da aula anterior, nós podemos simplificar este `case` criando uma nova função!

```elixir
def handle_params(params, _uri, socket) do
  {:noreply, apply_action(socket, socket.assigns.live_action, params)}
end

defp apply_action(socket, :edit, %{"id" => id}) do
  product = Catalog.get_product!(id)
  assign(socket, product: product)
end

defp apply_action(socket, :index, _params) do
  assign(socket, product: nil)
end
```

Agora nosso `handle_params/3` ficou bem mais legível e esta convenção de criar uma função privada `apply_action/3` é muito comum em projetos Phoenix.

### Adicionando o modal

No momento, clicar em Quick Edit redireciona você corretamente para a rota nova porém nada novo aparece na sua tela. Vamos adicionar o Live Component de formulário. Crie um `alias SuperStoreWeb.ProductLive.FormComponent` e adicione o seguinte código no final de sua `render/1`.

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  # ...
  alias SuperStoreWeb.ProductLive.FormComponent

  def render(assigns) do
    ~H"""
    # ...

    <.modal :if={@live_action == :edit} id="product-modal" show on_cancel={JS.patch(~p"/")}>
      <.live_component
        module={FormComponent}
        id="quick-edit-form"
        product={@product}
        action={@live_action}
      >
        <h1>Editing a product</h1>
      </.live_component>
    </.modal>
    """
  end
end
```

A magia acontece no atributo especial `:if`. Se a `@live_action` for `:edit` o modal aparece. Se o modal for fechado a propriedade `on_cancel` define que o usuário deverá ser redirecionado para a página inicial.

### Problemas de redirecionamento

A essa altura seu formulário funciona corretamente. Use o Quick Edit para editar qualquer elemento. Opa? Você foi redirecionado para a página de editar produto?

Isso acontece pois no nosso `ProductLive.FormComponent` definimos que após editar um produto vamos direto para a página de edição. Para evitar isso podemos introduzir um novo assign opcional chamado `patch`.

Dentro da sua `ProductLive.Index` atualize o código do seu modal para:

```elixir
~H"""
...

<.modal :if={@live_action == :edit} id="product-modal" show on_cancel={JS.patch(~p"/")}>
  <.live_component
    module={FormComponent}
    id="quick-edit-form"
    product={@product}
    action={@live_action}
    patch={~p"/"}
  >
    <h1>Editing a product</h1>
  </.live_component>
</.modal>
"""
```

No seu `ProductLive.FormComponent` procure por `save_product` no caso `:edit` e modifique o código para:

```elixir
defp save_product(socket, :edit, product_params) do
  case Catalog.update_product(socket.assigns.product, product_params) do
    {:ok, product} ->
      socket =
        socket
        |> put_flash(:info, "Product updated successfully")

      socket =
        if patch = socket.assigns[:patch] do
          push_patch(socket, to: patch)
        else
          push_navigate(socket, to: ~p"/products/#{product.id}/edit")
        end

      {:noreply, socket}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end
```

Como você pode notar um `if patch = socket.assigns[:patch] do` foi adicionado. Usamos a sintaxe de pegar um dado dinâmico `socket.assigns[:patch]` pois ela funciona mesmo se o valor não for definido. Se o valor não for definido, vamos para a cláusula else.

Neste momento sua funcionalidade de Quick Edit deve funcionar completamente!

## Criação de produto via modal

Agora que criamos o caso do modal de edição nós estamos quase prontos para fazer o mesmo com o modal para criar um produto de uma maneira rápida. Vamos experimentar!

### Modificando o router

Seu router no momento terá 3 rotas apontando para a `ProductLive.Index`, cada uma com uma live action diferente. Isto é completamente normal!

```elixir
live "/", ProductLive.Index, :index
live "/:id/edit", ProductLive.Index, :edit
live "/new", ProductLive.Index, :new # nova
```

### Melhorando a `apply_action/3`

Lembra que usamos uma função nova privada para tratar live actions diferentes chamadas `apply_action/3`? Isso facilita imensamente criarmos um novo caso. Adicione um `alias SuperStore.Catalog.Product` e mais uma cláusula a sua função do seguinte modo:

```elixir
defmodule SuperStoreWeb.ProductLive.Index do
  # ...
  alias SuperStore.Catalog.Product

  # ...

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Catalog.get_product!(id)
    assign(socket, product: product)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, product: nil)
  end

  defp apply_action(socket, :new, _new) do
    product = %Product{}
    assign(socket, product: product)
  end

  # ...
end
```

O último caso do `apply_action/3` trata o caso `:new` e apenas diz que o assign `@product` é um produto vazio.

### Atualizando a `render/1`

Precisamos de duas coisas: atualizar o link do botão de criar produto e atualizar o `:if` do `<.modal>`.

```elixir
# ...

def render(assigns) do
  ~H"""
  <.header>
    Listing Products
    <:actions>
      <.link patch={~p"/new"}>
        <.button>New Product</.button>
      </.link>
    </:actions>
  </.header>

  # ...

  <.modal :if={@live_action in [:edit, :new]} id="product-modal" show on_cancel={JS.patch(~p"/")}>
    <.live_component
      module={FormComponent}
      id="quick-edit-form"
      product={@product}
      action={@live_action}
      patch={~p"/"}
    >
      <h1>Editing a product</h1>
    </.live_component>
  </.modal>
  """
end
```

Agora o botão faz um `patch` para `/new`. Nosso modal agora trata tanto `:edit` quanto `:new` em live actions.

Pronto! Você tem tanto a funcionalidade de edição rápida quanto a funcionalidade de criação rápida!

### Apagando código morto

Se você parar para pensar, não há mais necessidade de termos uma página de criação de produto dedicada. Nossa `ProductLive.New` virou código morto!

Podemos deletar o arquivo `lib/super_store_web/live/product_live/new.ex` e remover do nosso router `live "/products/new", ProductLive.New, :new`.

### Código final

Agora que aplicamos o modal nós possuímos em nosso sitema:

- Uma página inicial que lista produtos e tem modal de criação e edição de produtos além da opção de deletar produtos.
- Uma página dedicada para mostrar o produto.
- Uma página dedicada de editar o produto.

Você pode optar por remover a página de edição dedicada e deixar a `ProductLive.Index` ser o único lugar em que você edita o produto ou até mesmo usar o modal de edição rápida na página que mostra o produto, fica a seu critério.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout modal-form-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch modal-form-done`.

## Resumindo!

- O componente `<.modal>` pode ser útil como forma simples de trazer formulários.
- Uma vez que nossos formulários são um Live Component, usar eles em novos lugares é extremamente simples, sem medo de repetir código.
- Podemos usar rotas para definir quando um modal deve abrir.
- Usando Live Actions diferentes podemos definir diferentes casos de `handle_params/3` para uma mesma LiveView como fizemos para que nossa `ProductLive.Index` pudesse funcionar tanto para listar, editar e criar produtos.
- Para organizar múltiplas live actions em uma mesma LiveView optamos por criar uma função `apply_action/3` para cada action apenas por questões de organização.
- Conseguimos renderizar HEEx opcionalmente checando o assign `@live_action` como fizemos para apenas mostrar o modal em `:new` e `:edit`.
