%{
title: "Documentando componentes",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Facilitando a manutenção do projeto no futuro",
previous_page_id: "v2-function-component",
next_page_id: "v2-components-from-other-modules"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nessa página, pode ficar confuso porque é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por aqui, você pode clonar a versão inicial desta aula com o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch function-component-done`</code>.
"""
} %% .callout

O Elixir é uma linguagem que desde cedo trouxe uma incrível ferramenta de documentação chamada ExDoc. O time do Phoenix seguiu a mesma direção e tornou a documentação de componentes LiveView não apenas simples, mas também capaz de adicionar superpoderes ao seu LiveView. Atualize seu `page_live.ex` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button color="blue">Welcome</.my_button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.my_button color="red">Delete account</.my_button>
  """
  attr :color, :string, required: true
  slot :inner_block, required: true

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

A primeira forma de documentar seu componente é usar a tag `@doc` do ExDoc, onde você explica brevemente o que o componente faz e adiciona um ou mais exemplos.

As próximas funcionalidades são específicas do Phoenix. Você pode usar a macro [`attr/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3) para documentar o componente logo abaixo da sua chamada. Cada uso de `attr` define um atributo a ser recebido. Uma funcionalidade extra de usar `attr/3` é que em projetos Phoenix [o compilador irá validar](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3-compile-time-validations) que não há atributos extras, faltando ou incorretos! Simplesmente documentando seu componente você já ganha validação extra.

Por último, mas não menos importante, também documentamos que nosso componente usa slots usando [`slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/2). Similar ao `attr/3`, o `slot/2` também [valida seus componentes em tempo de compilação](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#slot/3-compile-time-validations) e serve para documentar seu código.

## Usando `attr/3` para gerar valores padrão

No exemplo acima sempre devemos passar o atributo de cor. Se você já trabalhou com outras bibliotecas de componentes, vai notar que sempre existe um estilo padrão quando você não escolhe uma cor específica. É sempre útil ter uma cor padrão para o seu design system. Você pode fazer isso passando uma configuração via `attr/3` como `default: "blue"`.

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button>Default</.my_button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue"
  slot :inner_block, required: true

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

Não só removemos `color="blue"` da nossa função `render/1` como também adicionamos mais um exemplo na documentação onde podemos usar o botão sem passar um `color`. Vale mencionar que no `attr/3` as opções `default` e `required` são mutuamente exclusivas: ou você tem um valor padrão para caso não seja passado, ou pede que quem use este componente sempre passe um valor.

## Usando `attr/3` para definir valores possíveis

A função `attr/3` também possui outras duas propriedades mutuamente exclusivas: `examples` e `values`. Se for do seu interesse que apenas certas cores sejam aceitas pelo seu componente, use `values` do seguinte modo: `attr :color, :string, default: "blue", values: ~w(blue red yellow green)`. Se for do seu interesse não limitar a certos valores, mas fornecer alguns exemplos, basta trocar `values` por `examples`. Vale mencionar que esta configuração não irá prevenir o uso de valores errados em tempo de execução; ela só vai lhe ajudar fornecendo warnings em tempo de compilação.

%{
title: ~H"O que é esse <code>`~w(x y z)`</code> aí?",
description: ~H"""
A <.link navigate="https://hexdocs.pm/elixir/1.16.2/Kernel.html#sigil_w/2" target="\_blank"><code>`sigil_w`</code></.link> serve como uma forma simplificada de criar listas de strings. Essencialmente <code>`["blue", "green"]`</code> pode ser escrito como <code>`~w(blue green)`</code>. Com esse sigil não precisamos de vírgulas nem aspas, basta colocar os valores dentro dos parênteses.
"""
} %% .callout

## Usando `attr/3` para definir classes

A personalização do nosso botão está atualmente limitada. Para poder receber novas classes, precisamos criar um novo `attr`. Atualize `page_live.ex` para adicionar um atributo `class`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button class="text-red-500">Default</.my_button>
    """
  end

  @doc """
  Renders a button

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button class="text-blue-500">Save data</.my_button>
      <.my_button color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def my_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

Usando uma funcionalidade do HEEx mencionada em uma aula anterior, convertemos nosso atributo `class` para receber uma lista. Como o valor padrão do assign `class` é `nil`, ele será ignorado. Intencionalmente colocamos `@class` como elemento final porque, se houver classes que alterem as mesmas propriedades CSS das do componente, a nova classe poderá ter precedência.

## Múltiplas propriedades opcionais

Como você pode ver, nosso botão atualmente funciona apenas como `type="button"`. Se quiséssemos poder mudar o tipo para `"submit"` ou `"reset"`, teríamos que criar um novo `attr`. Esse processo manual de criar um `attr` fica repetitivo rapidamente. Se você quiser simplesmente repassar todos os outros atributos vindos do uso do componente, o HEEx tem uma solução. Atualize `page_live.ex` para suportar atributos globais:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <.my_button type="submit" style="color: red">Default</.my_button>
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

Geralmente chamado de `:rest` (mas qualquer nome serve), podemos definir um atributo do tipo `:global` usando `attr/3`. Também podemos adicionar seu `default` como um mapa com todas as propriedades padrão. Podemos ainda dizer quais propriedades serão aceitas pelo nosso atributo global; neste caso, `type="..."` e `style="..."`.

## Resumindo!

- Você pode usar `@doc` para documentar seu componente e mostrar exemplos.
- Usando `attr/3` você pode documentar e aprimorar seu componente:
  - Você pode definir um valor como `required`.
  - Você pode definir um valor padrão se algo não for passado usando `default`.
  - Você pode limitar os valores possíveis usando `values`.
  - Você pode exemplificar valores possíveis usando `examples`.
  - Você pode capturar todas as propriedades extras com um `attr` do tipo `:global`.