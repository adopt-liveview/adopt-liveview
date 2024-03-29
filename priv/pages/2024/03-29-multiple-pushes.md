%{
title: "Mais de um evento disparado",
author: "Lubien",
tags: ~w(getting-started),
section: "Eventos",
description: "Como passar ativar 2+ eventos em um clique?"
}

---

Imagine que estamos construindo um sistema de pontos para uma disputa entre dois jogadores. Uma vitória concede 3 pontos ao vencedor e o empate concede 1 ponto a ambos. Se nós tivermos um código como abaixo para conceder vitórias, como podemos construir um terceiro botão para empate? Precisamos de um terceiro evento?

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={JS.push("add_points", value: %{team: :red, amount: +3})}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={JS.push("add_points", value: %{team: :blue, amount: +3})}
    />
    ?????????
    """
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Vamos analisar o que temos até então. Nossa LiveView possui dois assigns com valor inteiro: `:red` e `:blue`. Quando clicamos no botão "Red Wins" nós disparamos um evento chamado `"add_points"` com valor `%{team: :red, amount: +3}`.

Nosso handle `handle_event/3` recebe no evento `"add_points"` um mapa no formato `%{"team" => "red", "amount" => +3}`. Convertemos a string `"red"` no atom `:red` e buscamos o valor atual nos nossos assigns. Logo em seguida atualizamos o socket para que o time correspondente receba o `amount` em pontos.

%{
title: ~H"No HEEx eu escrevi <code>`:red`</code> na propriedade <code>`team`</code>, o evento não deveria receber um atom?",
description: ~H"""
JS Commands serializam os dados em JSON para armazenar no cliente portanto um dado que tem compatibilidade como Integer do elixir e inteiro do JSON funciona normalmente. Já atoms que não existem em JSON são convertidos em string.
"""
} %% .callout

%{
title: ~H"Como <code>`socket.assigns[team_atom]`</code> funciona?",
description: ~H"""
Os assigns em LiveView são apenas mapas do elixir no formato chave valor usando atoms. Nesta LiveView os assigns seriam <code>`%{red: 0, blue: 0}`</code>. Em Elixir você ode dinamicamente pegar um dado de um mapa usando a sintaxe <code>`mapa[:atom]`</code> logo <code>`socket.assigns[:red]`</code> funciona tão bem quando <code>`socket.assigns.red`</code>. Se você estiver com dúvidas recomendamos <.link navigate="https://elixirschool.com/pt/lessons/basics/collections#mapas-5" target="\_blank">esta aula curta do Elixir School</.link>.
"""
} %% .callout

## Encadeando JS Commands

Felizmente, JS Commands podem ser combinados usando o operador pipe. Crie e execute o arquivo `multiple_pushes.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={JS.push("add_points", value: %{team: :red, amount: +3})}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={JS.push("add_points", value: %{team: :blue, amount: +3})}
    />
    <input
      type="button"
      value="Draw"
      phx-click={
        JS.push("add_points", value: %{team: :blue, amount: +1})
        |> JS.push("add_points", value: %{team: :red, amount: +1})
      }
    />
    """
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

A única diferença do código original para este é que o binding `phx-click` tem dois `JS.push` encadeados. Quantos mais você julgar necessários podem ser adicionados.

## JS Commands customizados

Nossa LiveView parece está ficando cheia de código agora com esses JS.push em todo canto. Além disso imagine se um dia formos refatorar o formato de envio? Teríamos que modificar manualmente múltiplos lugares. Felizmente um módulo LiveView deixa você adicionar funções do módulo no seu HEEx. Crie e execute `multiple_pushes_refactor.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={add_points(:red, 3)}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={add_points(:blue, 3)}
    />
    <input
      type="button"
      value="Draw"
      phx-click={add_points(:red, 1) |> add_points(:blue, 1)}
    />
    """
  end

  defp add_points(js \\ %JS{}, team, amount) do
    JS.push(js, "add_points", value: %{team: team, amount: amount})
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Criamos uma função privada chamada `add_points/3` que recebe 3 argumentos. Nesse momento você deve estar se perguntando o que é esse argumento inicial chamado `js`. Para responder isso vamos falar de como JS Commands funcionam internamente.

Toda vez que você usa `JS.push` ou qualquer outra função de JS Commands o que você está realmente criando é uma estrutura de dados chamada `%JS{}`. Quando vazia ela se parece assim: `%Phoenix.LiveView.JS{ops: []}`. Ela contém a lista de operações que serão executadas.

Quando você executa `JS.push("event", value: %{})` você está internamente usando `JS.push(%JS{}, "event", value: %{})`, ou seja, você começou a cadeia de operações agora. Para que nossa função de JS Command customizada possa ser encadeada precisamos fazer com que o primeiro argumento receba opcionalmente um argumento `js \\ %JS{}`.

Tudo bem se esta parte ficou um pouco confusa no momento, iremos revisitar JS Commands no futuro. Por enquanto só leve consigo que se você fizer uma função customizada de JS Commands sempre comece com `def sua_funcao(js \\ %JS{}, ...resto)` e use a variável `js` no primeiro argumento do `JS.push/3`.

## Resumindo!

- JS Commands podem ser encadeados
- Usando JS Commands você pode fazer com que mais de um evento seja disparado na mesma binding `phx-click`.
- Criar funções customizadas de JS Commands requer que explicitamente recebamos um argumento opcional `js \\ %JS{}` e esse `js` seja usado.
