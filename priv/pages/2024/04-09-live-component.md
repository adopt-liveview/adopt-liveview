%{
title: "Live Component",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "Como reusar lógica em componentes",
previous_page_id: "form-component",
next_page_id: "modal-form",
}

---

Na aula anterior aprendemos como reutilizar código HEEx usando componentes. Todavia, até então nunca vimos nenhum caso em que conseguimos reutilizar código de callbacks em uma LiveView. Para isto iremos aprender uma nova parte importante do LiveView: Live Components.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/refactoring-crud.git --branch form-component-done`</code>.
"""
} %% .callout

## O que é um Live Component?

Até então conversamos apenas sobre componentes funcionais. Eles nos possibilitaram facilitar muito nosso código por prevenir que repetíssemos HTML e facilitou a manutenção de nosso código no futuro. Sua limitação porém é que estes não tem qualquer relacionamento com lógica de negócio.

Já Live Components trazem não só as vantagens de componentes funcionais como eles também podem gerenciar seu próprio estado local. Pense em Live Components como se fossem LiveViews que podem ficar dentro de outras LiveViews.

## Convertendo nosso código atual para Live Component

Vamos começar por converter o formulário de novo produto para Live Component. Abra seu `ProductLive.FormComponent` e edite ele para:

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <%= render_slot(@inner_block) %>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <.button type="submit">Send</.button>
      </.form>
    </div>
    """
  end
end
```

Não houveram grandes mudanças aqui além de termos removidos os `attr` e `slot`, removido o assign `@rest` e o principal: mudamos no topo de `use SuperStoreWeb, :html` para `use SuperStoreWeb, :live_component`. Com isso já podemos aplicar o Live Component.

### Usando um Live Component

Vá até seu `ProductLive.New` e edite seu HEEx do formulário para:

```elixir
~H"""
...
<.live_component
  module={FormComponent}
  id="new-form"
>
  <h1>Creating a product</h1>
</.live_component>
"""
```

Para usar um Live Component devemos usar o component `<.live_component>` passando no mínimo o `module` e `id` como parâmetros. No momento ele não faz nada. Vamos voltar para o `ProductLive.FormComponent`.

### Inicializando o estado do `FormComponent`

No momento seu formulário de criação deve mostrar uma exceção. Isso acontece pois não inicializamos o `@form`. Vamos começar por aprender o callback de inicialização novo para Live Components: `update/2`:

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :live_component
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product

  def update(assigns, socket) do
    form =
      Product.changeset(%Product{})
      |> to_form()

    {:ok,
     socket
     |> assign(form: form)
     |> assign(assigns)}
  end

  # ...
end
```

O callback `update/2` de Live Components se parece muito com o `mount/3` de uma LiveView. Ele recebe os `assigns` passados no `<.live_component>` e o `socket`. Assim como no `mount/3` nós criamos o `form` e fazemos assign dele.

A principal diferença aqui está no fato de que nós pegamos os `assigns` recebidos no callback e fazemos `assign(assigns)` para que todos eles estejam disponíveis dentro do componente também. Ou seja, se você usar `<.live_component module{FormComponent} x={10} y={20}>`, dentro do seu Live Component `@x` e `@y` estarão disponíveis.

### Adicionando os eventos

```elixir
# ...

