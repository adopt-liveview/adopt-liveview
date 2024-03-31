%{
title: "Slots com atributos",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Como customizar slots com atributos"
}

---

Em nossa aula anterior utilizamos o componente `<.hero>` duas vezes. Digamos que na página inicial gostaríamos de que o título fosse mais chamativo. Como passar atributos para slots?

## Entendendo de verdade o que são slots

Para entender o que estamos prestes a fazer você primeiro precisa entender como slots funcionam internamente. Você já deve ter notado que como nós renderizamos slot usando variáveis `@nome_do_slot` isso significa que slots não são nada mais que assigns especiais. Todo `@nome_do_slot` é obrigatoriamente uma lista. Se você for no seu componente e usar `<%= inspect(@nome_do_slot) %>` você verá algo como:

```elixir
[%{inner_block: #Function<2.32079264/2 in IndexLive.render/1>, __slot__: :nome_do_slot}]
```

Ou seja, secretamente slots são listas de mapas que contém uma função de renderizar HEEx na propriedade `__iner_block__` e o nome do slot na propriedade `__slot__`. Dito isso, nada impede de você usar o mesmo slot múltiplas vezes no mesmo componente.

```elixir
<.hero>
  <:title class="text-red-500">IndexLive</:title>
  <:title class="text-red-500">IndexLive</:title>
  <:subtitle>Welcometo my personal website!</:subtitle>
</.hero>
```

No exemplo acima, ao inspecionar o slot `@title` veremos:

```elixir
[%{inner_block: #Function<2.32079264/2 in IndexLive.render/1>, __slot__: :title},
%{inner_block: #Function<3.32079264/2 in IndexLive.render/1>, __slot__: :title}]
```

## Renderizando atributos de slot

Por que fizemos todo esse rodeio de entender que slots são listas de mapas em Elixir se nosso objetivo é renderizar classes de slots? Simples: se slots são listas, podemos fazer loops e, se cada slot é um mapa, podemos pegar propriedades deles!

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
          <%= render_slot(title_slot) %>
        </h1>
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
      <:title class="text-red-500">IndexLive</:title>
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

Nosso slot ganhou algo novo na sua definição! Usando um bloco `do` podemos declarar quais atributos são pertinentes a aquele slot em específico. Neste caso, apenas `class`.

Além disso, mudamos nossa forma de renderizar o slot para usar um loop `:for={title_slot <- @title}` de modo com que conseguimos olhar para cada utilização de `<:title>` individualmente para pegar suas classes. Dentro do atributo `class` usamos uma lista para poder aplicar os atributos opcionais que conseguirmos extrair usando `Map.get(title_slot, :class)` (que será `nil` por padrão, resultando em nenhuma classe sendo aplicada). Por fim, dentro do nosso loop modificamos a utilização do `render_slot/2` para que ele use a variável de loop atual `<%= render_slot(title_slot) %>`.

Excelente! Agora seus slots podem ter atributos especificamente neles. Conseguimos resolver o problema original: na página inicial gostaríamos que o slot title tivesse um atributo diferente da outra!

## Resumindo!

- Cada slot é na verdade um assign do tipo lista de mapas.
- Slots podem receber atributos e podemos documentar isso usando `slot/2` com um bloco `do`.
- Para acessar os atributos de slots precisamos fazer um loop no `@nome_do_slot`. Em seguida basta usar um `Map.get(item_do_loop, :nome_do_atributo)`.
