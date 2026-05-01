%{
title: "Deletando um ticket",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Criando uma UX de deletar um ticket usando LiveView",
previous_page_id: "v2-show-data",
next_page_id: "v2-editing-data"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch show-data-done`</code>.
"""
} %% .callout

Vamos pular para a última letra do CRUD: o Delete. Nesta aula vamos ver como é simples criar uma UX de deletar um item usando recursos do próprio projeto.

## Você provavelmente já imaginou que começaríamos com o Context

O primeiro passo é voltarmos para o nosso arquivo `lib/lineup/queue.ex` e adicionar uma nova função:

```elixir
defmodule Lineup.Queue do
  # ...

  @doc """
  Deletes a ticket.

  ## Examples

      iex> delete_ticket(ticket)
      {:ok, %Ticket{}}

      iex> delete_ticket(ticket)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end
end
```

A função `delete_ticket/1` recebe um struct do tipo `%Ticket{}` e simplesmente aplica o método [`Repo.delete/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:delete/2) nele. O resultado será `{:ok, %Ticket{}}`, o que é útil caso seja necessário conhecer o ticket deletado.

### Testando no `iex`

Usando o confiável modo Elixir Interativo, podemos pegar o último ticket com `ticket = Lineup.Queue.list_tickets() |> List.last` e deletá-lo usando `Lineup.Queue.delete_ticket(ticket)`:

```elixir
$ iex -S mix

[info] Migrations already up
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Interactive Elixir (1.16.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> ticket = Lineup.Queue.list_tickets() |> List.last

[debug] QUERY OK source="tickets" db=0.2ms queue=0.1ms idle=1192.5ms
SELECT p0."id", p0."name", p0."description" FROM "tickets" AS p0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405

%Lineup.Queue.Ticket{
  __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
  id: 10,
  name: "asda",
  description: "ad"
}

iex(2)> Lineup.Queue.delete_ticket(ticket)
[debug] QUERY OK source="tickets" db=1.7ms idle=1366.3ms
DELETE FROM "tickets" WHERE "id" = ? [10]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:405
{:ok,
 %Lineup.Queue.Ticket{
   __meta__: #Ecto.Schema.Metadata<:deleted, "tickets">,
   id: 10,
   name: "asda",
   description: "ad"
 }}
```

## Deletando tickets na lista de LiveView

Ao invés de criarmos uma nova LiveView chamada `TicketLive.Delete`, podemos reutilizar a lista de tickets para isso. Abra sua `TicketLive.Index` localizada em `lib/lineup_web/live/ticket_live/index.ex`.

### O slot `<:action>` do componente `<.table>`

Dentro da sua `render/1`, atualize sua `<.table>` para o seguinte código:

```elixir
<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="ID">{ticket.id}</:col>
  <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
  <:action :let={{id, ticket}}>
    <.link
      phx-click={JS.push("delete", value: %{id: ticket.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>
```

Adicionamos um slot chamado `<:action>` onde recebemos tanto o `id` quanto o `ticket` usando o atributo especial `:let`. Este slot fica como última coluna para adicionarmos botões de ação na nossa linha.

### O ID do `:let`

Este `id` em específico é conhecido como "DOM ID" ou "HTML ID" e, neste caso, deve ser algo como "tickets-123" pois nossa tabela tem o ID "tickets" e supondo que o ID no banco de dados do elemento é 123. Ele é útil para aplicarmos JS commands.

### Confirmando ações com `data-confirm`

O próximo ponto de foco é o `data-confirm`. Não queremos que o item seja deletado imediatamente sem qualquer tipo de confirmação, certo? O Phoenix verifica que, caso você clique em um elemento com `data-confirm`, ele dispara um diálogo `confirm` no seu navegador e só aplica o `phx-click` se o usuário confirmar.

### O comando `hide/2`

Dentro do nosso binding `phx-click`, duas coisas acontecem:

1. Enviamos um evento à nossa LiveView chamado "delete" (ainda precisamos defini-lo).
2. Escondemos o elemento da linha atual usando o HTML ID.

Como você pode notar, não estamos usando diretamente `JS.hide/2` e sim apenas a função `hide/1`. Isso acontece porque o Phoenix já traz essa função simplificada dentro do `CoreComponents`, que aplica transições usando classes CSS! Veja no seu `CoreComponents`:

```elixir
def hide(js \\ %JS{}, selector) do
  JS.hide(js,
    to: selector,
    time: 200,
    transition:
      {"transition-all transform ease-in duration-200",
       "opacity-100 translate-y-0 sm:scale-100",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
  )
end
```

Sempre que possível, prefira usar `hide/1` do `CoreComponents`. Porém, se você precisar customizar a transição, opte por `JS.hide/2`.

### Criando o evento de deletar

Para conseguirmos testar este código, precisamos criar nosso `handle_event/3`. Em sua LiveView, abaixo da função `mount/3`, adicione este callback:

```elixir
@impl true
def handle_event("delete", %{"id" => id}, socket) do
  ticket = Queue.get_ticket!(id)
  {:ok, _} = Queue.delete_ticket(ticket)

  {:noreply, stream_delete(socket, :tickets, ticket)}
end
```

Neste evento recebemos apenas o ID e imediatamente verificamos no banco se o ticket existe usando a função `Queue.get_ticket/1` que construímos na aula anterior. Em seguida, deletamos o ticket. Como já temos a variável `ticket`, ignoramos o segundo resultado da função de deletar.

### A função `stream_delete/3`

Em aulas anteriores já vimos como criar streams usando `stream/4` para renderizar listas de maneira eficiente. Agora conhecemos a função [`stream_delete/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream_delete/3) para deletar um item de uma stream.

Lembrando que streams não armazenam nenhum dado em memória sobre seus itens, a função `stream_delete/3` recebe o nome da stream que é `:tickets` como definimos no nosso `mount/3` e o `ticket`. Usando essas duas variáveis, ela infere que o HTML ID do elemento será `#tickets-123` e envia um payload simples ao cliente indicando que a LiveView deve deletar este elemento do HTML.

### Código da LiveView

Com todas as peças unidas, sua `TicketLive.Index` deve estar próxima deste código:

```elixir
defmodule LineupWeb.TicketLive.Index do
  use LineupWeb, :live_view

  alias Lineup.Queue

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Tickets")
     |> stream(:tickets, list_tickets())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ticket = Queue.get_ticket!(id)
    {:ok, _} = Queue.delete_ticket(ticket)

    {:noreply, stream_delete(socket, :tickets, ticket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tickets
        <:actions>
          <.button variant="primary" navigate={~p"/tickets/new"}>
            <.icon name="hero-plus" /> New Ticket
          </.button>
        </:actions>
      </.header>

      <.table
        id="tickets"
        rows={@streams.tickets}
        row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
      >
        <:col :let={{_id, ticket}} label="ID">{ticket.id}</:col>
        <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
        <:action :let={{id, ticket}}>
          <.link
            phx-click={JS.push("delete", value: %{id: ticket.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  defp list_tickets() do
    Queue.list_tickets()
  end
end
```

## Adicionando mais testes!

Não deve ser nenhum mistério para você como adicionar testes de contexto em `QueueTest`. Vá até esse arquivo de teste e adicione:

```elixir
test "delete_ticket/1 deletes the ticket" do
  ticket = ticket_fixture()
  assert {:ok, %Ticket{}} = Queue.delete_ticket(ticket)
  assert_raise Ecto.NoResultsError, fn -> Queue.get_ticket!(ticket.id) end
end
```

Neste caso de teste estamos usando [`assert_raise/2`](https://hexdocs.pm/ex_unit/1.19.3/ExUnit.Assertions.html#assert_raise/2) para verificar que chamar `Queue.get_ticket/1` novamente retornará corretamente `Ecto.NoResultsError` como esperado. Quanto ao `TicketLiveTest`, nosso teste é tão simples quanto disparar o evento de clique no botão. Adicione isso à sua seção `describe "Index" do`:

```elixir
test "deletes ticket in listing", %{conn: conn, ticket: ticket} do
  {:ok, index_live, _html} = live(conn, ~p"/tickets")

  assert index_live |> element("#tickets-#{ticket.id} a", "Delete") |> render_click()
  refute has_element?(index_live, "#tickets-#{ticket.id}")
end
```

## Código final

Pronto! Agora basta testar sua LiveView e verificar que o fluxo atual está funcionando.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout deleting-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/lineup.git --branch deleting-data-done`.

## Resumindo!

- A função `Repo.delete/2` recebe um struct de um schema Ecto e o deleta do banco de dados.
- O slot `<:action>` é útil para adicionar botões de ação nas suas tabelas.
- Os IDs que vêm do atributo especial `:let` em slots do componente `<.table>` se chamam DOM ID ou HTML ID e seguem o formato `nome-da-sua-stream-ID` (onde ID é o ID no banco de dados do elemento).
- O DOM ID é útil para aplicar JS commands.
- O `CoreComponents` de projetos Phoenix vem com uma função `hide/1` que é simplesmente a `JS.hide/2` com uma transição bonita.
- Podemos usar `data-confirm` para confirmar com o usuário antes de disparar uma ação como um `phx-click`.
- A função `stream_delete/3` é uma forma de deletar elementos de uma stream. Esta função otimiza o envio do mínimo de dados para a LiveView, seguindo a ideia de que streams são uma maneira eficiente de gerenciar listas em LiveView.
- `assert_raise/2` pode ser usado para testar que exceções serão lançadas por algum código.