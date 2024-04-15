%{
title: "Validando componentes",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Facilitando a manutenção de um projeto para o futuro",
previous_page_id: "function-component",
next_page_id: "components-from-other-modules"
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

No exemplo acima não só removemos o `color="blue"` da nossa render function como também adicionamos mais um exemplo na documentação onde podemos usar o botão sem passar um `color`. Vale mencionar que no `attr/3` as opções `default` e `required` são mutualmente exclusivas: ou você tem um padrão para caso não seja passado ou você pede que quem use este componente sempre passe um valor.

## Usando `attr/3` para definir possíveis valores

A função `attr/3` também contem outras duas propriedades mutualmente exclusivas: `examples` e `values`. Se for do seu interesse que só algumas cores sejam aceitas pelo seu componente, use o `values` do seguinte modo: `attr :color, :string, default: "blue", values: ~w(blue red yellow green)`. Se for do seu interesse não limitar a certos valores porém fornecer alguns exemplos, basta você trocar de `values` para `examples`. Vale mencionar que esta configuração não irá prevenir que os valores errados sejam usados em tempo de execução ele só irá ajudar lhe fornecendo warnings em tempo de compilação.

%{
title: ~H"O que é esse <code>`~w(x y z)`</code> aí?",
description: ~H"""
A <.link navigate="https://hexdocs.pm/elixir/1.16.2/Kernel.html#sigil_w/2" target="\_blank"><code>`sigil_w`</code></.link> serve como uma maneira simplificada de criar listas de string. Essencialmente <code>`["blue", "green"]`</code> podem ser escritos como <code>`~w(blue green)`</code>. Com esta sigil não precisamos de vírgula nem aspas, basta colocar os valores dentro do parênteses.
"""
} %% .callout

## Usando `attr/3` para definir classes

Nosso botão no momento não é bem customizável. Para poder receber classes novas precisamos criar um novo `attr`. Crie e execute um arquivo chamado `class_attr.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button class="text-red-500">Default</.button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.button>Save data</.button>
      <.button class="text-blue-500">Save data</.button>
      <.button color="red">Delete account</.button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Usando uma funcionalidade do HEEx comentada em uma aula anterior nós convertemos nosso atributo `class` para receber uma list. Como o valor padrão do assign `class` é `nil` ele será ignorado. Colocamos intencionalmente o `@class` como elemento final pois se houverem clases que alterem as mesmas propriedades CSS que as do componente a nova classe terá precedência.

## Múltiplas propriedades opcionais

Como você pode notar nosso botão no momento funciona apenas como `type="button"`. Se quisermos poder mudar o tipo para `"submit"` ou `"reset"` teríamos que criar um novo `attr`. Esse processo manual de criar um `attr` fica repetitivo muito rápido. Se você quiser apenas repassar os demais atributos vindos da utilização do componente o HEEx tem uma solução. Crie e execute um arquivo chamado `global_attrs.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button type="submit" style="color: red">Default</.button>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Save data</.button>
      <.button type="submit" class="text-blue-500">Save data</.button>
      <.button type="submit" color="red">Delete account</.button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  attr :rest, :global, default: %{type: "button"}, include: ~w(type style)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
```

Geralmente chamado de `:rest` (porém qualquer nome serve), podemos definir usando `attr/3` um atributo do tipo `:global`. Opcionalmente, podemos adicionar o `default` dele como um mapa com todas as propriedades padrão. Também opcionalmente podemos dizer quais propriedades serão aceitas pelo nosso atributo global, neste caso, `type="..."` e `style="..."`.

## Resumindo!

- Você pode usar `@doc` para documentar seu componente e mostrar exemplos.
- Usando `attr/3` você pode documentar e aprimorar seu componente:
  - Você pode definir um valor como `required`.
  - Você pode definir um valor padrão caso algo não seja passado usando `default`.
  - Você pode limitar os possíveis valores usando `values`.
  - Você pode exemplificar os possíveis valores usando `examples`.
  - Você pode capturar todas as propriedades extras com um `attr` do tipo `:global`.
