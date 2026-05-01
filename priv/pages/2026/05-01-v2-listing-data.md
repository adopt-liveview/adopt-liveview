%{
title: "Listando tickets",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Organizando nosso projeto e listando nossos tickets",
previous_page_id: "v2-saving-data",
next_page_id: "v2-show-data"
}

---

Na aula anterior criamos alguns tickets! Vamos criar uma página simples para listar os tickets salvos.

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch first-context-test-done`</code>.
"""
} %% .callout

## De volta ao nosso Context

Lembre-se que todas as operações relacionadas à modificação do nosso domínio de tickets estarão concentradas no contexto `Queue`. Neste momento precisamos de uma função para listar todos os tickets. Abra `lib/lineup/queue.ex` e adicione o método `list_tickets/0`:

```elixir
defmodule Lineup.Queue do
  @moduledoc """
  The Queue context.
  """

  import Ecto.Query, warn: false
  alias Lineup.Repo

  alias Lineup.Queue.Ticket

  @doc """
  Returns the list of tickets.

  ## Examples

      iex> list_tickets()
      [%Ticket{}, ...]

  """
  def list_tickets do
    Repo.all(Ticket)
  end

  # Other methods...
end
```

Para listar linhas do nosso banco de dados, usamos a função [`Repo.all/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:all/2) que recebe uma query Ecto e retorna todas as linhas. O próprio módulo `Ticket` é considerado uma query e, neste caso, representa `select * from tickets`.

### Testando no `iex`

Abra seu `iex -S mix` e execute `Lineup.Queue.list_tickets()`:

```elixir
$ iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Compiling 2 files (.ex)
Generated lineup app
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Lineup.Queue.list_tickets()
[debug] QUERY OK source="tickets" db=0.7ms decode=0.8ms idle=1809.8ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 []
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
[
  %Lineup.Queue.Ticket{
    __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
    id: 1,
    called_at: ~U[2026-04-21 13:07:00Z],
    inserted_at: ~U[2026-04-28 16:03:37Z],
    updated_at: ~U[2026-04-28 16:03:37Z]
  }
]
```

Como você pode ver, nossa função funciona. Podemos prosseguir e aplicá-la em uma nova LiveView.

## De volta à nossa `TicketLive.Index`

