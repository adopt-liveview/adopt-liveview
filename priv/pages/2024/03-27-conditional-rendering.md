%{
title: "Renderização condicional",
author: "Lubien",
tags: ~w(getting-started),
section: "Estruturas de Controle",
description: "Renderizar ou não renderizar, eis a questão"
}

---

Vamos aprender algumas formas de renderizar HTML dependendo de certas condições. Crie e execute um arquivo chamado `toggle.exs`:

## Usando `if-else` para casos simples

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% else %>
        <p>You can't see this message!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Vamos destrinchar este código. O único assign que temos aqui se chama `show_information?` com valor inicial de falso. O evento `"toggle"` enviado pelo input simplesmente reverte o valor entre `true` e `false`. O que realmente é novo aqui é nosso bloco de `if-else`.

%{
title: "Interrogação no meio do código? Pode isso, Arnaldo?",
description: ~H"""
Em Elixir a interrogação é válida em átomos e variáveis quando adicionada no final. Isso é bem útil para denotar booleanos. Vai dizer que <code>`if @show_information?`</code> não fica elegante?
"""
} %% .callout

Dentro de uma LiveView você pode fazer um `if-else` da seguinte maneira:

- Adicione um `<%= if condition do %>`. É importante você usar a tag que contém `=` senão o HEEx vai entender que isso não deve ser renderizado!
- Escreva qualquer HTML que estará no caso que deve ser renderizado.
- Adicione um `<% else %>`. Note que não há um `=` desta vez. Se você adicionar ele o código continua a funcionar porém um warning lhe avisará para removê-lo.
- Escreva qualquer HTML para o caso `else`.
- Adicione um `<% ende %>`. Mais uma vez, sem `=`.

Se você não desejar mostrar um caso de `else` existem dua maneiras de fazer isso. A primeira é simples: apenas remova o `<% else %>` e o conteúdo dele! Crie e execute um arquivo chamado `toggle_without_else.ex`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

## O atributo especial `:if`

Para casos em que você só possui o `if` o HEEx possui um atributo especial chamado `:if` em que você pode colocar diretamente na tag HTML. Crie e execute um arquivo chamado `toggle_special_if.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={@show_information?}>You're an amazing person!</p>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

No momento não existe um attributo especial para `else` então como recomendação se você precisa apenas de `if` é recomendado usar `:if` se você puder colocar em uma tag pai das coisas que entram na condição, caso contrário utilize o primeiro exemplo com `if-else` demonstado aqui.

## Usando `case` para casos complexos

É só uma questão de tempo até você chegar em uma situação em que existe mais de duas possibilidades de renderizar algo. Elixir não possui suporte para `else if` e com motivo: a preferência é `case` que é muito mais poderoso!

Vamos criar um sistema simples de abas em LiveView. Crie e execute um arquivo chamado `case.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Desta vez nosso assign virou `tab` que pode ser uma string entre `"home"`, `"about"` ou `"contact"`. Cada input contém um `phx-click="show_NOME_DA_ABA"` de modo que nosso `handle_event/3` irá usar pattern matching em Elixir para aceitar qualquer evento que comece com `show_` e salva o restante do nome do evento em uma variável. Outro ponto simples porém interessante do nosso código é que utilizamos a propriedade `disabled` do HTML para evitar que o botão seja clicável se você já esta na aba correta.

%{
title: "Pattern matching?!",
description: ~H"""
Em Elixir pattern matching é uma técnica comum e bem poderosa que, quando você aprende, não consegue ficar sem querer usar. Como o escopo deste curso é falar sobre LiveView, não sinta que é necessário que você pare tudo para estudar mais sobre isso. Como leitura complementar a Elixir School fala sobre isso aqui: <.link navigate="https://elixirschool.com/pt/lessons/basics/functions#pattern-matching-1" target="\_blank">Funções - Pattern Matching</.link>.
"""
} %% .callout

Agora vamos falar do que importa para esta aula: `case`. Assim como o `if` você precisa começar o condicional com `<%= case (condição aqui) do %>`, ênfase no `=` pois sem ele nada será renderizado. Como nossa condição passada ao `case` foi `@tab`, cada condição vai essencialmente checar `@tab == 'valor'`. Para cada condição fazemos um `<% 'valor esperado' -> %>` (sem a necessidade de `=`) e finalizamos o bloco com `<% end %>`.

