%{
title: "Componentes funcionais",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Reutilizando código de maneira inteligente",
previous_page_id: "navigate-to-the-same-route",
next_page_id: "documenting-components"
}

---

Reutilizar código é a chave para construir um sistema de fácil manutenção. Em LiveView existe mais de uma maneira de você reutilizar código HEEx. Nesta e nas próximas aulas iremos explorar componentes funcionais para sua views e, passo a passo, entender como funcionam e suas possibilidades.

## Entendendo o problema

Crie e execute um arquivo `duplicated_code.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      Default
    </button>
    <button
      type="button"
      class="focus:outline-none text-white bg-green-700 hover:bg-green-800 focus:ring-4 focus:ring-green-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800"
    >
      Green
    </button>
    <button
      type="button"
      class="focus:outline-none text-white bg-red-700 hover:bg-red-800 focus:ring-4 focus:ring-red-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-red-600 dark:hover:bg-red-700 dark:focus:ring-red-900"
    >
      Red
    </button>
    <button
      type="button"
      class="focus:outline-none text-white bg-yellow-400 hover:bg-yellow-500 focus:ring-4 focus:ring-yellow-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:focus:ring-yellow-900"
    >
      Yellow
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Neste exemplo introduzimos a propriedade `scripts` no nosso `LiveviewPlayground.start/1` que aceita uma lista de scripts JavaScripts e adiciona no nosso HTML. Iremos utilizar Tailwind ao invés de escrever CSS diretamente pois hoje em dia o Phoenix já vem com esta biblioteca instalada.

Imagine que você está desenvolvendo um projeto grande e os estilos acima são usados para botões. Toda vez que você precisar de um botão novo você teria que copiar e colar uma tonelada de classes. Ainda que fossem uma ou duas classes, se um dia elas mudarem você teria que mudar elas em todos os cantos da sua aplicação.

## Criando um componente funcional

Em aulas anteriores vimos o componente `<.link>` sendo usado para renderizar nossos links. Para criar um componente novo basta você criar uma função com qualquer nome e que receba uma única variável chamada assigns. Crie e execute `first_component.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button>Default</.button>
    <.button>Green</.button>
    <.button>Red</.button>
    <.button>Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      Default
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Assim como a `render/1`, nós temos outra função que retorna HEEx e recebe um argumento chamado assigns. Para usar um componente definido no arquivo atual basta escrever no seu HEEx `<.nome_do_component></.nome_do_component>`.

%{
title: ~H"Por que os componentes tem um <code>.</code> no início?",
description: ~H"""
Escolhemos este exemplo justamente pois existe uma tag HTML <code>`button`</code>. O <code>.</code> no início do componente serve para deixar óbvio que esta tag faz referência a um componente funcional e não a uma tag HTML.
"""
} %% .callout

Diferente do nosso primeiro código você pode notar que todos os botões agora mostram o mesmo texto: "Default" apesar de cata `<.button>` possuir um texto diferente! Isso acontece pois no momento somos os criadores do componente novo, devemos ensinar ao HEEx one o conteúdo do bloco interno deve ser renderizado. Crie e execute `component_inner_block.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button>Default</.button>
    <.button>Green</.button>
    <.button>Red</.button>
    <.button>Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

A única modificação aconteceu no nosso `<.button>`. Adicionamos a função [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) passando um assign `@inner_block`. O assign em questão é definido automaticamente em componentes e ele é do tipo slot, como é chamado o HTML passados dentro do seu `<.componente>`. A partir de agora qualquer coisa enviada dentro do `<.button>` será renderizado alí.

## Customizando componentes com atributos

Originalmente cada botão tinha sua própria cor enquanto agora todos tem o mesmo estilo. Podemos customizar nossos botões usando assigns passados. Crie e execute `custom_button_colors.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button color="blue">Default</.button>
    <.button color="green">Green</.button>
    <.button color="red">Red</.button>
    <.button color="yellow">Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class={"text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800"}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Agora cada utilização do botão possui um assign de `color="..."` e podemos customizar nossos botões de maneira muito mais simples e sem duplicar código.

## Resumindo!

- Você pode criar componentes nas suas LiveViews se criar uma função que recebe `assigns` e retorna HEEx.
- Componentes e tags HTML são diferenciados pela presença de um `.` no início da tag para evitar conflitos.
- Em um componente você decide onde renderizar o slot filho usando `render_slot(@inner_block)`.
- Com atributos, seus componentes podem reutilizar código de maneira eficiente.
