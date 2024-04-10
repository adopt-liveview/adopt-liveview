%{
title: "Formulário DRY",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "Como evitar duplicação de código em formulário",
previous_page_id: "editing-data",
next_page_id: "live-component",
}

---

Uma boa prática em computação é evitar repetir código sempre que possível. O princípio DRY (Dont Repeat Yourself, não se repita) é um mantra que você pode carregar consigo durante seu dia-a-dia como desenvolvedor.

No final da seção anterior notamos que houve uma considerável repetição de código no formulário. Nesta seção vamos analisar como evitar isso uma aula de cada vez.

## Ponto de partida

Usaremos como base o código final da seção anterior. Caso você prefira começar do zero você pode clonar uma versão pronta para começar. Usando o seu terminal:

```
git clone https://github.com/adopt-liveview/refactoring-crud.git
cd refactoring-crud
mix setup
```

Com estes comandos você deve ter um projeto inicial em Phoenix. O comando `mix setup` não só instala como também compila as dependências para você. Uma vez que você tiver preparado o projeto e aberto sua IDE de preferência execute `mix phx.server` e vá ate [http://localhost:4000](http://localhost:4000) para ver a página inicial do seu projeto Phoenix.

Caso você não tenha feito a seção anterior deste curso esperamos que ao menos você tenha umas noções básicas de como formulários LiveView funcionam.

## Analisando os pedaços

Estaremos focando em dois arquivos: `ProductLive.New` (em `lib/super_store_web/live/product_live/new.ex`) `ProductLive.Edit` (em `lib/super_store_web/live/product_live/edit.ex`). Ambos possuem:

1. Uma função de `mount/3` que inicializa o formulário.
2. Um `handle_event("validate_product" ...)` muito parecidos.
3. Um `handle_event("create_product", ...)` (ou `"save_product"`) muito parecidos.
4. Um `<.form>` com os mesmos dados exceto o título do formulário em si.

No dia que precisarmos adicionar um novo campo teríamos que adicionar em ambos os arquivos. No dia que precisarmos adicionar alguma validação específica (exemplo: validar se o nome do produto é repetido) teríamos que fazer em ambos os formulários. Você consegue ver onde quero chegar?

### Diminuindo o escopo

Vamos começar resolvendo um problema menor.

> 4. Um `<.form>` com os mesmos dados exceto o título do formulário em si.

Conseguimos reusar o HEEx em dois arquivos diferentes? Sim, basta criarmos um componente!

## Refatorando

O primeiro passo de refatorar algo repetido é identificar o ponto de duplicação. No momento estamos focando apenas no código HEEx então olhando para ambos os formulários vemos uma similaridade em:

```elixir
# new.ex
~H"""
...
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
...
"""

# edit.ex
~H"""
...
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
...
"""
```

Muda apenas o `phx-submit` e o conteúdo do `h1`. Como os bindings `phx-change` e `phx-submit` são atributos podemos passar para o componente como assigns. Também iremos precisar passar o assign `@form`. Já o `h1` podemos simplesmente usar um `slot` posto que é um código HEEx.

### Introduzindo o `ProductLive.FormComponent`

Dentro da sua pasta `lib/super_store_web/live/product_live/` crie um arquivo `form_component.ex` com o seguinte código:

```elixir
defmodule SuperStoreWeb.ProductLive.FormComponent do
  use SuperStoreWeb, :html

  attr :form, Phoenix.HTML.Form
  attr :rest, :global, include: ~w(phx-change phx-submit)
  slot :inner_block

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form for={@form} class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24" {@rest}>
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

Note que no topo usamos `use SuperStoreWeb, :html` e não `:live_view`. Este arquivo não será uma LiveView, isto é, uma página. Apenas conterá um componente.

Usamos `attr` para receber o `:form`e usamos o `:rest` como `attr` `:global` para receber os bindings. Além disso o slot `:inner_block` para o HEEx do `<h1>`.

### Aplicando nas LiveViews

Na sua `ProductLive.New` adicione um `alias SuperStoreWeb.ProductLive.FormComponent` e vamos usar o componente:

```elixir
defmodule SuperStoreWeb.ProductLive.New do
  # ...
  alias SuperStoreWeb.ProductLive.FormComponent

  # ...

  def render(assigns) do
    ~H"""
    <.header>
      New Product
      <:subtitle>Use this form to create product records in your database.</:subtitle>
    </.header>

    <FormComponent.render form={@form} phx-change="validate_product" phx-submit="create_product">
      <h1>Creating a product</h1>
    </FormComponent.render>

    <.back navigate={~p"/"}>Back to products</.back>
    """
  end
end
```

Como o componente vem de outro arquivo usamos a sintaxe `<FormComponent.render ...>`. Como discutimos anteriormente passamos os atributos necessários.

De modo similar em nossa `ProductLive.Edit`:

```elixir
defmodule SuperStoreWeb.ProductLive.Edit do
  # ...
  alias SuperStoreWeb.ProductLive.FormComponent

  # ...

  def render(assigns) do
    ~H"""
    <.header>
      Editing Product <%= @product.id %>
      <:subtitle>Use this form to edit product records in your database.</:subtitle>
    </.header>

    <FormComponent.render form={@form} phx-change="validate_product" phx-submit="save_product">
      <h1>Editing a product</h1>
    </FormComponent.render>

    <.back navigate={~p"/products/#{@product}"}>Back to product</.back>
    """
  end
end
```

### Sucesso!

Com esta pequena modificação conseguimos centralizar o formulário em um único lugar. Futuras adições ao formulário afetarão as duas páginas sem precisarmos duplicar código.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout form-component-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/refactoring-crud.git --branch form-component-done`.

## Resumindo!

- Manter o código DRY facilita a manutenção dele no futuro.
- Quando você sentir necessidade de refatorar código para deixar ele mais enxuto analise os pontos de repetição.
- Se tiverem muitos pontos de repetição tente começar diminuindo o escopo para algo mais simples antes de seguir em frente.
- Para evitar repetição de código HEEx, criar um componente pode ser uma excelente opção.
