%{
title: "Editando um ticket",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Editando dados existentes com formulários LiveView",
previous_page_id: "v2-deleting-data",
next_page_id: "v2-form-component"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch deleting-data- done`</code>.
"""
} %% .callout

Para finalizar o CRUD vamos criar um formulário de edição de ticket. Vamos ver como isso pode ser extremamente similar ao formulário de criação de ticket.

## De volta ao Context

Vamos voltar para nosso `lib/lineup/queue.ex` e adicionar uma nova função:

```elixir
defmodule Lineup.Queue do
  # ...
  
  @doc """
  Updates a ticket.

  ## Examples

      iex> update_ticket(ticket, %{field: new_value})
      {:ok, %Ticket{}}

      iex> update_ticket(ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end
end
```

Ao contrário do `create_ticket/1` que recebe apenas os atributos, para atualizar um ticket precisamos dos dados originais para poder aplicar as mudanças. Nossa função `Queue.update_ticket/2` recebe o struct original e as modificações, aplica o changeset e, usando a função [`Repo.update/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:update/2), retorna `{:ok, %Ticket{}}` ou `{:error, %Ecto.Changeset{}}`.

### Testando no `iex`

Usando o Elixir Interativo podemos pegar o último ticket com `ticket = Lineup.Queue.list_tickets() |> List.last` e atualizá-lo usando `Lineup.Queue.update_ticket(ticket, %{name: "Edited"})`:

```elixir
$  iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Compiling 1 file (.ex)
Generated lineup app
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> ticket = Lineup.Queue.list_tickets() |> List.last
[debug] QUERY OK source="tickets" db=0.8ms decode=0.6ms idle=727.5ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
%Lineup.Queue.Ticket{
 __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
 id: 6,
 called_at: ~U[2026-04-22 13:15:00Z],
 inserted_at: ~U[2026-04-30 14:15:45Z],
 updated_at: ~U[2026-04-30 14:15:45Z]
}

iex(2)> NaiveDateTime.utc_now()
~N[2026-05-01 17:11:03.402100]

iex(3)> Lineup.Queue.update_ticket(ticket, %{called_at: DateTime.utc_now()})
[debug] QUERY OK source="tickets" db=0.1ms idle=936.7ms
UPDATE "tickets" SET "called_at" = ?, "updated_at" = ? WHERE "id" = ? [~U[2026-05-01 17:11:13Z], ~U[2026-05-01 17:11:13Z], 6]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
{:ok,
%Lineup.Queue.Ticket{
  __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
  id: 6,
  called_at: ~U[2026-05-01 17:11:13Z],
  inserted_at: ~U[2026-04-30 14:15:45Z],
  updated_at: ~U[2026-05-01 17:11:13Z]
}}
```

Note que no segundo argumento passamos apenas o `called_at` com `DateTime.utc_now()`. O Ecto sabe o que mudou e o que permanece igual ao usar changesets.

## Criando nossa LiveView

Vamos escrever o código da LiveView passo a passo para vermos as semelhanças com a `TicketLive.Create`. Na pasta `lib/lineup_web/live/ticket_live/` crie um arquivo `edit.ex`.

### Começando

```elixir
defmodule LineupWeb.TicketLive.Edit do
  use LineupWeb, :live_view
  alias Lineup.Queue
  alias Lineup.Queue.Ticket
end
```

O primeiro passo é criar o módulo e fazer `use LineupWeb, :live_view`. Em seguida adicionamos dois aliases úteis para o que vem a seguir.

### O `mount/3`

```elixir
@impl true
def mount(%{"id" => id}, _session, socket) do
  ticket = Queue.get_ticket!(id)
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  {:ok,
   socket
   |> assign(:page_title, "Edit Ticket")
   |> assign(:ticket, ticket)
   |> assign(:form, form)}
end
```

Em nosso `mount/3` recebemos o `id` do ticket como parâmetro. Em breve vamos definir isso no router como `live "/tickets/:id/edit", TicketLive.Edit, :edit`, o que nos garante que sempre haverá esse `id`.

O próximo passo é usar `ticket = Queue.get_ticket!(id)` para recuperar o ticket pelo `id`. Vale lembrar que, se não existir nenhum ticket com esse `id`, um erro 404 será gerado automaticamente, como vimos em uma aula anterior.

Definimos nosso `form` como um changeset que recebe o ticket original. No formulário de criação usamos `Ticket.changeset(%Ticket{})`, ou seja, o ticket vazio porque naquele momento não havia nenhum ticket. Como estamos trabalhando com edição, todos os nossos changesets receberão o ticket que está sendo editado.

Note também que no assign passamos `ticket`. Vamos usar esse assign não só no nosso HEEx como também em outros eventos.

### O evento de validação

```elixir
@impl true
def handle_event("validate", %{"ticket" => ticket_params}, socket) do
  changeset = Queue.change_ticket(socket.assigns.ticket, ticket_params)
  {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
end
```

Você não está vendo errado — isso é uma cópia exata do evento `validate` da nossa view `TicketLive.New`.

### O evento de salvar

```elixir
def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, ticket_params)
end

defp save_ticket(socket, ticket_params) do
  case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
    {:ok, ticket} ->
      {:noreply,
       socket
       |> put_flash(:info, "Ticket updated successfully")
       |> push_navigate(to: ~p"/tickets/#{ticket}")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

Mais uma vez nosso evento é uma cópia do evento de criação de ticket com apenas pequenas mudanças no caso de sucesso!

### O `render/1`

```elixir
@impl true
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash}>
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage ticket records in your database.</:subtitle>
    </.header>

    <.form for={@form} id="ticket-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:called_at]} type="datetime-local" label="Called at" />
      <footer>
        <.button phx-disable-with="Saving..." variant="primary">Save Ticket</.button>
        <.button navigate={~p"/tickets/#{@ticket}"}>Cancel</.button>
      </footer>
    </.form>
  </Layouts.app>
  """
end
```

A única diferença em relação à nossa `TicketLive.New` é que o botão "Cancel" redireciona para a `TicketLive.Show` em vez de `TicketLive.Index`.

### Atualizando nosso router

Abra seu arquivo de router e adicione a rota `live "/tickets/:id/edit", TicketLive.Edit, :edit`. Seu router deve ficar assim:

```elixir
# ...
scope "/", LineupWeb do
  pipe_through :browser

  live "/", TicketLive.Index, :index
  live "/tickets/new", TicketLive.New, :new
  live "/tickets/:id", TicketLive.Show, :show
  live "/tickets/:id/edit", TicketLive.Edit, :edit
end
# ...
```

## Adicionando um link para o formulário

Temos uma página, mas nossos usuários não sabem dela. Abra sua `TicketLive.Show` e atualize apenas o componente `<.header>` para adicionar mais um botão dentro de `<:actions>`:

```elixir
<.header>
  Ticket {@ticket.id}
  <:subtitle>This is a ticket record from your database.</:subtitle>
  <:actions>
    <.button navigate={~p"/"}>
      <.icon name="hero-arrow-left" />
    </.button>
    <.button variant="primary" navigate={~p"/tickets/#{@ticket}/edit"}>
      <.icon name="hero-pencil-square" /> Edit ticket
    </.button>
  </:actions>
</.header>
```

Também vamos atualizar a `TicketLive.Index` para mostrar um link rápido para editar tickets:

```elixir
<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="Called at">{ticket.called_at}</:col>
  <:action :let={{_id, ticket}}>
    <div class="sr-only">
      <.link navigate={~p"/tickets/#{ticket}"}>Show</.link>
    </div>
    <.link navigate={~p"/tickets/#{ticket}/edit"}>Edit</.link>
  </:action>
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

%{
title: ~H"O que era esse 'sr-only'?",
description: ~H"""
Esta classe CSS é frequentemente usada para esconder elementos de forma que ainda sejam compreendidos por leitores de tela (SR), para que usuários entendam que há um item clicável, ao contrário de simplesmente tornar o elemento da linha da tabela (tr) clicável — pois semanticamente falando, o <code>tr</code> não foi pensado para ser algo que se clica.
"""
} %% .callout

## Adicionando nossos testes finais

Como você já deve ter imaginado, como nossa view de edição é muito similar ao formulário de novo ticket, esses testes também serão parecidos. Começando pelo `Lineup.QueueTest`:

```elixir
test "update_ticket/2 with valid data updates the ticket" do
  ticket = ticket_fixture()
  update_attrs = %{called_at: ~U[2026-04-28 16:00:00Z]}

  assert {:ok, %Ticket{} = ticket} = Queue.update_ticket(ticket, update_attrs)
  assert ticket.called_at == ~U[2026-04-28 16:00:00Z]
end
```

Este caso de teste é completamente óbvio a esta altura do curso. Quanto ao `LineupWeb.TicketLiveTest`, primeiro adicione isso no topo do arquivo junto com o `@create_attrs` existente:

```elixir
@create_attrs %{called_at: "2026-04-27T16:00:00Z"}
@update_attrs %{called_at: "2026-05-01T16:00:00Z"}
```

Em seguida, vamos adicionar dentro de `describe "Index" do`:

```elixir
test "updates ticket in listing", %{conn: conn, ticket: ticket} do
  {:ok, index_live, _html} = live(conn, ~p"/")

  assert {:ok, edit_form_live, _html} =
           index_live
           |> element("#tickets-#{ticket.id} a", "Edit")
           |> render_click()
           |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")

  assert render(edit_form_live) =~ "Edit Ticket"

  assert {:ok, index_live, _html} =
           edit_form_live
           |> form("#ticket-form", ticket: @update_attrs)
           |> render_submit()
           |> follow_redirect(conn, ~p"/tickets/#{ticket}")

  html = render(index_live)
  assert html =~ "Ticket updated successfully"
end
```

E, por fim, dentro de `describe "Show" do` adicione:

```elixir
test "updates ticket and returns to show", %{conn: conn, ticket: ticket} do
  {:ok, show_live, _html} = live(conn, ~p"/tickets/#{ticket}")

  assert {:ok, edit_form_live, _} =
            show_live
            |> element("a", "Edit")
            |> render_click()
            |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")

  assert render(edit_form_live) =~ "Edit Ticket"

  assert {:ok, show_live, _html} =
            edit_form_live
            |> form("#ticket-form", ticket: @update_attrs)
            |> render_submit()
            |> follow_redirect(conn, ~p"/tickets/#{ticket}")

  html = render(show_live)
  assert html =~ "Ticket updated successfully"
end
```

Neste ponto, tudo que foi usado aqui já foi explicado nas aulas anteriores!

## Código final

Pronto! Nossa aplicação tem um CRUD completo. Ainda há algumas coisas que podem ser melhoradas e vamos analisar isso em outra seção deste curso, mas se você acompanhou o curso até aqui já tem conhecimento suficiente para criar o seu próximo CRUD!

Se você sentiu dificuldade de acompanhar o código nesta aula, pode ver o código pronto usando `git checkout editing-data-done` ou clonando em outra pasta com `git clone https://github.com/adopt-liveview/lineup.git --branch editing-data-done`.

## Resumindo!

- Usando `Repo.update/2` podemos atualizar um ticket passando um changeset.
- Um formulário LiveView de edição pode ser extremamente similar a um de criação de dados.
- Você já sabe fazer um CRUD completo em LiveView 😉.
- Será que podemos fazer algo sobre ter duas LiveViews com muito código duplicado?