def handle_event("validate", %{"product" => product_params}, socket) do
  form =
    %Product{}
    |> Product.changeset(product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end

def handle_event("save", %{"product" => product_params}, socket) do
  case Catalog.create_product(product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product created successfully")
       |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end

def render(assigns) do
  ~H"""
  <div class="bg-grey-100">
    <.form
      for={@form}
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save"
      class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
    >
      <%= render_slot(@inner_block) %>
      <.input field={@form[:name]} placeholder="Name" />
      <.input field={@form[:description]} placeholder="Description" />

      <.button type="submit">Send</.button>
    </.form>
  </div>
  """
end
```

Como você pode notar a lógica toda de criação é uma cópia da original. Vale mencionar que adicionamos um `|> push_navigate(to: ~p"/products/")` para que quando o produto for criado o usuário seja enviado para a lista de produtos.

### `phx-target`

Em nossa `render/1` atualizamos nosso `<.form>` para adicionar os bindings de form porém um novo binding aparece: o `phx-target`. Para entender esse binding preciso revelar a você uma nova informação sobre Live Components: eles vivem num processo isolado.

Sabendo que um Live Component vive num processo seu você precisa deixar explícito que os eventos de formulário são tratados por ele e não pela Live View que o contém. Usando `phx-target={@myself}` o `<.form>` saberá para onde enviar eventos.

## Generalizando o componente

No momento o Live Component só sabe criar novos produtos. Veremos agora como generalizar ele para aceitar edição.

### Onde mudar o código?

Anotando as áreas que precisam mudar um pouco para que edição funcione:

1. O `update/2` deve saber quando inicializar o form com produto vazio ou um produto existente.
2. O `handle_event("validate", ...)` deve saber quando inicializar o form com produto vazio ou um produto existente.
3. O `handle_event("save", ...)` deve saber se deve usar `Catalog.create_product/1` ou `Catalog.update_product/2`.

Eis a sugestão: os tópicos 1 e 2 giram em torno de "saber o produto". Para novo, usaremos um produto vazio e para editar usamos o produto existente. Isso pode ser resolvido com um assign como `<.live_component module{FormComponent} product={...}>`.

Já o terceiro tópico depende de saber se é edição ou criação. Podemos resolver isso com um assign também como `<.live_component module{FormComponent} action={:new / :edit}>`. Além disso, podemos usar o assign automático `@live_action` que vem do router. Se a página for `:edit`, o `@live_action` será `:edit`. Isso simplifica as coisas!

### Atualizando nossas LiveViews

Na sua `ProductLive.New` atualize o HEEx para:

```elixir
~H"""
...
<.live_component module={FormComponent} id="new-form" product={%Product{}} action={@live_action}>
  <h1>Creating a product</h1>
</.live_component>
...
"""
```

Na sua `ProductLive.Edit` atualize o HEEx para:

```elixir
~H"""
...
<.live_component module={FormComponent} id={@product.id} product={@product} action={@live_action}>
  <h1>Editing a product</h1>
</.live_component>
...
"""
```

### Melhorando o `update/2`

Voltamos ao `FormComponent`. Como sabemos que o Live Component sempre receberá um `product` como assign podemos fazer:

```elixir
def update(%{product: product} = assigns, socket) do
  form =
    Product.changeset(product)
    |> to_form()

  {:ok,
   socket
   |> assign(form: form)
   |> assign(assigns)}
end
```

Além disso, como o `product` faz parte dos `assigns`, no futuro poderemos usar `socket.assigns.product`.

### Melhorando o `handle_event("validate", ...)`

```elixir
def handle_event("validate", %{"product" => product_params}, socket) do
  form =
    socket.assigns.product
    |> Product.changeset(product_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, form: form)}
end
```

Ao invés de usar diretamente `%Product{}` a única coisa que mudou aqui é que construímos o `form` usando `socket.assigns.form` que vem do nosso `<.live_component ... product={...}>`.

### Melhorando o `handle_event("save", ...)`

Neste momento iremos usar o `socket.assigns.action` para descobrir qual ação tomar:

```elixir
def handle_event("save", %{"product" => product_params}, socket) do
  case socket.assigns.action do
    :new ->
      case Catalog.create_product(product_params) do
        {:ok, product} ->
          {:noreply,
           socket
           |> put_flash(:info, "Product created successfully")
           |> push_navigate(to: ~p"/")}

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, form: form)}
      end

    :edit ->
      case Catalog.update_product(socket.assigns.product, product_params) do
        {:ok, product} ->
          {:noreply,
           socket
           |> put_flash(:info, "Product updated successfully")
           |> push_navigate(to: ~p"/products/#{product.id}/edit")}

        {:error, %Ecto.Changeset{} = changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, form: form)}
      end
  end
end
```

Como você pode notar a única coisa nova aqui é o `case` mais externo que checa o valor de `socket.assigns.action`. Porém nossa função ficou bem grande e com `case`s aninhados. Podemos melhorar isso criando uma outra função!

```elixir
def handle_event("save", %{"product" => product_params}, socket) do
  save_product(socket, socket.assigns.action, product_params)
