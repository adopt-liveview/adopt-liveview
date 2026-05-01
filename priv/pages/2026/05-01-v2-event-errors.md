%{
title: "Eventos problemáticos",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Quais são os erros mais comuns com eventos?",
previous_page_id: "v2-events",
next_page_id: "v2-heex-is-not-html"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você caiu diretamente nesta página pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

## Aprendendo errando

Um problema que acontece bastante com quem está começando em LiveView é um evento que não foi tratado corretamente. Vamos aprender a debugar esse cenário. Comente seu handle_event/3 desta forma:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}

    <input type="button" value="Reverse" phx-click="reverse" />
    """
  end

  # def handle_event("reverse", _params, socket) do
  #   socket = assign(socket, name: String.reverse(socket.assigns.name))
  #   {:noreply, socket}
  # end
end
```

Ao clicar no botão, do ponto de vista da UI, não vemos nada além de uma barra de carregamento. Mas se você olhar no seu terminal verá algo assim:

```elixir
debug] HANDLE EVENT "reverse" in MyappWeb.PageLive
  Parameters: %{"value" => "Reverse"}
[error] GenServer #PID<0.937.0> terminating
** (UndefinedFunctionError) function MyappWeb.PageLive.handle_event/3 is undefined or private
    (myapp 0.1.0) MyappWeb.PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-GH-g8OXkVBmy2AOC", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.937.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.929.0>, sticky?: false, ...>)
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:528: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.3.0) /Users/joaoferreira/workspace/adopt-liveview-apps/myapp/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:260: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 7.0.1) gen_server.erl:2434: :gen_server.try_handle_info/3
    (stdlib 7.0.1) gen_server.erl:2420: :gen_server.handle_msg/3
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
Process Label: {Phoenix.LiveView, MyappWeb.PageLive, "lv:phx-GH-g8OXkVBmy2AOC"}
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GH-g8OXkVBmy2AOC", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "12", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-GH-g8OXkVBmy2AOC", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.937.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.929.0>, sticky?: false, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-GH-g8OXkVBmy2AOC", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", fingerprints: {334685504655270794193411719397220261095, %{}}, redirect_count: 0, upload_names: %{}, upload_pids: %{}}
```

O Elixir é excelente em nos dizer exatamente o que está faltando. Neste momento a exceção `UndefinedFunctionError` deixa claro que o problema é a falta do callback `handle_event/3` na sua LiveView `PageLive`. E se o problema fosse que nós usamos o nome errado do evento? Descomente seu handle_event/3 mas mude o nome do evento desta forma:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}

    <input type="button" value="Reverse" phx-click="reverse" />
    """
  end

  def handle_event("wrong-reverse", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end
```

Desta vez a exceção é diferente. Ao ver `FunctionClauseError`, a interpretação que você deve ter é que a função existe porém nenhum caso dela bateu com a mensagem enviada:

```elixir
[debug] HANDLE EVENT "reverse" in MyappWeb.PageLive
  Parameters: %{"value" => "Reverse"}
[error] GenServer #PID<0.691.0> terminating
** (FunctionClauseError) no function clause matching in MyappWeb.PageLive.handle_event/3
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:17: MyappWeb.PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-GH-hE0FkiPoKpgAJ", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.691.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.683.0>, sticky?: false, ...>)
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:528: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.3.0) /Users/joaoferreira/workspace/adopt-liveview-apps/myapp/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/channel.ex:260: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 7.0.1) gen_server.erl:2434: :gen_server.try_handle_info/3
    (stdlib 7.0.1) gen_server.erl:2420: :gen_server.handle_msg/3
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
Process Label: {Phoenix.LiveView, MyappWeb.PageLive, "lv:phx-GH-hE0FkiPoKpgAJ"}
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GH-hE0FkiPoKpgAJ", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "12", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-GH-hE0FkiPoKpgAJ", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.691.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.683.0>, sticky?: false, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-GH-hE0FkiPoKpgAJ", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", fingerprints: {334685504655270794193411719397220261095, %{}}, redirect_count: 0, upload_names: %{}, upload_pids: %{}}
```

Para simplificar o seu debug o Elixir já mostra exatamente a mensagem que você recebeu. Vamos limpar a exceção e focar apenas na primeira linha da mensagem de erro:

```elixir
[error] GenServer #PID<0.691.0> terminating
** (FunctionClauseError) no function clause matching in MyappWeb.PageLive.handle_event/3
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:17: MyappWeb.PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-GH-hE0FkiPoKpgAJ", endpoint: MyappWeb.Endpoint, view: MyappWeb.PageLive, parent_pid: nil, root_pid: #PID<0.691.0>, router: MyappWeb.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :home}, transport_pid: #PID<0.683.0>, sticky?: false, ...>)
```

Note que ele diz que sua LiveView recebeu `"reverse"` como primeiro parâmetro. Verificando o código da sua LiveView, percebemos que o seu callback esperava `"wrong-reverse"`. Esse é o problema.

## Resumindo!

- Se você esquecer de fazer o seu `handle_event/3` a LiveView irá mostrar o erro `UndefinedFunctionError`.
- Se você possuir o callback porém não tratar o caso recebido você verá um `FunctionClauseError`.
- Saber interpretar esses erros no seu terminal vai lhe ajudar a desbloquear um novo nível de debug em projetos Elixir.