%{
title: "Documentando componentes",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Facilitando a manutenção de um projeto para o futuro"
}

---

Elixir é uma linguagem que desde cedo trouxe uma ferramental incrível para documentação chamada ExDoc. Seguindo no mesmo rumo o time do Phoenix tornou documentar componentes LiveView não apenas simples mas também capaz de adicionar superpoderes a sua LiveView. Crie e execute `basic_component_doc.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button color="blue">Welcome</.button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.button color="red">Delete account</.button>
  """
  attr :color, :string, required: true
  slot :inner_block, required: true

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

A primeira forma de documentar seu componente é usar a tag `@doc` do ExDoc onde você explica brevemente o que o componente faz e adiciona um ou alguns exemplos.

A próxima novidade é específica do Phoenix. Você pode usar a função [`attr/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3) para documentar o componente abaixo dela. Cada uso de `attr` define um atributo a ser recebido. Uma funcionalidade extra de usar `attr/3` é que em projetos Phoenix [o compilador irá validar](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3-compile-time-validations) se não há atributos a mais, faltando ou incorretos! Por simplesmente documentar seu componente você já ganha uma validação extra.

%{
title: ~H"Validação de <code>`attr/3`</code> e LiveView Playground",
type: :warning,
description: ~H"""
Até o momento o LiveView Playground não consegue checar a validade dos componentes usando <code>`attr/3`</code>. De todo modo, a recomendação é que você continue usando elas por padrão pois em projetos Phoenix reais isso será um super poder para sua base de código.
"""
} %% .callout

Por fim também documentamos que nosso componente utiliza slots usando o [`slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/2). Similar ao `attr/3` o `slot/2` também [valida seus componentes em tempo de compilação](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/3-compile-time-validations) e serve para documentar seu código.

## Usando `attr/3` para gerar valores padrão

No nosso exemplo acima nós obrigatoriamente devemos passar o atributo color. Se você já trabalhou com outras bibliotecas de estilo deve notar que sempre existe um estilo padrão quando você não escolhe a cor em específico. Isso é útil para ter uma cor padrão para o sistema. Você pode fazer isso definindo via `attr/3` o `default: "blue"`.

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button>Default</.button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.button>Save data</.button>
      <.button color="red">Delete account</.button>
  """
  attr :color, :string, default: "blue"
  slot :inner_block, required: true

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

No exemplo acima não só removemos o `color="blue"` da nossa render function como também adicionamos mais um exemplo na documentação onde podemos usar o botão sem passar um `color`. Vale mencionar que no `attr/3` as opções `default` e `requred` são mutualmente exclusivas: ou você tem um padrão para caso não seja passado ou você pede que quem use este componente sempre passe um valor.

## Usando `attr/3` para definir possíveis valores

A função `attr/3` também contem outras duas propriedades mutualmente exclusivas: `examples` e `values`. Se for do seu interesse que só algumas cores sejam aceitas pelo seu componente, use o `values` do seguinte modo: `attr :color, :string, default: "blue", values: ["blue", "red", "yellow", "green"]`. Se for do seu interesse não limitar a certos valores porém fornecer alguns exemplos, basta você trocar de `values` para `examples`. Vale mencionar que esta configuração não irá prevenir que os valores errados sejam usados em tempo de execução ele só irá ajudar lhe fornecendo warnings em tempo de compilação.

## Usando `attr/3` para definir classes

TODO
