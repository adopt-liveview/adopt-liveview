%{
title: "Exibindo um ticket",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Exibindo um ticket específico no seu projeto LiveView",
previous_page_id: "v2-listing-data",
next_page_id: "v2-deleting-data"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch listing-data-done`</code>.
"""
} %% .callout

Na aula anterior criamos a lista de tickets da nossa aplicação. Nesta aula vamos finalizar a parte Read do nosso CRUD: vamos criar a página que exibe um ticket específico.

## Mais uma vez, o Context

A esta altura você provavelmente já adivinhou que vamos começar editando o módulo de contexto em `lib/lineup/queue.ex`. Abra este arquivo e adicione a seguinte função no final:

```elixir
defmodule Lineup.Queue do
  # ...
  
  @doc """
  Gets a single ticket.

  Raises `Ecto.NoResultsError` if the Ticket does not exist.

  ## Examples

      iex> get_ticket!(123)
      %Ticket{}

      iex> get_ticket!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ticket!(id), do: Repo.get!(Ticket, id)
end
```

Desta vez você pode notar que o nome da função é um pouco diferente: ela tem um ponto de exclamação no final. Não só a função que estamos criando mas também a função [`Repo.get/3`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:get!/3) têm um ponto de exclamação. Em Elixir chamamos essas de "bang functions".

### Entendendo bang functions

Enquanto você pode ter percebido que algumas funções Elixir preferem retornar `{:ok, data}` ou `{:error, data}`, as bang functions preferem retornar os dados diretamente ou lançar uma exceção. Vamos ver isso na prática. Entre no Elixir Interativo usando `iex -S mix`. Vamos assumir que seu sistema tem um ticket com ID 1.

```elixir
[I] ➜ iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Generated lineup app
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> Lineup.Queue.get_ticket!(1)
[debug] QUERY OK source="tickets" db=0.7ms decode=0.5ms idle=705.3ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 WHERE (t0."id" = ?) [1]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
%Lineup.Queue.Ticket{
  __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
  id: 1,
  called_at: ~U[2026-04-21 13:07:00Z],
  inserted_at: ~U[2026-04-28 16:03:37Z],
  updated_at: ~U[2026-04-28 16:03:37Z]
}

iex(2)> Lineup.Queue.get_ticket!(100000000)
[debug] QUERY OK source="tickets" db=0.0ms idle=1359.2ms
SELECT t0."id", t0."called_at", t0."inserted_at", t0."updated_at" FROM "tickets" AS t0 WHERE (t0."id" = ?) [100000000]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
** (Ecto.NoResultsError) expected at least one result but got none in query:

from t0 in Lineup.Queue.Ticket,
  where: t0.id == ^100_000_000

    (ecto 3.13.5) lib/ecto/repo/queryable.ex:173: Ecto.Repo.Queryable.one!/3
    iex
```

Quando usamos a função `Lineup.Queue.get_ticket!/1` com o ID 1 que existe, o resultado é o próprio ticket, sem o formato `{:ok, ticket}`. Quando usamos com um ID inexistente, o resultado é uma exceção `Ecto.NoResultsError`. Qual é a vantagem de usar este formato em vez de simplesmente tratar o erro nós mesmos?

### Tratamento automático de exceções

Internamente, o framework Phoenix consegue entender que `Ecto.NoResultsError` é uma exceção que significa que o dado esperado não existe, então esta página é um erro 404. Este tratamento vem da biblioteca `phoenix_ecto`, que já estava instalada no seu projeto e que também instalamos nas aulas anteriores. Confira diretamente no [código-fonte](https://github.com/phoenixframework/phoenix_ecto/blob/3bdb207e31a242d3286faf117c95a3c40a048dc5/lib/phoenix_ecto/plug.ex#L1-L6) quais exceções são tratadas automaticamente:

```elixir
errors = [
  {Ecto.CastError, 400},
  {Ecto.Query.CastError, 400},
  {Ecto.NoResultsError, 404},
  {Ecto.StaleEntryError, 409}
]
```

Se você quiser tratar automaticamente exceções diferentes, dê uma olhada na documentação de [Custom Exceptions](https://hexdocs.pm/phoenix/custom_error_pages.html#custom-exceptions) no Phoenix. A principal vantagem aqui é: se o Phoenix trata o erro, nossa LiveView pode focar apenas no fluxo de sucesso.

## Criando nossa `TicketLive.Show`

Dentro da pasta `lib/lineup_web/live/ticket_live`, crie um arquivo chamado `show.ex` com o seguinte conteúdo:

```elixir
defmodule LineupWeb.TicketLive.Show do
  use LineupWeb, :live_view

  alias Lineup.Queue

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Ticket {@ticket.id}
        <:subtitle>This is a ticket record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Called at">{@ticket.called_at}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Ticket")
     |> assign(:ticket, Queue.get_ticket!(id))}
  end
end
```

### O componente `<.list>`

Dentro do nosso `render/1`, o único componente novo é o `<.list>`, que também vem do `CoreComponents`. Para cada slot `<:item>`, ele recebe um `title` e renderiza o inner block. Este componente é útil para exibir coisas no formato `chave-valor`.

### Atualizando nosso router

Abra seu `router.ex` e adicione a nova rota abaixo das outras:

```elixir
live "/tickets/:id", TicketLive.Show, :show
```

Mais uma vez, seguimos não só a convenção de nomenclatura para a LiveView como também para a live action `:show`.

Abra uma aba em [http://localhost:4000/tickets/1](http://localhost:4000/tickets/1) e veja seu ticket sendo exibido. Da mesma forma, troque para um ID inexistente como [http://localhost:4000/tickets/1123](http://localhost:4000/tickets/1123) e veja a mensagem de erro.

### Mensagens de erro bonitas no ambiente de desenvolvimento

Vale mencionar que na página com o ID inexistente você deve ter visto uma mensagem de erro bem formatada com código sendo exibido e muito mais informações. O Phoenix traz essa tela de erro apenas no ambiente de desenvolvimento. Em produção, você verá apenas uma mensagem genérica de "Not found" porque não queremos vazar nenhuma informação sobre nosso código para os usuários.

Se quiser ver como fica a mensagem genérica sem precisar fazer deploy, você pode abrir `config/dev.exs`, mudar `debug_errors: true` para `false` e reiniciar o servidor.

## Criando um link da lista para o ticket

Mais uma vez, não devemos fazer nossos usuários adivinharem onde as coisas estão. Abra sua `TicketLive.Index` e edite apenas a tabela dentro do `render/1` para:

```elixir
<.table
  id="tickets"
  rows={@streams.tickets}
  row_click={fn {_id, ticket} -> JS.navigate(~p"/tickets/#{ticket}") end}
>
  <:col :let={{_id, ticket}} label="ID">{ticket.id}</:col>
  <:col :let={{_id, ticket}} label="Called at">{ticket.called_at || "n/a"}</:col>
</.table>
```

Agora, quando o usuário clicar em uma linha da tabela, ele será levado para `TicketLive.Show`. O componente `<.table>` aceita um assign chamado `row_click`, que recebe uma função anônima e passa `{id, ticket}` para ela. Podemos ignorar o `id` e usar o `ticket` diretamente.

### `JS.navigate/2`

Aqui introduzimos um novo JS Command: [`JS.navigate/1`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#navigate/1). Ele recebe uma URL e simplesmente navega o usuário até ela.

### `Phoenix.Param`

Você pode ter ficado surpreso que a URL é `~p"/tickets/#{ticket}"` em vez de `~p"/tickets/#{ticket.id}"` (note o `.id`). Isso acontece porque o Phoenix sabe como converter um schema Ecto como `%Ticket{}` para uma URL lendo seu ID. Apenas uma [curiosidade interna do framework](https://hexdocs.pm/phoenix/Phoenix.Param.html) para você saber.

## Adicionando mais testes!

Não poderíamos encerrar esta aula sem adicionar alguns testes. Adicione ao `Lineup.QueueTest` o seguinte caso:

```elixir
test "get_ticket!/1 returns the ticket with given id" do
  ticket = ticket_fixture()
  assert Queue.get_ticket!(ticket.id) == ticket
end
```

Não há nada de novo aqui, apenas um teste simples. Quanto ao `LineupWeb.TicketLiveTest`, adicione um novo bloco describe assim:

```elixir
describe "Show" do
  setup [:create_ticket]

  test "displays ticket", %{conn: conn, ticket: ticket} do
    {:ok, _show_live, html} = live(conn, ~p"/tickets/#{ticket}")

    assert html =~ "Show Ticket"
  end
end
```

Por enquanto vamos apenas verificar que esta página renderiza corretamente e exibe seu título. Espera, tem algo diferente neste teste! Até agora estávamos recebendo nos casos de teste `%{conn: conn}` mas desta vez há também uma variável `ticket`? A explicação é bem simples. No nosso pipeline de `setup` temos `:create_ticket` que está definido como:

```elixir
defp create_ticket(_) do
  ticket = ticket_fixture()

  %{ticket: ticket}
end
```

Em qualquer função de setup que você escrever, se retornar um mapa ele será automaticamente mesclado com o contexto do seu teste. Então se você tivesse escrito `%{ticket: ticket, user_id: 1}`, mais tarde nos seus casos de teste você poderia fazer o match `%{conn: conn, ticket: ticket, user_id: user_id}`. Caso você esteja se perguntando, o `conn` vem de uma função `setup/1` no `LineupWeb.ConnCase`!

## Código final

Usando a rota para exibir um ticket, conseguimos aprender muitas coisas relacionadas ao framework Phoenix e à linguagem de programação Elixir.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto desta aula usando `git checkout show-data-done` ou clonando em outra pasta usando `git clone https://github.com/adopt-liveview/first-crud.git --branch show-data-done`.

## Resumindo!

- Podemos usar `Repo.get!/3` para buscar dados do banco de dados usando um ID.
- Funções em Elixir com nomes terminados em ponto de exclamação são chamadas de bang functions.
- Bang functions não usam o formato conveniente de `{:ok, data}` e `{:error, error}`; elas simplesmente retornam os dados ou lançam uma exceção.
- O Phoenix consegue tratar automaticamente algumas exceções Ecto e convertê-las em erros HTTP, tornando nosso código mais simples pois podemos focar apenas no caso de sucesso.
- O componente `<.list>` é útil para renderizar estruturas simples de chave-valor.
- No modo de desenvolvimento, o Phoenix exibe mensagens de erro bonitas no navegador para auxiliar o desenvolvedor, mas em produção as mensagens são genéricas (porém customizáveis).
- O componente `<.table>` aceita um assign `row_click` com uma função que é executada quando uma linha da tabela é clicada.
- O JS Command `JS.navigate/1` funciona exatamente como o componente `<.link navigate={...}>`, só que de forma programática.
- O Phoenix consegue converter automaticamente schemas Ecto em parâmetros de URL lendo seu ID.
- Funções de setup de testes podem retornar mapas com dados que estarão acessíveis nos casos de teste.