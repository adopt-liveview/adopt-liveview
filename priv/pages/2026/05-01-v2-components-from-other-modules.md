%{
title: "Componentes de outros módulos",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Como reutilizar componentes em mais de uma LiveView",
previous_page_id: "v2-documenting-components",
next_page_id: "v2-multiple-slots"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou direto nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta, você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch documenting-components-done`</code>.
"""
} %% .callout

Quando criamos um componente como uma função em uma LiveView, temos acesso a ele no nosso HEEx usando `<.function_name>`. Porém, se você precisar usá-lo em outra LiveView, também precisará escrever o nome do módulo. Abra e edite o módulo `OtherLive`:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <MyappWeb.PageLive.my_button color="blue">
      My other button
    </MyappWeb.PageLive.my_button>
    """
  end
end
```

Isso não é nada elegante. Poderíamos, talvez, usar `alias` para deixar nosso HEEx menos verboso:

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view
  alias MyappWeb.PageLive

  def render(assigns) do
    ~H"""
    <h1>OtherPageLive</h1>
    <PageLive.my_button color="blue">
      My other button
    </PageLive.my_button>
    """
  end
end
```

%{
title: ~H"<code>alias</code>",
description: ~H"""
Em Elixir você pode usar alias para simplificar referências a módulos aninhados. Em vez de escrever <code>MyApp.Deep.ModuleName.function</code> você pode fazer <code>alias MyApp.Deep.ModuleName</code> e depois escrever apenas <code>ModuleName.function</code>.
"""
} %% .callout

## Conhecendo o CoreComponents

Em projetos Phoenix, quando temos certos componentes que são úteis em várias partes do sistema, optamos por compartilhá-los em um módulo chamado CoreComponents e os importamos. Como o `CoreComponents` já existe, criaremos um `MyCoreComponents` para fins de aprendizado. Crie-o em `lib/myapp_web/components/my_core_components.ex`:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :inner_block, required: true

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 class="text-4xl font-bold">{render_slot(@inner_block)}</h1>
        <p class="mt-4 text-lg">My personal website</p>
        <.link
          class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded mr-2"
          navigate={~p"/"}
        >
          Homepage
        </.link>
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

Em seguida, atualize tanto a `PageLive` quanto a `OtherLive` desta forma:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view
  import MyappWeb.MyCoreComponents

  def render(assigns) do
    ~H"""
    <.hero>PageLive</.hero>
    <.my_button type="submit" style="color: red">Default</.my_button>
    """
  end
end
```

```elixir
defmodule MyappWeb.OtherPageLive do
  use MyappWeb, :live_view
  import MyappWeb.MyCoreComponents

  def render(assigns) do
    ~H"""
    <.hero>OtherPageLive</.hero>
    <my_button color="blue">
      My other button
    </my_button>
    """
  end
end

```

Desta vez também inserimos um componente `<.hero>` que foi usado para criar títulos bonitos para cada página. Em cada uma das nossas LiveViews usamos manualmente `import MyappWeb.MyCoreComponents`. Caso você esteja se perguntando, usamos `use Phoenix.Component` para termos acesso a coisas relacionadas ao HEEx, como o `sigil_H`. Também usamos `use MyappWeb, :verified_routes` para poder usar o `sigil_p` e escrever rotas como `~p"/"` e `~p"/other"` dentro do nosso componente `<.hero>`.

## Conhecendo o `MyappWeb.ex`

O ponto principal do `CoreComponents` (e no nosso caso do `MyCoreComponents`) é que esses componentes são tão importantes para toda a aplicação que são importados por padrão. Vamos fazer isso para o nosso módulo, assim como o Phoenix faz para o seu. Vá até `lib/myapp_web.ex`.

Este módulo é mágico. Ele usa invocações secretas conhecidas apenas pelos antigos como `macros`. Brincadeiras à parte, este módulo utiliza o mecanismo do Elixir de definir um macro secreto chamado `__using__` para que, sempre que alguém fizer `use MyappWeb`, esteja chamando `__using__` por baixo dos panos. Isso não importa muito para você, pois tudo que você precisa entender é que `use MyappWeb, :something` vai executar o que estiver dentro de `MyappWeb.something` em tempo de compilação!

* `use MyappWeb, :static_paths` mapeia para `def static_paths`
* `use MyappWeb, :router` mapeia para `def router`
* `use MyappWeb, :channel` mapeia para `def channel`
* `use MyappWeb, :controller` mapeia para `def controller`
* `use MyappWeb, :live_view` mapeia para `def live_view`
* `use MyappWeb, :live_component` mapeia para `def live_component`
* `use MyappWeb, :html` mapeia para `def html`
* `use MyappWeb, :verified_routes` mapeia para `def verified_routes`

Como você já deve ter percebido, fazemos `use MyappWeb, :live_view` em todas as nossas LiveViews e, dentro dele, o código de `html_helpers/0` é adicionado em tempo de compilação. Vamos adicionar o `MyCoreComponents` ao `html_helpers/0`:

```elixir
defp html_helpers do
  quote do
    # Translation
    use Gettext, backend: MyappWeb.Gettext

    # HTML escaping functionality
    import Phoenix.HTML
    # Core UI components
    import MyappWeb.CoreComponents
    import MyappWeb.MyCoreComponents

    # Common modules used in templates
    alias Phoenix.LiveView.JS
    alias MyappWeb.Layouts

    # Routes generation with the ~p sigil
    unquote(verified_routes())
  end
end
```

Adicionamos `import MyappWeb.MyCoreComponents` logo abaixo do `import MyappWeb.CoreComponents` original. Não se esqueça de remover o `import MyappWeb.MyCoreComponents` da `PageLive` e da `OtherPageLive` também.

## Resumindo!

- Você pode usar componentes de outros módulos usando a sintaxe `<MyappWeb.ModuleName.component_name>`.
- Você pode usar aliases para encurtar chamadas de funções de módulos, como `alias MyappWeb.ModuleName`, para usar a sintaxe `<ModuleName.component_name>`.
- Se o componente em questão é usado em muitos lugares da aplicação, considere colocá-lo no seu `CoreComponents`.
- Por baixo dos panos, `use MyappWeb, :something` apenas insere o código de `def something() do` do `MyappWeb` no seu módulo, para que você tenha acesso a todas as ferramentas necessárias para o seu trabalho.