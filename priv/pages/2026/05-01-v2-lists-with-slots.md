%{
title: "Renderizando listas com slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Usando slots para fazer loops",
previous_page_id: "v2-slots-with-attributes",
next_page_id: "v2-forms"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch slots-with-attributes-done`</code>.
"""
} %% .callout

Imagine que você está construindo uma aplicação que lista termos de boxe. Sua implementação inicial se parece com o código abaixo:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    boxing_terms = [
      %{term: "Jab", definition: "A quick, straight punch thrown with the lead hand."},
      %{
        term: "Hook",
        definition:
          "A punch thrown in a circular motion targeting the side of the opponent's head or body."
      },
      %{
        term: "Cross",
        definition:
          "A powerful punch thrown with the rear hand across the body, traveling straight toward the opponent."
      }
    ]

    socket = assign(socket, boxing_terms: boxing_terms)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @boxing_terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold">{item.term}</dt>
          <dd class="text-gray-600">{item.definition}</dd>
        </div>
      </div>
    </dl>
    """
  end
end
```

Até agora, nada que você não tenha visto. Há um assign para definir a lista de termos, um loop usando o atributo especial `:for` e cada item está sendo renderizado. No entanto, por causa das aulas anteriores, você pode notar que poderia simplificar um pouco mais esse código criando um componente para esconder todas essas classes e, ao mesmo tempo, ter maior reusabilidade no seu `<dl>`.

## Combinando slots e listas

Até agora nossos slots apenas renderizavam um único elemento. Seja um título ou um subtítulo por uso de `<:nome_do_slot>`. Vamos aprender como combinar listas e slots. Comece adicionando um componente `dl` ao `my_core_components.ex`:

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

  attr :terms, :list, required: true
  slot :dt, required: true
  slot :dd, required: true

  def dl(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold">{render_slot(@dt, item)}</dt>
          <dd class="text-gray-600">{render_slot(@dd, item)}</dd>
        </div>
      </div>
    </dl>
    """
  end
end
```

Agora atualize seu `page_live.ex` para usar o novo componente `<.dl>`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    boxing_terms = [
      %{term: "Jab", definition: "A quick, straight punch thrown with the lead hand."},
      %{
        term: "Hook",
        definition:
          "A punch thrown in a circular motion targeting the side of the opponent's head or body."
      },
      %{
        term: "Cross",
        definition:
          "A powerful punch thrown with the rear hand across the body, traveling straight toward the opponent."
      }
    ]

    socket = assign(socket, boxing_terms: boxing_terms)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.dl terms={@boxing_terms}>
      <:dt :let={item}>{item.term}</:dt>
      <:dd :let={item}>{item.definition}</:dd>
    </.dl>
    """
  end
end
```

Usando novamente a ideia do `MyCoreComponents`, criamos um componente chamado `<.dl>` para deixar claro que esta é a nossa versão da tag HTML `<dl>`. Também escolhemos os nomes dos nossos slots para imitar o HTML: `<:dt>` (description term) e `<:dd>` (description detail).

O componente em si não é muito diferente do que você já viu antes. Usamos um loop com `:for`. Para cada elemento usamos a função `render_slot/2`. A diferença é que desta vez passamos um segundo argumento para essa função: o item atual do loop.

Quando um segundo argumento é passado para `render_slot/2`, podemos usar o atributo especial `:let={var}` na definição do slot para armazenar o elemento atual do loop em `var`. Dessa forma conseguimos simplificar um componente que trabalha com loops e tornamos a função `render/1` da nossa LiveView extremamente limpa.

## Resumindo!

- Você pode simplificar loops criando componentes.
- Slots podem receber variáveis de loop passando-as no segundo argumento de `render_slot/2` e recebendo-as no slot com `:let={nome_var}`.
- Usar slots e componentes deixa o código LiveView mais limpo.