%{
title: "Mais de um evento disparado",
author: "Lubien",
tags: ~w(getting-started),
section: "Eventos",
description: "Como ativar 2+ eventos em um clique?",
previous_page_id: "v2-js-push",
next_page_id: "v2-your-second-liveview"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nessa página, pode ficar confuso porque é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por aqui, você pode clonar a versão inicial desta aula com o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

Imagine que estamos construindo um sistema de pontos para uma competição entre dois jogadores. Vencer dá 3 pontos ao vencedor e empatar dá 1 ponto para ambos. Se temos o código abaixo para registrar vitórias, como podemos construir um terceiro botão para empate? Precisamos de um terceiro evento?

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd>{@red}</dd>

      <dt>Blue Points</dt>
      <dd>{@blue}</dd>
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
```

Vamos analisar o que temos até agora. Nossa LiveView tem dois assigns de valor inteiro: `:red` e `:blue`. Quando clicamos no botão "Red Wins" disparamos um evento chamado `"add_points"` com o valor `%{team: :red, amount: +3}`.

Nosso handler `handle_event/3` recebe no evento `"add_points"` um mapa no formato `%{"team" => "red", "amount" => +3}`. Convertemos a string `"red"` para o átomo `:red` e buscamos o valor atual nos nossos assigns. Em seguida, atualizamos o socket para que o time correspondente receba o `amount` em pontos.

%{
title: ~H"No HEEx eu escrevi <code>`:red`</code> na propriedade <code>`team`</code>, o evento não deveria receber um átomo?",
description: ~H"""
Os JS Commands serializam dados em JSON para armazenamento no cliente. Dados compatíveis com tipos Elixir, como o Integer do Elixir e o Integer do JSON, funcionam normalmente. Átomos não existem em JSON e por isso são convertidos em strings.
"""
} %% .callout

%{
title: ~H"Como <code>`socket.assigns[team_atom]`</code> funciona?",
description: ~H"""
Assigns no LiveView são apenas mapas Elixir usando átomos (uma estrutura de chave-valor basicamente). Nesta LiveView os assigns seriam <code>`%{red: 0, blue: 0}`</code>. Em Elixir você pode acessar dados dinamicamente de um mapa usando a sintaxe <code>`map[:atom]`</code>, então <code>`socket.assigns[:red]`</code> funciona tão bem quanto <code>`socket.assigns.red`</code>. Se tiver alguma dúvida, recomendamos <.link navigate="https://elixirschool.com/en/lessons/basics/collections#maps-6">esta aula rápida da Elixir School</.link>.
"""
} %% .callout

## Encadeando JS Commands

Felizmente, JS Commands podem ser combinados usando o operador pipe. Atualize seu `page_live.ex` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd>{@red}</dd>

      <dt>Blue Points</dt>
      <dd>{@blue}</dd>
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
```

A única diferença do código original para este é que o binding `phx-click` tem dois `JS.push` encadeados. Você pode adicionar quantos mais forem necessários.

## JS Commands personalizados

Nossa LiveView parece estar ficando cheia de código duplicado com esses `JS.push` por toda parte. Imagine se um dia precisássemos refatorar o formato de envio? Teríamos que modificar múltiplos lugares manualmente. Felizmente um módulo LiveView pode usar funções do módulo no seu HEEx. Agora refatore o `page_live.ex` para usar uma função JS Commands personalizada:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd>{@red}</dd>

      <dt>Blue Points</dt>
      <dd>{@blue}</dd>
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
```

Criamos uma função privada chamada `add_points/3` que recebe 3 argumentos. Neste ponto você pode estar se perguntando o que é esse argumento inicial chamado `js`. Para responder isso, vamos falar sobre como JS Commands funcionam internamente.

Toda vez que você usa `JS.push` ou qualquer outra função JS Commands, o que você está criando de fato é uma estrutura de dados chamada `%JS{}`. Quando vazia fica assim: `%Phoenix.LiveView.JS{ops: []}`. Ela contém a lista de operações que serão executadas.

Quando você executa `JS.push("event", value: %{})` você está internamente usando `JS.push(%JS{}, "event", value: %{})`, ou seja, você iniciou a cadeia de operações agora. Para que nossa função JS Command personalizada seja encadeável, precisamos fazer com que o primeiro argumento receba opcionalmente um `js \\ %JS{}`.

Tudo bem se essa parte ficar um pouco confusa por enquanto; vamos revisitar JS Commands no futuro. Por ora, lembre-se apenas de que se você criar uma função JS Commands personalizada, deve sempre começar com `def sua_funcao(js \\ %JS{}, ...resto)` e usar a variável `js` no primeiro argumento de `JS.push/3`.

## Resumindo!

- JS Commands podem ser encadeados.
- Usando JS Commands você pode fazer com que mais de um evento seja disparado no mesmo binding `phx-click`.
- Criar funções JS Commands personalizadas requer que recebamos explicitamente um argumento opcional `js \\ %JS{}` e que `js` seja utilizado.