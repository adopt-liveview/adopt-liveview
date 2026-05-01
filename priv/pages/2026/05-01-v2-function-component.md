%{
title: "Componentes funcionais",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Reutilizando código de maneira inteligente",
previous_page_id: "v2-navigate-to-the-same-route",
next_page_id: "v2-documenting-components"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch navigate-to-the-same-route-done`</code>.
"""
} %% .callout

Reutilizar código é a chave para construir um sistema de fácil manutenção. Em LiveView existe mais de uma maneira de você reutilizar código HEEx. Nas próximas aulas iremos explorar componentes funcionais para suas views e, passo a passo, entender como funcionam e suas possibilidades.

## Entendendo o problema

Atualize seu `page_live.ex` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

Usaremos classes do Tailwind CSS para estilização — o Phoenix já vem com Tailwind instalado por padrão.

Imagine que você está desenvolvendo um projeto grande e os estilos acima são usados para botões. Toda vez que precisar de um botão novo, teria que copiar e colar uma tonelada de classes. Ainda que fossem uma ou duas classes, sempre que precisar alterá-las, teria que mudar em todos os cantos da sua aplicação.

## Criando um componente funcional

Na aula anterior, vimos o componente `<.link>` sendo usado para renderizar nossos links. Para criar um componente novo, basta criar uma função com qualquer nome que receba uma única variável chamada assigns. Atualize seu `page_live.ex` para adicionar um componente `my_button`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button>Default</.my_button>
    <.my_button>Green</.my_button>
    <.my_button>Red</.my_button>
    <.my_button>Yellow</.my_button>
    """
  end

  def my_button(assigns) do
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
```

Assim como a `render/1`, temos outra função que retorna HEEx e recebe um argumento chamado assigns. Para usar um componente definido no arquivo atual, basta escrever `<.nome_do_componente></.nome_do_componente>` no seu HEEx.

%{
title: ~H"Por que chamá-lo de <code>.my_button</code> em vez de <code>.button</code>?",
description: ~H"""
Projetos Phoenix já vêm com alguns componentes comuns a muitas aplicações web, incluindo <code>.button</code>. Para evitar conflitos e focar no aprendizado, vamos nomear este e outros componentes das próximas aulas como <code>.my_component</code> até começarmos a usar os gerados por padrão.
"""
} %% .callout

%{
title: ~H"Por que os componentes têm um <code>.</code> no início?",
description: ~H"""
Como você já deve saber, existe uma tag HTML <code>`button`</code>. O <code>.</code> no início do componente deixa óbvio que essa tag faz referência a um componente funcional e não a uma tag HTML.
"""
} %% .callout

Diferente do nosso primeiro exemplo de código, você deve ter notado que todos os botões agora mostram o mesmo texto "Default", apesar de cada `<.my_button>` ter um texto diferente! Isso acontece pois, como criadores deste novo componente, devemos ensinar ao HEEx como renderizar o conteúdo do seu bloco interno. Atualize o `page_live.ex` para renderizar o bloco interno:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button>Default</.my_button>
    <.my_button>Green</.my_button>
    <.my_button>Red</.my_button>
    <.my_button>Yellow</.my_button>
    """
  end

  def my_button(assigns) do
    ~H"""
    <button
      type="button"
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800"
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

A única modificação no nosso `<.my_button>` foi adicionar a função [`render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#render_slot/2) passando um assign chamado `@inner_block`. Esse assign é definido automaticamente em componentes e é do tipo slot, como é chamado o HTML passado dentro do seu `<.componente>`. A partir de agora, qualquer coisa escrita dentro de `<.my_button>` será renderizada ali.

## Customizando componentes com atributos

Originalmente cada botão tinha sua própria cor, enquanto agora todos têm o mesmo estilo. Podemos customizar nossos botões usando assigns passados como atributos. Atualize o `page_live.ex` para suportar um atributo `color`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button color="blue">Default</.my_button>
    <.my_button color="green">Green</.my_button>
    <.my_button color="red">Red</.my_button>
    <.my_button color="yellow">Yellow</.my_button>
    """
  end

  def my_button(assigns) do
    ~H"""
    <button
      type="button"
      class={"text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800"}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

Agora cada uso do botão tem um assign de `color="..."` e podemos customizar nossos botões de maneira muito mais simples sem duplicar código.

## Resumindo!

- Você pode criar componentes nas suas LiveViews criando uma função que recebe `assigns` e retorna HEEx.
- Componentes e tags HTML são diferenciados pela presença de um `.` no início do nome para evitar conflitos.
- Em um componente você decide onde renderizar os nós filhos usando `render_slot(@inner_block)`.
- Com atributos, seus componentes podem reutilizar código de maneira eficiente.