%{
title: "Modificando estado com eventos",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Como gerenciar estado usando eventos"
}

---

## Bem vindo ao mundo dinâmico

Em um framework de front-end moderno você não vai querer uma visualização que mostra algo e nunca mais é modificada. Iremos aprender a primeira forma de modificar estado em LiveView: eventos.

Nós vamos construir um botão simples que reverte o nome do usuário atual. Crie um arquivo `events.exs` com o seguinte código:

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

      <input type="button" value="Reverse" >
    </div>
    """
  end
end

LiveviewPlayground.start()
```

Não temos nada muito diferente aqui exceto o botão. Até então apenas HTML básico. Vamos fazer um pouco de mágica agora. Edite o input e adicione um handle_event como no código abaixo:

```elixir
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

  def handle_event("reverse", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end
```

Com essa pequena modificação vemos o primeiro exemplo de reatividade no Phoenix: `phx-click`. Quando clicado, este input gera um evento para sua LiveView com o nome que você escolheu, neste caso `"reverse"`. Execute o servidor mais uma vez e veja que, ao clicar no botão, seu nome é revertido!

## Como funcionam?

Vamos falar sobre o [`handle_event/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_event/3). Esta função é um callback que só é necessário se sua LiveView possui algum evento. Para cada evento no seu código HTML você necessita de um `def handle_event("seu_evento", _params, socket) do` correspondente. Os três argumentos que este callback recebe são, respectivamente:

%{
title: "Lembrete sobre callbacks!",
description: ~H"""
Callbacks são simplesmente funções que são executadas quando determinada coisa acontece.
"""
} %% .callout

- O nome do evento que você definiu.
- Parâmetros do evento (iremos explorar mais em outra aula, no momento estamos apenas ignorando esse argumento).
- O estado do Socket to usuário atual.

Assim como no callback `mount/3` você recebe o `socket` para que você possa modificá-lo como quiser. O retorno esperado da função é `{:noreply, socket}`.

%{
title: ~H"<code>:ok</code> ou <code>:noreply</code>?",
description: ~H"""
Você deve estar se perguntando o motivo de que no callback <code>`mount/3`</code> nós respondemos com <code>`{:ok, socket}`</code> enquanto que no <code>`handle_event/3`</code> usamos <code>`{:noreply, socket}`</code>. <br><br>O <code>`mount/3`</code> é apenas uma função que a LiveView executa enquanto está preparando sua view portanto essa segue o padrão Elixir de dizer "está tudo OK, aqui o socket inicial". <br><br>Já o <code>`handle_event/3`</code> internamente usa um padrão do Erlang/Elixir chamado <code>`GenServer`</code> ("Servidor Genérico") e no futuro veremos que podemos tambem retornar um valor para o elemento que gerou o evento com <code>`{:reply, map(), socket}`</code>!
"""
} %% .callout

## Resumindo!

- Adicionando `phx-click="nome_do_evento"` a um elemento você dispara um evento quando o botão for clicado.
- Para cada evento no seu HTML você precisa de um callback `handle_event("nome_do_evento", _params, socket)` equivalente.
- O callback `mount/3` retorna `{:ok, socket}` enquanto o `handle_event/3` retorna `{:noreply, socket}`.
