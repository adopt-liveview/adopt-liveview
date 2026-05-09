%{
title: "Criação de Tickets em Tempo Real",
author: "Lubien",
tags: ~w(realtime),
section: "Tempo Real com LiveView",
description: "Como usar PubSub para transmitir a criação de tickets em tempo real",
previous_page_id: "v2-pubsub-primer",
next_page_id: "v2-under-construction",
}

---

%{
title: "Esta lição é uma continuação direta de uma lição anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da lição anterior. Se quiser pular a lição anterior e começar direto com esta, você pode clonar a versão inicial desta lição usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch form-component-done`</code>.
"""
} %% .callout

Sem mais delongas, vamos mergulhar no código!

## Transmitindo novos tickets

Um dos motivos pelos quais criamos um arquivo de contexto Queue foi centralizar onde nossas operações ficam. Isso facilita a manutenção do código ao longo do tempo. Este é um desses momentos. Vá até o módulo `Queue` e atualize `create_ticket/2` assim:

```elixir
defmodule Lineup.Queue do
  @moduledoc """
  The Queue context.
  """

  import Ecto.Query, warn: false
  alias LineupWeb.Endpoint
  alias Lineup.Repo

  alias Lineup.Queue.Ticket
  
  # ...muitas funções
  
  @doc """
  Creates a ticket and broadcasts its ID when successful.

  ## Examples

      iex> create_ticket(%{field: value})
      {:ok, %Ticket{}}

      iex> create_ticket(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ticket(attrs) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
    |> tap(fn result ->
      if match?({:ok, %Ticket{}}, result) do
        {:ok, ticket} = result
        Endpoint.broadcast("queue:tickets", "add_ticket", %{ticket_id: ticket.id})
      end
    end)
  end

  # ...resto
end
```

Temos duas novidades aqui. Primeiro, adicionamos um [`tap/2`](https://hexdocs.pm/elixir/1.12.3/Kernel.html#tap/2) no nosso pipeline. Esta função sempre recebe um valor e uma função. Ela chama a função com o valor e retorna o valor sem alterações. Ao usar `tap/2`, estamos deixando claro que o conteúdo desta função não afetará o resultado do pipeline.

A outra função introduzida aqui é na verdade um macro chamado [`match?/2`](https://hexdocs.pm/elixir/1.12.3/Kernel.html#match?/2). Este macro compara o padrão passado no primeiro argumento com o valor passado no segundo argumento. Ela retorna `true` se o padrão corresponder ao valor. Como não nos importamos com outras cláusulas de `create_ticket/1`, checamos apenas ao caso de sucesso para fazer o broadcast do resultado.

Por último, mas não menos importante, usamos [`Endpoint.broadcast/3`](https://hexdocs.pm/phoenix/1.7.11/Phoenix.Endpoint.html#broadcast/3) para enviar uma mensagem ao canal `queue:tickets` quando um ticket é criado. Certifique-se de adicionar `alias LineupWeb.Endpoint` no topo do módulo também.

## Esperando novos tickets no nosso `TicketLive.Index`

Vamos direto ao ponto, edite o `TicketLive.Index` para adicionar o seguinte:

```elixir
defmodule LineupWeb.TicketLive.Index do
  use LineupWeb, :live_view

  alias Lineup.Queue
  alias LineupWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    Endpoint.subscribe("queue:tickets")

    {:ok,
     socket
     |> assign(:page_title, "Listing Tickets")
     |> stream(:tickets, list_tickets())}
  end

  # ...handle_event

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "queue:tickets",
          event: "add_ticket",
          payload: %{ticket_id: ticket_id}
        },
        socket
      ) do
    ticket = Queue.get_ticket!(ticket_id)
    {:noreply, socket |> stream_insert(:tickets, ticket)}
  end

  # ...muitas coisas
end
```

![Criação de ticket em tempo real](/videos/ticket-creation-in-real-time/real-time-ticket.mp4)

Acabamos de apresentar um novo callback chamado `handle_info/2`. Este callback pode ser usado por LiveViews para tratar mensagens recebidas de outros processos. Da aula anterior já sabemos que `Endpoint.broadcast/3` nos envia mensagens no formato `%Phoenix.Socket.Broadcast{...}`, então podemos analisá-las facilmente para extrair as informações que precisamos. Agora você provavelmente já consegue ver como tópicos e eventos são usados para definir o comportamento das atualizações em tempo real. Não esqueça que tudo o que foi necessário foi adicionar `Endpoint.subscribe("queue:tickets")` e este LiveView instantaneamente passou a receber atualizações em tempo real da Queue!

Além disso, também introduzimos [`stream_insert/4`](https://hexdocs.pm/phoenix_live_view/1.2.0-rc.2/Phoenix.LiveView.html#stream_insert/4) para adicionar um ticket ao nosso stream. Essa função adiciona um elemento ao final do stream por padrão, o que se encaixa perfeitamente no nosso caso de uso.

## Escrevendo código de fácil manutenção

Assim como focamos as operações de Ticket no nosso módulo Queue, também devemos garantir que nossas abstrações de PubSub sejam bem definidas e fáceis de reutilizar no futuro. Volte ao módulo Queue e adicione o seguinte:

```elixir
@topic "queue:tickets"

