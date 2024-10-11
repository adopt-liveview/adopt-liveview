%{
title: "Anatomia de uma LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Introdução",
description: "O que siginifica cada pedaço deste código aqui?",
previous_page_id: "first-liveview",
next_page_id: "mount-and-assigns"
}

---

## Entendendo as partes

Vamos retomar o código do passo anterior:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end

LiveviewPlayground.start()
```

## Entendendo o `Mix.install`

Mix é a ferramente que gerencia e compila projetos em Elixir. Para scripts em Elixir a função [`Mix.Install/2`](https://hexdocs.pm/mix/1.12.3/Mix.html#install/2) serve para instalar dependências sem você precisar fazer um projeto Mix inteiro. Na prática você dificilmente vai hospedar projetos LiveView usando scripts `.exs` ([apesar de ser possível](https://fly.io/phoenix-files/single-file-elixir-scripts/) e válido dependendo do seu projeto) porém para estudos isso é o suficiente.

%{
title: ~H"Ei, o que foi esse <code>/2</code> que você disse no <code>Mix.install/2</code>?",
description: ~H"""
Em Elixir as funções são diferentes dependendo do número de argumentos. Então assim como existe a função <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/1" target="\_blank"><code>Enum.count/1</code></.link> também existe a <.link navigate="https://hexdocs.pm/elixir/Enum.html#count/1" target="\_blank"><code>Enum.count/2</code></.link> que recebe dois argumentos e são funções diferentes. Vale mencionar que esse número de argumentos representa a <strong class="text-black dark:text-white">aridade da função</strong>. Uma função que aceita um argumento é uma função unária Uma função que aceita dois argumentos é uma função binária Uma função que aceita três argumentos é uma função ternária.
"""
} %% .callout

## O módulo PageLive

Por conveniência o `LiveviewPlayground` sempre procura um `defmodule PageLive do` para usar por padrão. Se você esquecer de escrever ele irá ver um erro no sistema. Veremos mais tarde que esse nome não importa tanto e pode ser chamado de qualquer coisa quando estudarmos sobre `Router` do Phoenix.

A primeira linha do módulo `use LiveviewPlaygroundWeb, :live_view` é importante de ser entendida e você verá em todas as aplicações LiveView. O macro `use` funciona por trás dos panos como uma forma de executar um código em tempo de compilação. Pense nisso como "na hora que este código compilar, coisas serão adicionadas". Quando estudarmos o módulo `LiveviewPlaygroundWeb` tudo ficará mais claro porém você só precisa saber agora que quase sempre que você for fazer uma LiveView o módulo dela terá algo como `use NomeDoProjetoWeb, :live_view`.

```elixir
def render(assigns) do
  ~H"""
  Hello World
  """
end
```

Por fim, o mínimo para você ter uma LiveView é, pasme, a View. Isto é, uma função que explica qual código HTML será mostrado para seu usuário. Toda LiveView (sem exceção) tem uma função de renderização que recebe exclusivamente um argumento chamado `assigns` (falaremos sobre eles logo mais). Tudo que sua `render function` precisa fazer é retornar um HTML válido usando a [sigil_H/2](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2).

%{
title: ~H"<code>sigil_H/2</code>?",
description: ~H"""
Em Elixir, as <code>sigils</code> são funções binárias (recebem 2 argumentos) que servem pra transformar texto em outra coisa. A <code>sigil_H/2</code> transforma HTML válido em uma estrutura de dados otimizada para enviar HTML para seu usuário. <strong class="text-black dark:text-white">Precisamos saber como ela funciona?</strong> Não! Mas iremos ver no futuro apenas a nível de curiosidade nos tópicos avançados.
"""
} %% .callout

## Recapitulando!

- Mix é a ferramenta de compilação de projetos Elixir.
- `Mix.install/2` é útil para projetos simples e geralmente não é usado para hospedar LiveView em produção.
- Todas as LiveViews possuem uma `render function` e sempre recebem um argumento chamado `assigns`.
- `use SeuProjetoWeb, :live_view` adiciona coisas em tempo de compilação para fazer sua LiveView funcionar direitinho.
