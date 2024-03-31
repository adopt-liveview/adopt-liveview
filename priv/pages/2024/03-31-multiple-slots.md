%{
title: "Múltiplos slots",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Um component pode ter mais de um slot"
}

---

Vamos recapitular a solução que usamos na aula anterior para o componente Hero:

```elixir
# ...
slot :inner_block, required: true

def hero(assigns) do
  ~H"""
  <div class="bg-gray-800 text-white py-20">
    <div class="container mx-auto text-center">
      <h1 class="text-4xl font-bold"><%= render_slot(@inner_block) %></h1>
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

Usamos o slot `@inner_block` para renderizar o texto principal da página porém deixamos dois textos repetidos tanto na página inicial como na LiveView `/other`. Isso gera mais confusão ainda pois, se você já estiver nesta página não há necessidade de você ver este link.

## Slots customizados

Por padrão todo componente terá um slot `@inner_block` se houver algum HTML dentro de sua tag. Todavia, você também pode adicionar mais slots conforme necessário. Crie e execute `custom_slots.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CustomRouter do
  use LiveviewPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/other", OtherPageLive, :index
  end
end

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  slot :title
  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold"><%= render_slot(@title) %></h1>
        <p class="mt-4 text-lg"><%= render_slot(@subtitle) %></p>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>
      <:title>IndexLive</:title>
      <:subtitle>Welcometo my personal website!</:subtitle>
      <.link
        class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
        navigate={~p"/other"}
      >
        Get Started
      </.link>
    </.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

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

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
```

A primeira modificação que fizemos foi adicionar dois novos `slot` na definição do nosso componente. Para deixar as coisas mais claras usamos os nomes `:title` e `:subtitle` para os novos slots.

A utilização de slots customizados é muito similar a sintaxe de componentes exceto que você deve usar `:`. Quando colocamos texto em `<:meu_slot>Abc</:meu_slot>` o código HEEx dentro dele irá ser enviado para este slot nomeado. Qualquer dado que não estiver dentro de um slot nomeado irá ser jogado no slot `@inner_block`.

A função [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) consegue entender quando não há nada no slot. Na view OtherPageLive não adicionamos nada fora de slots nomeados e mesmo assim não houveram problemas no código.

## Resumindo!

- Componentes podem ter mais de um slot
- Slots nomeados podem ser usados como `<:nome>Conteúdo</:nome>` e renderizados como `<% render_slot(@nome) %>`.
- Qualquer HEEx fora de slots nomeados cai no slot `@inner_block`.