end

defp save_product(socket, :edit, product_params) do
  case Catalog.update_product(socket.assigns.product, product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product updated successfully")
       |> push_navigate(to: ~p"/products/#{product.id}/edit")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end

defp save_product(socket, :new, product_params) do
  case Catalog.create_product(product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product created successfully")
       |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      form = to_form(changeset)
      {:noreply, assign(socket, form: form)}
  end
end
```

Agora nosso evento de `"save"` simplesmente repassa valores para uma função privada nova chamada `save_product/3`. Esta função utiliza pattern matching para verificar o segundo argumento se é `:edit` ou `:new` e aplica as funções necessárias.

## Revisando o código final

Vamos dar uma olhada em cada parte do código que mexemos nesta aula para ver o produto final

### `ProductLive.FormComponent`

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :live_component
  alias SuperStore.Catalog
  alias SuperStore.Catalog.Product

  def update(%{product: product} = assigns, socket) do
    form =
      Product.changeset(product)
      |> to_form()

    {:ok,
     socket
     |> assign(form: form)
     |> assign(assigns)}
  end

  def handle_event("validate", %{"product" => product_params}, socket) do
    form =
      socket.assigns.product
      |> Product.changeset(product_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_navigate(to: ~p"/products/#{product.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)
        {:noreply, assign(socket, form: form)}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Catalog.create_product(product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset)
        {:noreply, assign(socket, form: form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <%= render_slot(@inner_block) %>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <.button type="submit">Send</.button>
      </.form>
    </div>
    """
  end
end
```

### `ProductLive.New`

```elixir
defmodule SuperStoreWeb.ProductLive.New do
  use SuperStoreWeb, :live_view
  import SuperStoreWeb.CoreComponents
  alias SuperStore.Catalog.Product
  alias SuperStoreWeb.ProductLive.FormComponent

  def render(assigns) do
    ~H"""
    <.header>
      New Product
      <:subtitle>Use this form to create product records in your database.</:subtitle>
    </.header>

    <.live_component module={FormComponent} id="new-form" product={%Product{}} action={@live_action}>
      <h1>Creating a product</h1>
    </.live_component>

    <.back navigate={~p"/"}>Back to products</.back>
    """
  end
end
```

### `ProductLive.Edit`

```elixir
defmodule SuperStoreWeb.ProductLive.Edit do
  use SuperStoreWeb, :live_view
  alias SuperStore.Catalog
  alias SuperStoreWeb.ProductLive.FormComponent

  def mount(%{"id" => id}, _session, socket) do
    product = Catalog.get_product!(id)
    {:ok, assign(socket, product: product)}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Editing Product <%= @product.id %>
      <:subtitle>Use this form to edit product records in your database.</:subtitle>
    </.header>

    <.live_component module={FormComponent} id={@product.id} product={@product} action={@live_action}>
      <h1>Editing a product</h1>
    </.live_component>

    <.back navigate={~p"/products/#{@product}"}>Back to product</.back>
    """
  end
end
```

### Conclusão

Como podemos notar, as LiveView ficaram bem enxutas. Não há código de formulário repetido. Com esta aula aprendemos como reutilizar lógica de negócio em mais de uma LiveView usando Live Components!

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout live-component-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch live-component-done`.

## Resumindo!

- Live Components são componentes capazes de gerenciar seu próprio estado. Eles também são uma excelente arma para evitar duplicação de código.
- Para criar um Live Component você usa no topo do módulo `use SeuProjetoWeb, :live_component`.
- Para usar um Live Component você usa o componente `<.live_component module={} id="algum-id">`.
- Você pode usar o callback `update/2` de um Live Component para definir o estado inicial.
- Você pode usar `assign(socket, assigns)` dentro do `update/2` para salvar no componente todos os assigns passados na chamada `<.live_component x={10} y={20} z={30}>`.
- Live Components vivem em processos separados da LiveView que o chamou.
- Quando criar eventos em Live Componentes você pode usar o `phx-target={@myself}` para deixar claro que o evento será tratado por este componente e não a LiveView que o contém.
