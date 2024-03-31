%{
title: "Componentes de outros módulos",
author: "Lubien",
tags: ~w(getting-started),
section: "Componentes",
description: "Como reusar componentes em mais de uma LiveView"
}

---

Quando criamos um componente como função em uma LiveView nós ganhamos acesso a ele no nosso HEEx usando `<.nome_da_funcao>`. Todavia, se você precisar usar ele em outra LiveView você precisa dizer o nome do módulo também. Crie e execute `shared_component.exs`:

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

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.hero>IndexLive</.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end

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
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <IndexLive.hero>OtherPageLive</IndexLive.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
```

Para este exemplo criamos um simples componente de Hero (um componente geralmente usado para chamar a atenção) e, para poder usarmos na OtherPageLive tivemos que usar a sintaxe `<IndexLive.hero>OtherPageLive</IndexLive.hero>`.

## Conhecendo CoreComponents

Em projetos Phoenix quando temos certos componentes que são úteis em várias partes do nosso sistema nós optamos por compartilhar eles em um módulo chamado CoreComponents e importar eles. Crie e execute um arquivo chamado `core_components.exs`:

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
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>IndexLive</.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>OtherPageLive</.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
```

Agora nosso componente `hero` mora num módulo dedicado a componentes úteis da aplicação. Vale mencionar que nosso CoreComponents possui uma chamada `use LiveviewPlaygroundWeb, :html` para importar diversas funções como suporte a HEEx e a `sigil_p` para rotas.

Em cada uma de nossas LiveViews nós manualmente usamos `import CoreComponents`. Em Elixir quando você importa um módulo você ganha todas as funções dele portanto podemos usar `<.hero>` (ao invés de `<CoreComponents.hero>`) pois a função `hero/1` está disponível em cada LiveView no momento.

%{
title: "CoreComponents no mundo real",
description: ~H"""
Neste exemplo estamos criando um módulo chamado <code>`CoreComponents`</code> mas em projetos Phoenix reais ele seria chamado <code>`SuaAppWeb.CoreComponents`</code> e já seria gerado automaticamente e seria importado automaticamente. Só estamos fazendo esse exercício manual para você entender melhor quais vantagens essa organização possui.
"""
} %% .callout

## Resumindo!

- Você pode usar componentes de outros módulos usando a sintaxe `<NomeDoModulo.nome_do_component>`.
- Se o componente em questão for usado de forma comum na aplicação considere colocar ele no seu `CoreComponents`.
- Durante as aulas iremos construir e importar manualmente nossos `CoreComponents` mas no mundo real o Phoenix já faz isso para você.
