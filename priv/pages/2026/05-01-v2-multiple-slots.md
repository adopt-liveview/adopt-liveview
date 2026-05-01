%{
title: "Múltiplos slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Um componente pode ter mais de um slot",
previous_page_id: "v2-components-from-other-modules",
next_page_id: "v2-slots-with-attributes"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta, você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch components-from-other-modules-done`</code>.
"""
} %% .callout

Vamos recapitular a solução que usamos na aula anterior para o componente Hero:

```elixir
# ...
slot :inner_block, required: true

def hero(assigns) do
  ~H"""
  <div class="bg-gray-800 text-white py-20">
    <div class="container mx-auto text-center">
      <h1 class="text-4xl font-bold">{render_slot(@inner_block)}</h1>
      <p class="mt-4 text-lg">My personal website</p>
      <.link
        class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
        navigate={~p"/other"}
      >
        Get Started
      </.link>
    </div>
  </div>
  """
end
# ...
```

Usamos o slot `@inner_block` para renderizar o texto principal da página, mas deixamos dois outros textos repetidos tanto na página inicial quanto na LiveView `/other`. Isso cria ainda mais confusão porque você já está nessa página — não faz sentido ver esse link lá.

## Slots personalizados

Por padrão, todo componente terá um slot `@inner_block` se houver qualquer HTML dentro da sua tag. No entanto, você também pode adicionar mais slots conforme necessário. Comece atualizando o `my_core_components.ex` para dar ao `hero` slots nomeados:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :title
  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold">{render_slot(@title)}</h1>
        <p class="mt-4 text-lg">{render_slot(@subtitle)}</p>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button type="submit" class="text-blue-500">Save data</.my_button>
      <.my_button type="submit" color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  attr :rest, :global, default: %{type: "button"}, include: ~w(type style)
  slot :inner_block, required: true

  def my_button(assigns) do
    ~H"""
    <button
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

Agora atualize seu `page_live.ex` para usar os novos slots:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.hero>
      <:title>IndexLive</:title>
      <:subtitle>Welcome to my personal website!</:subtitle>
      <.link
        class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
        navigate={~p"/other"}
      >
        Get Started
      </.link>
    </.hero>
    This is my homepage
    """
  end
end
```

E atualize o `other_live.ex` também:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.hero>
      <:title>OtherPageLive</:title>
      <:subtitle>You're on the first step!</:subtitle>
    </.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end
```

A primeira modificação que fizemos foi adicionar dois novos slots à definição do nosso componente. Para deixar as coisas mais claras, usamos os nomes `:title` e `:subtitle` para os novos slots.

Usar slots personalizados é bem similar à sintaxe de componentes, exceto que você precisa usar `:`. Quando colocamos texto em `<:my_slot>Abc</:my_slot>`, o código HEEx dentro dele será enviado para esse slot nomeado como `@my_slot`. Qualquer HTML fora de um slot nomeado será colocado no slot `@inner_block`.

A função [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) consegue entender quando não há nada no slot. Na view `OtherPageLive` não adicionamos nada fora dos slots nomeados e mesmo assim não houve nenhum problema no código.

## Resumindo!

- Componentes podem ter mais de um slot.
- Slots nomeados podem ser usados como `<:name>Conteúdo</:name>` e renderizados como `{render_slot(@name)}`.
- Qualquer HEEx fora de slots nomeados vai para o slot `@inner_block`.