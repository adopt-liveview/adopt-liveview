%{
title: "Renderização condicional",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "Renderizar ou não renderizar, eis a questão",
previous_page_id: "v2-basics-of-heex",
next_page_id: "v2-list-rendering"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nessa página, pode ficar confuso porque é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por aqui, você pode clonar a versão inicial desta aula com o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

Vamos aprender algumas formas de renderizar HTML dependendo de certas condições. Vamos atualizar nossa PageLive:

## Usando `if-else` para casos simples

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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

    <input type="button" value="Toggle" phx-click="toggle" />
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end
```

Vamos destrinchar este código. O único assign que temos aqui se chama `show_information?` com valor inicial de false. O evento `"toggle"` enviado pelo input simplesmente inverte o valor entre `true` e `false`. O que realmente é novo aqui é nosso bloco de `if-else`.

%{
title: "Ponto de interrogação no meio do código? Isso é possível?",
description: ~H"""
Em Elixir o ponto de interrogação é válido em átomos e variáveis quando adicionado no final. Isso é muito útil para booleanos. Não fica elegante <code>`if @show_information?`</code>?
"""
} %% .callout

Dentro de uma LiveView você pode fazer um `if-else` da seguinte forma:

- Adicione um `<%= if condição do %>`. É importante usar a tag que contém `=`, caso contrário o HEEx entenderá que isso não deve ser renderizado!
- Escreva qualquer HTML que ficará no caso que deve ser renderizado.
- Adicione um `<% else %>`. Note que não há `=` desta vez. Se você adicionar, o código continuará funcionando mas um warning pedirá para removê-lo.
- Escreva qualquer HTML para o caso `else`.
- Adicione um `<% end %>`. Novamente, sem `=`.

Se você não quiser mostrar um caso `else`, existem duas formas de fazer isso. A primeira é simples: basta remover o `<% else %>` e seu conteúdo! Atualize seu `page_live.ex`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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

    <input type="button" value="Toggle" phx-click="toggle" />
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end
```

## O atributo especial `:if`

Para casos onde você só tem `if`, HEEx possui um atributo especial chamado `:if` que você pode colocar diretamente na tag HTML. Atualize mais uma vez o `page_live.ex`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={@show_information?}>You're an amazing person!</p>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" />
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end
```

No momento não existe um atributo especial para `else`, então se você precisar apenas de `if` recomenda-se usar `:if` quando puder colocá-lo em uma tag pai das coisas que entram na condição; caso contrário, use o primeiro exemplo com `if-else` como mostrado acima.

## Usando `case` para casos complexos

É só uma questão de tempo até você se encontrar em uma situação onde existem mais de duas possibilidades para renderizar algo. Elixir não suporta `else if` e por um bom motivo: a preferência é o `case`, que é muito mais poderoso!

Vamos criar um sistema simples de abas no LiveView.

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

Desta vez nosso assign virou `tab`, que pode ser uma string entre `"home"`, `"about"` ou `"contact"`. Cada input contém um `phx-click="show_NOME_DA_ABA"` para que nosso `handle_event/3` use pattern matching do Elixir para aceitar qualquer evento que começa com `show_` e salvar o restante do nome do evento em uma variável. Outro detalhe simples mas interessante no nosso código é que usamos a propriedade HTML `disabled` para impedir que o botão seja clicável se você já estiver na aba correta.

%{
title: "Pattern matching?!",
description: ~H"""
Em Elixir o pattern matching é uma técnica comum e muito poderosa que, uma vez que você aprende, não consegue deixar de querer usar. Como o escopo deste curso é falar sobre LiveView, não se sinta obrigado a parar tudo para estudar mais sobre ele. Você pode aprender mais sobre isso na Elixir School aqui: <.link navigate="https://elixirschool.com/en/lessons/basics/functions" target="\_blank">Functions - Pattern Matching</.link>.
"""
} %% .callout

Agora vamos falar sobre o que é importante para esta aula: `case`. Assim como o `if`, você precisa iniciar o condicional com `<%= case (condição aqui) do %>`, com ênfase no `=` porque sem ele nada será renderizado. Como nossa condição no `case` era `@tab`, cada condição essencialmente verifica `@tab == 'valor'`. Para cada condição fazemos um `<% "valor esperado" -> %>` (sem necessidade de `=` na tag de interpolação) e encerramos o bloco com `<% end %>`.

Vale mencionar que no nosso `case` tratamos todos os cenários possíveis. E se esquecêssemos uma possibilidade? Vamos tentar isso:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

Neste exemplo adicionamos um novo botão para mostrar uma aba de blog, mas não adicionamos uma cláusula no nosso `case` para tratar esse valor do nosso assign. Quando você clicar em "Open Blog" deve notar que sua LiveView reinicia para o estado original e uma exceção aparece no seu terminal:

```elixir
[debug] HANDLE EVENT "show_blog" in MyappWeb.PageLive
  Parameters: %{"value" => "Open Blog"}
[debug] Replied in 78µs
[error] GenServer #PID<0.802.0> terminating
** (CaseClauseError) no case clause matching:

    "blog"

    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:399: Phoenix.LiveView.Diff.traverse/6
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:146: Phoenix.LiveView.Diff.render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:1018: anonymous fn/4 in Phoenix.LiveView.Channel.render_diff/3
    (telemetry 1.3.0) /Users/joaoferreira/workspace/adopt-liveview-apps/myapp/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:1011: Phoenix.LiveView.Channel.render_diff/3
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:841: Phoenix.LiveView.Channel.handle_changed/4
    (stdlib 7.0.1) gen_server.erl:2434: :gen_server.try_handle_info/3
    (stdlib 7.0.1) gen_server.erl:2420: :gen_server.handle_msg/3
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
Process Label: {Phoenix.LiveView, MyappWeb.PageLive, "lv:phx-GKk86LOWj7JUBQPB"}
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GKk86LOWj7JUBQPB", event: "event", payload: %{"event" => "show_blog", "type" => "click", "value" => %{"value" => "Open Blog"}}, ref: "14", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-GKk86LOWj7JUBQPB", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.802.0>, router: MyappWeb.Router, assigns: %{__changed__: %{}, flash: %{}, live_action: :home, tab: "contact"}, transport_pid: #PID<0.794.0>, sticky?: false, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-GKk86LOWj7JUBQPB", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", fingerprints: {87600012899249314488331332113278855451, %{0 => {124361009764341041662904844712747910554, %{}}}}, redirect_count: 0, upload_names: %{}, upload_pids: %{}}
```

A mensagem não poderia ser mais explícita! Vamos analisar cada parte:

- A exceção é `CaseClauseError`, deixando óbvio que uma cláusula `case` está faltando.
- A própria mensagem de erro deixa claro que a cláusula faltante se chama "blog".
- Se você olhar "Last message" pode ver que o evento que causou o problema foi `"show_blog"`. Isso facilita entender qual parte da sua LiveView iniciou o problema para que você possa reproduzi-lo localmente e tratá-lo.

Para adicionar uma cláusula padrão basta usar o formato `<% _ -> %>`. Em Elixir o `_` no contexto de pattern matching significa "qualquer coisa". Poderíamos adicionar um conteúdo padrão como `<p>Aba não existe</p>`.

%{
title: "O que fazer quando não sabemos como tratar todos os casos?",
type: :warning,
description: ~H"""
Depende da experiência que você quer oferecer ao usuário. Ao usar uma cláusula padrão você falha silenciosamente dando ao usuário a impressão de que seu sistema está incompleto. Se você deixar intencionalmente sem cláusula padrão, o sistema irá reiniciar a LiveView, o que também cria uma experiência inesperada para o seu usuário, mas se você tiver um APM verá a exceção e poderá corrigi-la depois. No futuro discutiremos validações como solução para esses casos.
"""
} %% .callout

## Cadeias de condições com `cond`

No exemplo anterior usamos `case` para comparar o valor exato da variável `@tab` em cada cláusula. Se você precisar renderizar algo com base em uma condição que não é sobre igualdade, `cond` é perfeito para isso. Vamos tentar:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
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
```

Neste código gerenciamos a temperatura em graus Celsius aumentando/diminuindo 10. A parte realmente importante do código é justamente o nosso `cond`. Mais uma vez observe que apenas a primeira tag tem `=` enquanto as outras não têm. A primeira diferença entre `cond` e `case` é que em `cond` você sempre começa com `cond do` sem passar uma expressão para ser avaliada imediatamente; cada cláusula é independente e pode muito bem usar variáveis diferentes.

Cada cláusula `cond` segue o formato predicado (uma expressão que retorna true ou false) e a primeira condição que for verdadeira encerra o fluxo e renderiza o HEEx correspondente. Como a ordem de verificação das cláusulas é de cima para baixo, não precisamos fazer verificações como `@temperature_celsius > 30 && @temperature_celsius < 40 ->` porque se a condição `@temperature_celsius > 40 ->` não retornou true, já sabemos que na próxima cláusula a temperatura está abaixo de 40. Ao contrário do `case`, para adicionar uma cláusula padrão fazemos `true ->` no final porque, como `true` é fixo e esta é a última cláusula, sempre passará por ali.

## Resumindo!

- Para `if-else` você deve usar explicitamente os blocos `<%= if condição do %>` e `<% else %>`.
- Para `if` sem `else` você pode usar o formato de bloco `<%= if condição do %>` ou o atributo especial HEEx `:if={condição}` em uma tag HTML.
- Para múltiplas comparações de um valor você pode usar `<%= case valor do %>`.
- Para múltiplas condições que não envolvem apenas comparar se um valor corresponde a algo, você pode usar `<%= cond do %>`.
- Em todos os casos, a primeira tag sempre precisará de `=` e as outras não. Se você adicionar `=` nas outras tags, o LiveView gerará warnings mas tudo funcionará normalmente.
- Se na primeira tag você não adicionar `=`, o código HTML não será renderizado.