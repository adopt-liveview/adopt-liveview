%{
title: "Salvando dados com Ecto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Persistindo dados com banco de dados em projetos LiveView",
previous_page_id: "v2-cleanup",
next_page_id: "v2-first-context-test"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch cleanup-done`</code>.
"""
} %% .callout

Finalmente vamos começar a implementar nosso CRUD (Create-Read-Update-Delete). Atualmente nosso projeto já tem instalado tanto LiveView quanto Ecto, então vamos focar em como colocar isso em prática. Nesta aula vamos aprender como persistir nosso ticket no banco de dados.

## Conceitos importantes de Ecto

Antes de começarmos código novo, vamos explorar um pouco do que o projeto Phoenix já instalou para você e, ao mesmo tempo, conversar sobre os padrões do projeto.

### Introduzindo o `Repo`

Se você for até o arquivo `lib/lineup/repo.ex`, verá o seguinte código:

```elixir
defmodule Lineup.Repo do
  use Ecto.Repo,
    otp_app: :lineup,
    adapter: Ecto.Adapters.SQLite3
end
```

O Ecto usa um Design Pattern chamado Repository para acessar o banco de dados. A regra é simples: se você pretende executar uma query, vai usar este módulo. Sempre que o banco de dados precisar ser acessado você verá algo como `Repo.insert()` ou `Repo.one()`.

O Phoenix automaticamente gerou este módulo `Lineup.Repo`. A nomenclatura será sempre no formato `SeuProjeto.Repo`. Dentro dele o `use Ecto.Repo` prepara o módulo com funções como `Repo.insert` e as opções passadas definem a configuração do nosso Repo. A opção `otp_app` contém o nome do nosso projeto Mix, `:lineup`, e como adaptador usamos `Ecto.Adapters.SQLite3`.

### Migrando o banco de dados

Para gerenciar modificações no banco de dados, o Ecto usa o padrão de projeto chamado [schema migrations](https://en.wikipedia.org/wiki/Schema_migration). A lógica de migrations é simples: sempre que você precisar modificar a estrutura do seu banco de dados, você gera uma migration que instrui o Ecto sobre o que precisa ser feito.

Vamos criar sua primeira migration: queremos criar a tabela de tickets. Usando seu terminal execute `mix ecto.gen.migration create_tickets`. O resultado será algo como:

```bash
* creating priv/repo/migrations/20260428160027_create_tickets.exs
```

Não se preocupe se o nome não for exatamente igual. As migrations possuem um timestamp no início do seu nome para deixar clara a ordem em que devem ser executadas. Neste momento sua migration deve estar com um código similar ao seguinte:

```elixir
defmodule Lineup.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do

  end
end
```

Vamos modificá-la para:

```elixir
defmodule Lineup.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :called_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
```

Dentro do nosso módulo devemos ter um método `change/0`. Este método é usado para especificar o que mudou no seu banco de dados. O módulo `Ecto.Migration` que importamos no topo da nossa migration contém esta e outras funções DDL (Data Definition Language) preparadas para operações comuns de modificar a estrutura do banco.

Dentro do `change/0` podemos usar [`create/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#create/2) para especificar que estamos criando algo, [`table/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#table/2) para indicar que estamos criando uma nova tabela chamada `tickets` e [`add/3`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#add/3) para definir as colunas dentro desta tabela.

Quando sua migration estiver pronta e salva, execute `mix ecto.migrate` para rodá-la:

```bash
$ mix ecto.migrate

08:56:48.950 [info] == Running 20260428160027 Lineup.Repo.Migrations.CreateTickets.change/0 forward

08:56:48.952 [info] create table tickets

08:56:48.955 [info] == Migrated 20260428160027 in 0.0s
```

%{
title: "Como desfazer uma migration?",
type: :warning,
description: ~H"""
Se algo de errado acontecer ou se você achar que sua migration estava incorreta, você sempre pode executar <code>`mix ecto.rollback`</code> para desfazer as migrations aplicadas na última vez que você executou <code>`mix ecto.migrate`</code> (mesmo que tenham sido mais de uma). <br><br>Se você estiver curioso sobre como o Ecto sabe desfazer, a resposta é bem simples: se sua migration tem um método <code>`create/2`</code> com <code>`table/2`</code> ele sabe que o inverso disso é apagar uma tabela. Por isso podemos criar uma migration apenas com a função <code>`change/0`</code> ao invés de <code>`up`</code> e <code>`down`</code> como em outros frameworks, apesar de que o Ecto opcionalmente aceita esses callbacks se você tiver alguma migration específica do seu banco de dados atual.
"""
} %% .callout

### Criando nosso `Ecto.Schema`

Crie `lib/lineup/queue/ticket.ex`. Talvez você precise criar a pasta `queue` também. Escreva assim:

```elixir
defmodule Lineup.Queue.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :called_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:called_at])
    |> validate_required([:called_at])
  end
end
```

Anteriormente usamos um `embedded_schema` no curso de fundamentos deste site, pois ele é útil quando você não pretende trabalhar com um banco de dados. Para fazer este schema funcionar com um banco, a modificação necessária é muito simples! Usamos o macro [`schema/2`](https://hexdocs.pm/ecto/Ecto.Schema.html#schema/2) que recebe o nome da tabela como primeiro argumento para que, quando usarmos nosso `Repo`, ele saiba de onde ler/escrever os dados.

### Seu primeiro módulo de contexto

Como mencionado anteriormente, o módulo principal de lógica de negócio do nosso sistema de filas será `Lineup.Queue`, por isso nosso módulo `Ticket` vive em `Lineup.Queue.Ticket`. No Phoenix, chamamos de Context Modules os módulos que encapsulam funções que gerenciam uma parte da lógica de negócio da nossa aplicação. O contexto `Queue` é responsável por gerenciar nossos tickets. Se tivéssemos um contexto chamado `Accounts`, ele seria responsável por gerenciar contas de usuário. Cada contexto pode ter zero ou mais schemas e geralmente a nomenclatura será `SeuProjeto.SeuContexto` e `SeuProjeto.SeuContexto.SeuSchema`.

Dentro da pasta `lib/lineup` crie um arquivo chamado `queue.ex` com o seguinte conteúdo:

```elixir
defmodule Lineup.Queue do
  alias Lineup.Repo
  alias Lineup.Queue.Ticket

  @doc """
  Creates a ticket.

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
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ticket changes.

  ## Examples

      iex> change_ticket(ticket)
      %Ecto.Changeset{data: %Ticket{}}

  """
  def change_ticket(%Ticket{} = ticket, attrs \\ %{}) do
    Ticket.changeset(ticket, attrs)
  end
end
```

Tudo relacionado a tickets estará aqui. O Phoenix se inspira muito em Domain-Driven Design (DDD), onde cada parte da sua aplicação foca no seu domínio específico.

Usando `alias` para escrever um pouco menos de código, criamos uma função que recebe `attrs` e os valida com nosso `Ticket.changeset/2`, em seguida tentando inserir no nosso banco de dados. Esta função tem dois possíveis resultados: `{:ok, %Ticket{...}}` se tudo der certo ou `{:error, %Ecto.Changeset{...}}` se houver erros de validação. Também criamos uma função auxiliar para criar changesets dos nossos tickets.

%{
title: ~H"Por que usar <code>`Queue.change_ticket/2`</code> se alguém poderia facilmente usar <code>`Ticket.changeset/2`</code>?",
description: ~H"""
Usamos nosso módulo de contexto para esconder a lógica de negócio o máximo possível das nossas LiveViews. Por enquanto a função está apenas roteando os argumentos para a função de changeset, mas isso não significa que será sempre assim. Se precisarmos adicionar alguma lógica de negócio extra para iniciar um changeset de um Ticket, podemos focar em melhorar nosso <code>`change_ticket/2`</code> em vez de quebrar a simplicidade da função <code>`Ticket.changeset/2`</code>.
"""
} %% .callout

### Testando nosso módulo diretamente do terminal

Podemos testar tudo que construímos até agora sem sequer começar a mexer na nossa LiveView! Como construímos um módulo `Lineup.Queue` que não depende de nada relacionado à web, podemos simplesmente iniciar um terminal interativo com o código mix do nosso projeto e executar a função `create_ticket/2`.

Usando seu terminal execute o comando indicado pelo prompt `$`:

```elixir
$ iex -S mix
Erlang/OTP 28 [erts-16.0.1] [source] [64-bit] [smp:14:14] [ds:14:14:10] [async-threads:1] [jit]
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

Usando `iex -S mix` entramos no modo Interactive Elixir (`iex`) contendo todas as funções do nosso projeto. No início da última linha você pode ver que `iex(1)>` virou seu novo prompt de comando. Vamos criar um alias para nosso contexto:

```elixir
iex(1)> alias Lineup.Queue
Lineup.Queue
iex(2)>
```

Agora podemos escrever `Queue.` ao invés de `Lineup.Queue.`. Vamos criar nosso primeiro ticket! Execute: `Queue.create_ticket(%{})`.

```elixir
iex(2)> Queue.create_ticket(%{})
{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{},
   errors: [called_at: {"can't be blank", [validation: :required]}],
   data: #Lineup.Queue.Ticket<>,
   valid?: false,
   ...
 >}
```

Ops! Quando definimos nosso schema dissemos que `called_at` era obrigatório! Mas na nossa aplicação real você precisa pegar a senha primeiro e só então será chamado. Sem sair do seu shell `iex`, altere em `lib/lineup/queue/ticket.ex` e salve o arquivo:

```diff
- |> validate_required([:called_at])
+ |> validate_required([])
```

Em seguida execute `recompile` dentro do `iex` e tente criar o ticket novamente. Dica: você pode pressionar a seta para cima para encontrar comandos anteriores no `iex`.

```elixir
iex(3)> recompile
Compiling 1 file (.ex)
Generated lineup app
:ok

iex(4)> Queue.create_ticket(%{})
[debug] QUERY OK source="tickets" db=0.7ms decode=0.6ms idle=515.9ms
INSERT INTO "tickets" ("inserted_at","updated_at") VALUES (?1,?2) RETURNING "id" [~U[2026-04-29 19:23:38Z], ~U[2026-04-29 19:23:38Z]]
↳ :elixir.eval_external_handler/3, at: src/elixir.erl:365
{:ok,
 %Lineup.Queue.Ticket{
   __meta__: #Ecto.Schema.Metadata<:loaded, "tickets">,
   id: 2,
   called_at: nil,
   inserted_at: ~U[2026-04-29 19:23:38Z],
   updated_at: ~U[2026-04-29 19:23:38Z]
 }}
```

Agora que sabemos que nosso Context funciona como esperado, podemos retornar ao trabalho na nossa LiveView!

## Usando nosso Context em nossa LiveView

Primeiramente, vamos adicionar uma nova rota ao nosso projeto:

```elixir
scope "/", LineupWeb do
  pipe_through :browser

  live "/", TicketLive.Index, :index
  live "/tickets/new", TicketLive.New, :new
end
```

Também precisamos escrever nossa nova LiveView `TicketLive.New`:

```elixir
defmodule LineupWeb.TicketLive.New do
  use LineupWeb, :live_view

  alias Lineup.Queue
  alias Lineup.Queue.Ticket

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
          <.button navigate={~p"/"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    ticket = %Ticket{}

    {:ok,
     socket
     |> assign(:page_title, "New Ticket")
     |> assign(:ticket, ticket)
     |> assign(:form, to_form(Queue.change_ticket(ticket)))}
  end

  @impl true
  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    changeset = Queue.change_ticket(socket.assigns.ticket, ticket_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    save_ticket(socket, ticket_params)
  end

  defp save_ticket(socket, ticket_params) do
    case Queue.create_ticket(ticket_params) do
      {:ok, _ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ticket created successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
```

Tem muito código aí! Para entender melhor o que acabamos de escrever, vamos desmontá-lo por partes.

### Nosso componente `<.header>`

```elixir
@impl true
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash}>
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage ticket records in your database.</:subtitle>
    </.header>
    ...    
  </Layouts.app>
  """
end
```

O `<.header>` é um componente do `CoreComponents` que pode ser usado para manter estilos de cabeçalho de página consistentes em toda a aplicação. Cansou de como eles parecem? Basta editar a definição do componente e ver todos os cabeçalhos serem atualizados. Um conselho geral de quem trabalhou muito com LiveView: ter componentes para encapsular estilos não só torna o código da função `render/1` da sua LiveView mais elegante e legível como também facilita as atualizações. Se você se encontrar repetindo código por toda a sua UI, pode ser hora de nascer um novo componente. Como você pode ver, o `<.header>` também tem um slot opcional chamado `<:subtitle>`. Sinta-se à vontade para olhar a definição desse componente em `lib/lineup_web/components/core_components.ex` se quiser saber mais.

%{
title: ~H"Você notou que usamos <code>@page_title</code> no nosso código HEEx?",
description: ~H"""
Mesmo que <code>@page_title</code> seja um assign especial pois tem significado para a tag de título do HTML, isso não significa que você não pode usá-lo como qualquer outro assign.
"""
} %% .callout

### Nosso `<.form>`

```elixir
~H"""
...
<.form for={@form} id="ticket-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:called_at]} type="datetime-local" label="Called at" />
  <footer>
    <.button phx-disable-with="Saving..." variant="primary">Save Ticket</.button>
    <.button navigate={~p"/"}>Cancel</.button>
  </footer>
</.form>
...
"""
```

Como aprendemos nas aulas do curso de Fundamentos, projetos Phoenix vêm com um componente `<.form>` built-in que deve ser usado para lidar com formulários em toda a sua base de código. Agora, desde o início, estamos usando os componentes `<.input>` e `<.button>` do `CoreComponents`, pois antes apenas os escrevemos para fins de aprendizado. Assim como o componente `<.header>`, se em algum momento você quiser mudar a aparência da sua aplicação, sempre pode editar esses estilos no `CoreComponents`.

Um novo atributo sobre o qual ainda não falamos é o `phx-disable-with`. Este atributo é um [Phoenix binding](https://hexdocs.pm/phoenix_live_view/bindings.html) que funciona exclusivamente para botões de envio de formulário, exibindo uma mensagem de carregamento enquanto o cliente aguarda a resposta do servidor. É recomendável usá-lo não só para criar uma melhor UX de carregamento com pouco código, mas também para evitar que alguém pressione o botão de envio várias vezes furiosamente, o que poderia levar a criações duplicadas.

### Nosso callback `mount/3`

```elixir
@impl true
def mount(_params, _session, socket) do
  ticket = %Ticket{}
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  {:ok,
   socket
   |> assign(:page_title, "New Ticket")
   |> assign(:ticket, ticket)
   |> assign(:form, form)}
end
```

Similar ao que aprendemos no curso de Fundamentos, usamos um changeset para rastrear a validação e então o convertemos para um `Phoenix.Form` usando a função `to_form/2`. Vamos ver na próxima seção por que também atribuímos o ticket vazio ao nosso socket.

### Nosso evento de validação

```elixir
...
@impl true
def handle_event("validate", %{"ticket" => ticket_params}, socket) do
  changeset = Queue.change_ticket(socket.assigns.ticket, ticket_params)
  {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
end
...
```

Para aplicar validações precisamos criar um evento "validate" (já que escrevemos em HEEx que `phx-change="validate"`) e receber os `ticket_params`. Para essa validação tudo que precisamos é acessar o `%Ticket{}` original (que está vazio) em `socket.assigns.ticket` (por isso atribuímos ele ao socket antes), usar `Queue.change_ticket/2` novamente e então atribuir o novo valor do form junto com `action: :validate` para que nosso formulário saiba que deve exibir os erros de validação.

## Nosso evento de salvar

```elixir
...
def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, ticket_params)
end

defp save_ticket(socket, ticket_params) do
  case Queue.create_ticket(ticket_params) do
    {:ok, _ticket} ->
      {:noreply,
        socket
        |> put_flash(:info, "Ticket created successfully")
        |> push_navigate(to: ~p"/")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

De forma muito similar ao que acabamos de escrever no nosso evento `"validate"`, agora vamos lidar com os mesmos `ticket_params` mas usando diretamente `Queue.create_ticket/2` (lembre que ele também usa changesets por baixo dos panos, então qualquer erro de validação causará um `{:error, %Ecto.Changeset{}}`).

No nosso cenário de sucesso teremos `{:ok, ticket}` mas não precisamos do seu ID, então simplesmente ignoramos a variável usando underscore no nome e fazemos duas coisas:

1. Usamos [`put_flash/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#put_flash/3) para adicionar uma mensagem informativa sobre a criação do ticket, que irá para o assign `@flash` que mencionamos antes. Pense no `@flash` como uma forma de passar notificações da LiveView para o seu frontend (embora ele possa fazer muito mais do que isso).
2. Usamos [`push_navigate/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_navigate/2) para redirecionar nossos usuários para a página inicial. Vale mencionar que `push_navigate/2` usa os mecanismos internos do LiveView para fazer redirecionamentos otimizados quando possível (entre views no mesmo escopo) usando mensagens WebSocket em vez de um refresh completo do navegador como redirecionamentos comuns fazem.

Se ocorrer um erro de validação recebemos o changeset e o convertemos em um `form` usando `to_form/2`.

Se você sentiu dificuldade de acompanhar o código nesta aula você pode ver o código pronto usando `git checkout saving-data-done` ou clonando em outra pasta com `git clone https://github.com/adopt-liveview/lineup --branch saving-data-done`.

## Resumindo!

- O Ecto usa o design pattern Repository para interagir com bancos de dados.
- Sempre que precisarmos usar o banco de dados, vamos usar uma função do módulo `Repo`.
- O Ecto usa o design pattern schema migrations para modificar a estrutura do banco de dados.
- Para criar uma migration você precisa rodar `mix ecto.gen.migration nome_da_migration` no terminal.
- Para aplicar as migrations pendentes você deve executar `mix ecto.migrate` no terminal.
- Para desfazer as últimas migrations aplicadas você pode executar `mix ecto.rollback` no terminal.
- Um schema com `embedded_schema do` não interage com o banco de dados, mas `schema "nome_da_tabela" do` é tudo que você precisa para instruir o Ecto a interagir com aquela tabela.
- Em projetos Phoenix concentramos as funções relacionadas a um domínio específico em um módulo de contexto, seguindo a inspiração do [DDD](https://en.wikipedia.org/wiki/Domain-driven_design).
- No nosso projeto atual concentramos o domínio de gerenciamento de tickets no contexto `Lineup.Queue`.
- Você pode usar `iex -S mix` para entrar no modo Interactive Elixir e testar todas as funções do seu projeto.
- Quando seu contexto e schema estão bem modelados, adicionar funções à sua LiveView se torna trivial.