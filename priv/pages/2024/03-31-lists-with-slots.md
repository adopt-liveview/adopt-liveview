%{
title: "Renderizando listas com slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Usando slots para facilitar loops",
previous_page_id: "slots-with-attributes",
next_page_id: "forms"
}

---

Imagine que você está construindo uma aplicação que lista termos de boxing. Sua implementação inicial se parece muito como o código abaixo:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

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
          <dt class="text-lg font-semibold"><%= item.term %></dt>
          <dd class="text-gray-600"><%= item.definition %></dd>
        </div>
      </div>
    </dl>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Até aqui nada que você não tenha visto. Um assign para definir a lista de termos, um loop usando o atributo especial `:for` e cada item sendo renderizado. Porém, devido às aulas anteriores, você nota que você poderia simplificar um pouco mais esse código gerando um componente para esconder todas essas classes e, ao mesmo tempo, ter uma reusabilidade maior no seu `<dl>`.

## Misturando slots e listas

Até então nossos slots só renderizavam um único elemento. Seja um título ou um subtítulo, não havia nenhum loop envolvido. Vamos aprender como combinar listas e slots. Crie e execute um arquivo chamado `rendering_slot_list.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  attr :terms, :list, required: true
  slot :dt, required: true
  slot :dd, required: true

  def dl(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold"><%= render_slot(@dt, item) %></dt>
          <dd class="text-gray-600"><%= render_slot(@dd, item) %></dd>
        </div>
      </div>
    </dl>
    """
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

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
      <:dt :let={item}><%= item.term %></:dt>
      <:dd :let={item}><%= item.definition %></:dd>
    </.dl>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Mais uma vez usando a ideia de `CoreComponents` criamos um componente chamado `<.dl>` para deixar claro que esta é a nossa versão da tag HTML `<dl>`. Também escolhemos o nome dos nossos slots de modo a imitar o HTML: `<:dt>` (description term) e `<:dd>` (description detail).

O componente em sí não é muito diferente do que você já viu anteriormente. Usamos um loop com `:for` e para cada elemento nós usamos a função `render_slot/2`. A diferença é que desta vez passamos um segundo argumento para essa função: o item atual do loop.

Quando um segundo argumento é passado para o `render_slot/2`, na utilização do slot podemos usar o atributo especial `:let={var}` para armazenar o elemento atual em `var`. Deste modo, conseguimos simplificar um componente que trabalha com loops e tornamos nossa `render/1` da LiveView extremamente enxuta.

## Resumindo!

- Você pode simplificar loops criando componentes.
- Slots podem receber variáveis de loop passando elas no segundo argumento de `render_slot/2` e recebendo no slot com `:let={nome_da_var}`.
- Usar slots e componentes contribui em deixar o código das suas LiveViews mais enxutos.
