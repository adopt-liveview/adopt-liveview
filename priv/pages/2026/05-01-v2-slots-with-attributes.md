%{
title: "Slots com atributos",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Como customizar slots com atributos",
previous_page_id: "v2-multiple-slots",
next_page_id: "v2-lists-with-slots"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch multiple-slots-done`</code>.
"""
} %% .callout

Na aula anterior usamos o componente `<.hero>` duas vezes. Digamos que na página inicial gostaríamos que o título fosse mais chamativo. Como passamos atributos para slots?

## Entendendo de verdade o que são slots

Para entender o que vamos fazer, primeiro você precisa entender como os slots funcionam internamente. Você já deve ter percebido que, como renderizamos slots usando assigns `@nome_do_slot`, isso significa que slots nada mais são do que assigns especiais. Todo `@nome_do_slot` é necessariamente uma lista. Se você for até o seu componente e usar `{inspect(@nome_do_slot)}` verá algo como:

```elixir
[%{inner_block: #Function<2.32079264/2 in MyappWeb.PageLive.render/1>, __slot__: :slot_name}]
```

Secretamente, slots são listas de mapas que contêm uma função de renderização HEEx na propriedade `__inner_block__` e o nome do slot na propriedade `__slot__`. Dito isso, nada impede você de usar o mesmo slot mais de uma vez no mesmo componente.

```heex
<.hero>
  <:title class="text-red-500">IndexLive</:title>
  <:title class="text-red-500">IndexLive</:title>
  <:subtitle>Welcome to my personal website!</:subtitle>
</.hero>
```

No exemplo acima, ao inspecionar o slot `@title` veremos:

```elixir
[%{inner_block: #Function<2.32079264/2 in MyappWeb.PageLive.render/1>, __slot__: :title},
%{inner_block: #Function<3.32079264/2 in MyappWeb.PageLive.render/1>, __slot__: :title}]
```

## Renderizando atributos com slots

Por que passamos por toda essa sessão de entendimento sobre slots serem listas de mapas em Elixir se nosso objetivo é renderizar classes do slot? Simples: se slots são listas, podemos fazer loops e, se cada slot é um mapa, podemos extrair propriedades deles!

Comece atualizando o `my_core_components.ex` para adicionar um atributo `class` ao slot `:title` e iterar sobre ele no template:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :title do
    attr :class, :string
  end

  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 :for={title_slot <- @title} class={["text-4xl font-bold", Map.get(title_slot, :class)]}>
          {render_slot(title_slot)}
        </h1>
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

Agora atualize seu `page_live.ex` para passar uma `class` ao slot `:title`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.hero>
      <:title class="text-red-500">IndexLive</:title>
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

E mantenha o `other_live.ex` como está — ele usa o slot sem uma classe, o que é perfeitamente válido:

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

Nosso slot ganhou algo novo na sua definição! Usando um bloco `do` podemos declarar quais atributos são importantes para aquele slot específico. Neste caso, apenas `class`.

Além disso, mudamos a forma de renderizar o slot para usar um loop `:for={title_slot <- @title}` para que possamos olhar para cada uso de `<:title>` individualmente e obter suas classes. Dentro do atributo `class` usamos uma lista para poder aplicar os atributos opcionais que podemos extrair com `Map.get(title_slot, :class)` (que será `nil` por padrão, resultando em nenhuma classe sendo aplicada). Por fim, dentro do nosso loop modificamos o uso de `render_slot/2` para que use a variável atual do loop `{render_slot(title_slot)}`.

Ótimo! Agora seus slots podem ter atributos. Conseguimos resolver o problema original: na página inicial gostaríamos que o título do slot tivesse um atributo diferente da outra página!

## Resumindo!

- Cada slot é na verdade uma lista de assigns do tipo mapa.
- Slots podem receber atributos e podemos documentar isso usando `slot/2` com um bloco `do`.
- Para acessar atributos de slots precisamos iterar sobre `@nome_do_slot` e então usar `Map.get(item_do_loop, :nome_do_atributo)`.