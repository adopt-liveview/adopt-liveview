%{
title: "Eventos problemáticos",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Quais os erros comuns com eventos?"
}

---

## Aprendendo errando

Um problema que acontece bastante com pessoas que estão iniciando em LiveView é um evento que não foi tratado corretamente. Vamos aprender a debugar este cenário. Crie um arquivo chamado `event_error.exs` com o seguinte código e o execute:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Hello <%= @name %>

      <input type="button" value="Reverse" phx-click="reverse" >
    </div>
    """
  end
end

LiveviewPlayground.start()
```

Ao clicar no botão, do ponto de vista da UI, não vemos nada! Mas se você olhar no seu terminal verá algo assim:

%{
title: "A UX de error do LiveView é essa?!",
description: ~H"""
Neste exemplo o usuário não tem nenhum feedback do erro acontecendo mas o motivo é que a bilbioteca <code>liveview_playground</code> (ainda) não vem com o mesmo nível de tratamento de erro que o Phoenix completo contém. Em um projeto LiveView real o usuário teria feedback com loaders e toasts por padrão e você pode modificá-los para qualquer coisa que sua imaginação quiser.
"""
} %% .callout

```elixir
08:05:41.576 [error] GenServer #PID<0.377.0> terminating
** (UndefinedFunctionError) function PageLive.handle_event/3 is undefined or private
    PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-F8CaUkZ7G3XHVAAG", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.377.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.371.0>, ...>)
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:401: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.2.1) /Users/lubien/Library/Caches/mix/installs/elixir-1.16.1-erts-14.2.2/df7edc454f95eaecd33200718b6c458a/deps/telemetry/src/telemetry.erl:321: :telemetry.span/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:221: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 5.2) gen_server.erl:1095: :gen_server.try_handle_info/3
    (stdlib 5.2) gen_server.erl:1183: :gen_server.handle_msg/6
    (stdlib 5.2) proc_lib.erl:241: :proc_lib.init_p_do_apply/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-F8CaUkZ7G3XHVAAG", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "8", join_ref: "7"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-F8CaUkZ7G3XHVAAG", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.377.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.371.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-F8CaUkZ7G3XHVAAG", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "7", upload_names: %{}, upload_pids: %{}}
```

O Elixir é excelente em nos dizer exatamente o que falta. Neste momento a exceção `UndefinedFunctionError` deixa claro que o problema é a falta do callback `handle_event/3` na sua LiveView `PageLive`. E se o problema fosse que nós usamos o nome errado do evento? Crie um novo arquivo chamado `event_typo.exs` com o seguinte código e o execute:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Hello <%= @name %>

      <input type="button" value="Reverse" phx-click="reverse" >
    </div>
    """
  end

  def handle_event("reverso", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
```

Desta vez a exceção é diferente. Ao ver `FunctionClauseError` a interpretação que você deve ter é que a função existe porém nenhum caso dela bateu com a mensagem enviada:

```elixir
08:09:52.096 [error] GenServer #PID<0.379.0> terminating
** (FunctionClauseError) no function clause matching in PageLive.handle_event/3
    priv/examples/event-errors/event_typo.exs:23: PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<id: "phx-F8CajZ4frvLvugAB", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.379.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.377.0>, ...>)
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:401: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.2.1) /Users/lubien/Library/Caches/mix/installs/elixir-1.16.1-erts-14.2.2/df7edc454f95eaecd33200718b6c458a/deps/telemetry/src/telemetry.erl:321: :telemetry.span/3
    (phoenix_live_view 0.18.18) lib/phoenix_live_view/channel.ex:221: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 5.2) gen_server.erl:1095: :gen_server.try_handle_info/3
    (stdlib 5.2) gen_server.erl:1183: :gen_server.handle_msg/6
    (stdlib 5.2) proc_lib.erl:241: :proc_lib.init_p_do_apply/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-F8CajZ4frvLvugAB", event: "event", payload: %{"event" => "reverse", "type" => "click", "value" => %{"value" => "Reverse"}}, ref: "6", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-F8CajZ4frvLvugAB", endpoint: LiveviewPlayground.Endpoint, view: PageLive, parent_pid: nil, root_pid: #PID<0.379.0>, router: LiveviewPlayground.Router, assigns: %{name: "Lubien", __changed__: %{}, flash: %{}, live_action: :index}, transport_pid: #PID<0.377.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-F8CajZ4frvLvugAB", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", upload_names: %{}, upload_pids: %{}}
```

Para simplificar seu debug o Elixir já mostra exatamente a mensagem que você recebeu. Vamos limpar a exceção e focar apenas na primeira linha da mensagem de erro:

```elixir
08:09:52.096 [error] GenServer #PID<0.379.0> terminating
** (FunctionClauseError) no function clause matching in PageLive.handle_event/3
    priv/examples/event-errors/event_typo.exs:23: PageLive.handle_event("reverse", %{"value" => "Reverse"}, #Phoenix.LiveView.Socket<>)
```

Note que ele diz que sua LiveView recebeu como primeiro parâmetro "reverse". Verificando o código da sua LiveView notamos que o seu callback esperava `"reverso"`. Este é o problema.

## Resumindo!

- Se você esquecer de fazer o seu `handle_event/3` o LiveView irá mostrar o erro `UndefinedFunctionError`.
- Se você possuir o callback porém não tratar o caso recebido você verá um `FunctionClauseError`.
- Saber interpretar esses erros do seu terminal vai lhe ajudar a desbloquear um novo nível de debug em projetos Elixir.
