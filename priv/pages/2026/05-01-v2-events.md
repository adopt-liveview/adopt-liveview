%{
title: "Modificando estado com eventos",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Como gerenciar estado usando eventos",
previous_page_id: "v2-your-first-mistakes",
next_page_id: "v2-event-errors"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou direto nessa página pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se você quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch mounts-and-assigns-done`</code>.
"""
} %% .callout

## Bem-vindo ao mundo dinâmico

Em um framework de front-end moderno você não vai querer uma view que mostra algo e nunca mais é modificada. Vamos aprender a primeira forma de modificar estado em LiveView: eventos.

Vamos construir um botão simples que reverte o nome do usuário atual. Edite o arquivo `page_live.exs` para isso:

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

    <input type="button" value="Reverse" />
    """
  end
end
```

Não temos nada muito diferente do nosso código anterior aqui, exceto o botão. Até então apenas HTML básico. Vamos fazer um pouco de mágica agora. Edite o input e adicione um `handle_event` como no código abaixo:

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

  def handle_event("reverse", _params, socket) do
    socket = assign(socket, name: String.reverse(socket.assigns.name))
    {:noreply, socket}
  end
end
```

Com essa pequena modificação vemos o primeiro exemplo de reatividade no Phoenix: `phx-click`. Quando clicado, este input gera um evento para sua LiveView com o nome que você escolheu, neste caso `"reverse"`. Execute o servidor mais uma vez e veja que, ao clicar no botão, seu nome é revertido!

## Como funcionam?

Vamos falar sobre o [`handle_event/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_event/3). Esta função é um callback que só é necessário se sua LiveView possui algum evento. Para cada evento no seu código HTML você precisa de um `def handle_event("seu_evento", _params, socket)` correspondente. Os três argumentos que este callback recebe são, respectivamente:

%{
title: "Lembrete sobre callbacks!",
description: ~H"""
Callbacks são simplesmente funções que são executadas quando determinada coisa acontece.
"""
} %% .callout

- O nome do evento que você definiu.
- Parâmetros do evento (iremos explorar mais em outra aula, no momento estamos apenas ignorando este argumento).
- O estado do Socket do usuário atual.

Assim como no callback `mount/3` você recebe o `socket` para que possa modificá-lo como quiser. O retorno esperado da função é `{:noreply, socket}`.

%{
title: ~H"<code>:ok</code> ou <code>:noreply</code>?",
description: ~H"""
Você deve estar se perguntando por que no callback <code>`mount/3`</code> nós retornamos <code>`{:ok, socket}`</code> enquanto no <code>`handle_event/3`</code> usamos <code>`{:noreply, socket}`</code>. <br><br>O <code>`mount/3`</code> é apenas uma função que a LiveView executa enquanto está preparando sua view, portanto ela segue o padrão Elixir de dizer "está tudo OK, aqui o socket inicial". <br><br>Já o <code>`handle_event/3`</code> internamente usa um padrão do Erlang/Elixir chamado <code>`GenServer`</code> ("Servidor Genérico") e no futuro veremos que podemos também retornar um valor para o elemento que gerou o evento com <code>`{:reply, map(), socket}`</code>!
"""
} %% .callout

## Resumindo!

- Adicionando `phx-click="nome_do_evento"` a um elemento, você dispara um evento chamado `"nome_do_evento"` quando ele é clicado.
- Para cada evento no seu HTML você precisa de um callback `handle_event("nome_do_evento", _params, socket)` equivalente.
- O callback `mount/3` retorna `{:ok, socket}` enquanto o `handle_event/3` retorna `{:noreply, socket}`.