@doc """
Keep track of tickets changes on the queue:tickets topic

## Events

    %Phoenix.Socket.Broadcast{topic: "queue:tickets", event: "add_ticket", payload: %{ticket_id: 1}}

"""
def subscribe_to_tickets() do
  Endpoint.subscribe(@topic)
end

@doc """
Broadcasts "add_ticket" event to the queue:tickets topic
"""
def broadcast_ticket_created(ticket) do
  Endpoint.broadcast(@topic, "add_ticket", %{ticket_id: ticket.id})
end
```

Agora definimos o tópico como uma module tag do Elixir para podermos alterá-lo facilmente no futuro se necessário, e também escondemos os detalhes de implementação do nosso PubSub do resto da aplicação. Certifique-se de também atualizar o `TicketLive.Index` para usar o novo módulo `Queue`:

```diff
- Endpoint.subscribe("queue:tickets")
+ Queue.subscribe_to_tickets()
```

Além disso, agora também temos intellisense no nosso editor de código.

![Intellisense em subscribe_to_tickets/0](/images/ticket-creation-in-real-time/intellisense.png)

## Como testar atualizações em tempo real?

Não vamos encerrar esta aula sem adicionar testes para essas atualizações. Vá até o `Lineup.QueueTest` e atualize nosso teste de criação assim:

```elixir
test "create_ticket/1 with valid data creates a ticket and broadcasts the update" do
  valid_attrs = %{called_at: ~U[2026-04-27 16:00:00Z]}

  Queue.subscribe_to_tickets()

  assert {:ok, %Ticket{} = ticket} = Queue.create_ticket(valid_attrs)
  assert ticket.called_at == ~U[2026-04-27 16:00:00Z]
  new_ticket_id = ticket.id

  assert_receive %Phoenix.Socket.Broadcast{
    topic: "queue:tickets",
    event: "add_ticket",
    payload: %{ticket_id: ^new_ticket_id}
  }
end
```

Podemos facilmente fazer um subscrive das atualizações de tickets e usar uma função auxiliar [`assert_receive/3`](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html#assert_receive/3) para verificar que a mensagem de broadcast chegou a este processo de teste. Também usamos pattern matching para verificar que o `ticket_id` no payload corresponde ao ticket que criamos, usando o [operador pin `^`](https://hexdocs.pm/elixir/pattern-matching.html#the-pin-operator), que faz o pattern matching a checar o valor exato de `new_ticket_id`.

Quanto ao nosso `TicketLiveTest`, é tão simples quanto:

```elixir
test "receives new tickets via pubsub", %{conn: conn} do
  {:ok, index_live, html} = live(conn, ~p"/")
  new_ticket = ticket_fixture()
  assert has_element?(index_live, "#tickets-#{new_ticket.id}")
end
```

Podemos adicionar um novo caso de teste que entra na liveview de listagem de tickets, depois cria um novo ticket e verifica se ele aparece na lista. Usando [`has_element?/3`](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html#has_element?/3) podemos usar um seletor CSS para verificar que `#tickets-ID` existe no HTML. E se você está curioso sobre de onde vem esse ID, ele vem do `html_id` do nosso stream `tickets`. Qualquer stream chamado `:elements` terá um `html_id` gerado automaticamente como `#elements-ID`, então nosso caso de teste pode usar isso para verificar que o elemento existe.

## Resumo!

- Usando `tap/2` você pode executar código dentro de um pipeline sem interferir no resultado final.
- A macro `match?/2` é útil quando você quer corresponder apenas a uma cláusula, ao contrário de `cond` e `case` que requerem múltiplas cláusulas.
- Elixir usa o callback `handle_info/2` para tratar mensagens enviadas ao seu processo.
- Usando `stream_insert/4` você pode adicionar um valor a um stream sem modificar o stream em si.
- Prefira esconder os detalhes de implementação das suas assinaturas PubSub em métodos no seu contexto, não apenas para tornar o código mais reutilizável, mas também para facilitar a manutenção e os testes posteriormente.
- Testar atualizações de PubSub se torna trivial com `assert_receive/2`.
- Streams do LiveView geram automaticamente um `html_id` para cada elemento no stream, então você pode usar isso para verificar que elementos existem no HTML.
- A função `has_element?/3` é útil para verificar que elementos existem no HTML de um LiveView.