Vale mencionar que no nosso case nós tratamos todas as possibilidades de forma explícita. E se nós esquecermos uma possibilidade? Crie e execute um arquivo chamado `case_missing.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    <input disabled={@tab == "blog"} type="button" value="Open Blog" phx-click="show_blog" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Neste exemplo adicionamos um novo botão para mostrar uma aba de blog porém não adicionamos uma cláusula no nosso `case` para tratar este valor do nosso assign. Ao clicar em "Open Blog" você deve notar que sua LiveView reinicia ao estado original e em seu terminal uma exceção aparece:

```elixir
07:18:46.498 [error] GenServer #PID<0.376.0> terminating
** (CaseClauseError) no case clause matching: "blog"
    priv/examples/conditional-rendering/case_missing.exs:16: anonymous fn/2 in PageLive.render/1
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:375: Phoenix.LiveView.Diff.traverse/7
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
    (elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:373: Phoenix.LiveView.Diff.traverse/7
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:833: Phoenix.LiveView.Channel.render_diff/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:689: Phoenix.LiveView.Channel.handle_changed/4
Last message: %Phoenix.Socket.Message{topic: "lv:phx-F8E02o_S_TzHVAEB", event: "event", payload: %{"event" => "show_blog", "type" => "click", "value" => %{"value" => "Open Blog"}}, ref: "13", join_ref: "12"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-F8E02o_S_TzHVAEB", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.376.0>, router: LiveviewPlayground.Router, assigns: %{tab: "home", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.371.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-F8E02o_S_TzHVAEB", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "12", upload_names: %{}, upload_pids: %{}}
```

A mensagem não poderia ser mais explícita! Vamos analisar cada pedaço:

- A exceção é `CaseClauseError` deixando óbvio que falta o tratamento de um caso.
- A própria mensagem de erro já deixa claro que o caso faltando se chama "blog".
- Se você descer o olho a "Last message" você consegue evidenciar que o evento que causou o problema foi o `"show_blog"`. Isto facilita você a entender que parte da sua LiveView iniciou o problema de modo que você possa reproduzir localmente e tratar o erro.

Para adicionar uma cláusula padrão basta usar o formato `<% _ -> %>`. Em Elixir o `_` em contexto de pattern matching significa "qualquer coisa". Poderiámos adicionar um conteúdo padrão como `<p>Tab does not exist</p>`.

%{
title: "O que fazer quando não sabemos tratar todos os casos?",
type: :warning,
description: ~H"""
Tudo depende da UX que você pretende dar ao seu usuário. Usando uma cláusula padrão você falha silenciosamente dando ao usuário uma experiência de que seu sistema está incompleto. Se você intencionalmente deixar sem uma cláusula padrão o sistema irá reiniciar a LiveView o que gera desconforto para seu usuário também porém se você tiver um APM você verá a exceção e pode corrigi-la em seguida. No futuro iremos discutir validações como solução para estes casos.
"""
} %% .callout

## Cadeias de condições com `cond`

No exemplo anterior usamos `case` para comparar o valor exato da variável `@tab` em cada cláusula. Caso você tenha a necessidade de renderizar algo baseado em uma condição que não gira em torno de igualdade o `cond` é perfeito para isso. Crie e execute um arquivo chamado `cond.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: <%= @temperature_celsius %>C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="Increase" phx-click="increase" />
    <input type="button" value="Decrease" phx-click="decrease" />
    """
  end

  def handle_event("increase", _params, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + 10)
    {:noreply, socket}
  end
  def handle_event("decrease", _params, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius - 10)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Nexte exemplo nós gerenciamos a temperatura em graus Celsius aumentando/diminuindo de 10 em 10. A parte realmente importante do código é justamente nosso condicional. Mais uma vez notamos que apenas a primeira tag possui `=` enquanto as demais não. A primeira diferença do `cond` para o `case` é que no `cond` você sempre começa com `cond do` sem passar nada diferente, as condições são independentes e podem muito bem usar diferentes variávels.

Cada cláusula do `cond` segue o formato de predicado (uma expressão que retorna true ou false) e a primeira condição que passar finaliza o fluxo e renderiza o HTML correspondente. Como a ordem de checagem das cláusulas é de cima para baixo não precisamos fazer checagens como `@temperature_celsius > 30 && @temperature_celsius < 40 ->` pois se a condição `@temperature_celsius > 40 ->` não retornou true já sabemos que na segunda cláusula já estamos com uma temperatura abaixo de 40. Diferente do `case`, para adicionar uma cláusula padrão nós adicionados `true ->` no final pois como o `true` está hardcoded e esta é a última cláusula ele sempre vai parar nela.

## Resumindo!

- Para situações de `if-else` você deve usar explicitamente os blocos `<%= if condição do %>` e `<% else %>`.
- Para situações de apenas `if` voce pode usar o formato de bloco `<%= if condição do %>` ou o atributo HEEx especial `:if={condição}` em uma tag HTML.
- Para múltiplas comparações de um valor você pode usar o `<%= case valor do %>`.
- Para múltiplas condições em que não envolvem apenas comparar se um valor é igual você pode usar `<%= cond do %>`.