Para listar nossos tickets, usaremos a `LineupWeb.TicketLive.Index`. Projetos Phoenix gostam de seguir este padrão: `YourAppWeb.NomeDaCoisa.{Index, Show, New, Edit}` (ou será que não? Vamos discutir isso mais tarde). Vamos alterar nossa LiveView `Index`:

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
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tickets
      </.header>

      <.table
        id="tickets"
        rows={@streams.tickets}
      >
        <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
      </.table>
    </Layouts.app>
    """
  end

  defp list_tickets() do
    Queue.list_tickets()
  end
end
```

### Lembra das streams?

Na aula sobre renderização de listas discutimos streams como uma forma otimizada de renderizar itens em HEEx. Naquela aula havia um pouco mais de complexidade no código porque precisávamos adicionar um `id` a cada elemento. Mas neste caso, como estamos trabalhando com um banco de dados, todos os elementos já têm um `id`, então podemos definir uma stream de tickets sem complicações.

### Usando o componente `<.table>`

Projetos Phoenix contêm um componente muito poderoso chamado `<.table>` no `CoreComponents`. Ao longo das aulas de CRUD aprenderemos mais sobre ele.

```elixir
<.table id="tickets" rows={@streams.tickets}> ... </.table>
```

No momento, tudo que você precisa entender é que este componente funciona muito bem com streams. Passamos dois assigns ao componente: um `id` único e `rows` que recebe a stream de `tickets`.

```elixir
<:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
```

Dentro do componente, podemos ver que usamos o slot `<:col>`. Cada um desses slots requer um atributo `label` para definir o nome da coluna na tabela e recebe o atributo especial `:let` para acessar `{id, elemento}`. No momento podemos ignorar o `id` e receber o `ticket` para renderizar o conteúdo daquela coluna para cada ticket. Se tudo isso parecer muito estranho para você, pode dar uma olhada na nossa aula de renderização de listas com slots na seção de componentes. Também vale mencionar que na `<:col>` de "Called at" usamos short circuit em `ticket.called_at || "n/a"` para renderizar a data ou mostrar "n/a", pois se `called_at` for `nil` nada será renderizado — é assim que o HEEx interpreta o átomo `nil`.

Sucesso! Abra seu navegador e veja que na página inicial todos os seus tickets estão listados. Mas espera, como o usuário vai até a página de novo ticket? Ele não vai adivinhar a rota!

### Conectando as páginas com links

Vá até sua `TicketLive.Index` e modifique apenas a seção `<.header>` um pouco:

```elixir
<.header>
  Listing Tickets
  <:actions>
    <.button variant="primary" navigate={~p"/tickets/new"}>
      <.icon name="hero-plus" /> New Ticket
    </.button>
  </:actions>
</.header>
```

Usamos o componente `<.header>`, que também vem do `CoreComponents`, não só para dar um título à nossa página de listagem de tickets como também para usar seu slot `<:action>` para adicionar um link para nossa página de novo ticket.

## Atualizando nosso teste de contexto

Agora que nosso módulo de contexto tem uma nova função, podemos testá-la também. Vá até `test/lineup/queue_test.exs` e adicione um novo caso de teste dentro do seu bloco describe:

```elixir
defmodule Lineup.QueueTest do
  use Lineup.DataCase

  alias Lineup.Queue

  describe "tickets" do
    alias Lineup.Queue.Ticket

    import Lineup.QueueFixtures

    test "list_tickets/0 returns all tickets" do
      ticket = ticket_fixture()
      assert Queue.list_tickets() == [ticket]
    end

    # other tests...
  end
end
```

Então verifique com `mix test`:

```sh
$ mix test test/lineup/queue_test.exs
Compiling 3 files (.ex)
Generated lineup app
Running ExUnit with seed: 684602, max_cases: 28

...
Finished in 0.02 seconds (0.00s async, 0.02s sync)
3 tests, 0 failures
```

Ótimo, todos os testes estão passando!

## Nosso primeiro teste de LiveView!

De forma similar a como criamos um teste para nosso módulo de contexto, vamos precisar criar um módulo de teste com um nome parecido. Como nossas LiveViews de CRUD são bem simples e relacionadas entre si, vamos criar um único módulo em vez de um por LiveView.

Crie `test/lineup_web/live/ticket_live_test.exs` com o seguinte código:

```elixir
defmodule LineupWeb.TicketLiveTest do
  use LineupWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lineup.QueueFixtures

  @create_attrs %{called_at: "2026-04-27T16:00:00Z"}

  defp create_ticket(_) do
    ticket = ticket_fixture()

    %{ticket: ticket}
  end

  describe "Index" do
    setup [:create_ticket]

    test "lists all tickets", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Listing Tickets"
    end

    test "saves new ticket", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      assert {:ok, new_ticket_live, _} =
               index_live
               |> element("a", "New Ticket")
               |> render_click()
               |> follow_redirect(conn, ~p"/tickets/new")

      assert render(new_ticket_live) =~ "New Ticket"

      assert {:ok, index_live, _html} =
                new_ticket_live
               |> form("#ticket-form", ticket: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/")

      html = render(index_live)
      assert html =~ "Ticket created successfully"
    end
  end
end
```

### `ConnCase`

A primeira coisa no nosso módulo é o uso de um helper chamado `LineupWeb.ConnCase` que, assim como o `LineupWeb.DataCase`, vive dentro do seu repositório. A principal diferença é que o `ConnCase` vai trazer funções úteis para testar como as requisições HTTP do Phoenix funcionam sem precisar rodar o servidor de verdade. Logo abaixo também fazemos `import Phoenix.LiveViewTest` que traz ainda mais helpers de teste específicos para LiveViews.

No topo criamos uma função chamada `create_ticket/1` que simplesmente ignora o primeiro argumento. Por enquanto você não precisa saber muito sobre ela, mas vamos falar sobre isso em outra aula. O que você precisa entender é que ela vai garantir que nosso banco de dados sempre terá pelo menos um `%Ticket{}` armazenado. Essa função é implicitamente usada dentro do nosso bloco `describe` pelo `setup [:create_ticket]`, que diz ao ExUnit para sempre chamá-la antes de executar cada teste.

Nosso primeiro caso de teste recebe como argumento um mapa que inclui `conn`, que é como vamos simular uma requisição ao nosso servidor Phoenix. Se você não conhece o `conn` do Plug, tudo bem — pense nele como uma conexão simulada.

Nossos testes de LiveView frequentemente usarão um helper chamado [`live/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live/4). Esse helper converte um `conn` (que é uma requisição HTTP simples simulada) em uma conexão LiveView simulada. Seu retorno é uma 3-tupla com `:ok`, a LiveView simulada e o HTML renderizado no início. Vale mencionar que, como LiveViews são reativas, podemos sempre obter o HTML de volta usando `render(live)` (assumindo que chamamos nossa LiveView de `live`).

No nosso teste `"list all tickets"` apenas verificamos que o texto do cabeçalho aparece. Vamos melhorar isso mais tarde. Já no teste `"saves new ticket"` não só começamos renderizando a `index_live` como também simulamos um clique no link "New ticket", seguimos o redirecionamento para gerar uma **nova** live chamada `new_ticket_live` e dentro dela enviamos o formulário e seguimos o redirect de volta para a `index_live` com uma mensagem flash "Ticket created successfully".

Tome seu tempo para se familiarizar com essas funções, mas não se preocupe — você sempre pode buscar outros exemplos na sua base de código ou na internet quando se perder sobre o que pode fazer para testar LiveViews. Dica: salve este link de documentação para ter todas as funções do `LiveViewTest` sempre que precisar: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html

## Código final

Agora sua aplicação não só está mais organizada em termos de pastas como o usuário também terá uma boa experiência de navegação inicial.

Se você sentiu dificuldade de acompanhar o código nesta aula, pode ver o código completo usando `git checkout listing-data-done` ou clonando em outra pasta com `git clone https://github.com/adopt-liveview/lineup.git --branch listing-data-done`.

## Resumindo!

- Usando `Repo.all/2` podemos listar o resultado de uma query Ecto.
- O módulo `Ticket` pode ser considerado uma query Ecto no formato `select * from tickets`.
- Projetos Phoenix gostam de seguir este padrão: `YourAppWeb.NomeDaCoisa.{Index, Show, New ou Edit}`.
- Para manter suas pastas de LiveView mais organizadas no projeto, usamos o formato `lib/your_app_web/live/seu_modelo/{index.ex, new.ex, edit.ex, show.ex}`, como veremos em aulas futuras.
- Quando se trabalha com bancos de dados, é muito fácil usar streams em LiveView porque os elementos já vêm com um `id`.
- O componente `<.table>` é muito poderoso para simplificar tabelas com itens, como veremos no futuro.
- No seu `router.ex`, prefira Live Actions entre `:new`, `:index`, `:edit` e `:show`, como veremos nas próximas aulas.
- O componente `<.header>` é muito útil para titular suas páginas e também pode conter um slot `<:actions>` para simplificar a adição de botões de ação, como usamos para adicionar o botão de criar ticket.
- Em testes de LiveViews, usamos tanto `use MyappWeb.ConnCase` quanto `import Phoenix.LiveViewTest`.
- `ConnCase` é onde helpers para simular requisições HTTP ao Phoenix são importados.
- `Phoenix.LiveViewTest` é onde existem helpers para testar LiveViews.
- Você pode simular interações com LiveView usando `live/3` para entrar em uma view, `element/3` para encontrar algum HTML, `render_click/1` para acionar um link/botão e `follow_redirect/3` para criar cenários de teste dos fluxos dos seus usuários.