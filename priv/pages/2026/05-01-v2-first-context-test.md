%{
title: "Primeiro teste de contexto",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Vamos usar mix test pela primeira vez",
previous_page_id: "v2-saving-data",
next_page_id: "v2-listing-data"
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch saving-data-done`</code>.
"""
} %% .callout

Posso estar sendo tendencioso ao dizer isso, dado o quanto gosto de Elixir e Phoenix, mas posso afirmar que este é o stack com o qual me sinto mais confortável para escrever testes de código frontend que já experenciei. E há uma boa razão para isso: o código HEEx é tão funcional quanto um frontend pode ser! Você passa argumentos via assigns e recebe um HTML gerado.

Claro que agora você deve estar me xingando por afirmar isso, já que existem efeitos colaterais óbvios no código HEEx, como navegação, eventos de atualização/envio de formulários e até chamadas JS com JS commands. Mas me dê algumas aulas para mostrar que tudo isso fará sentido no final.

## Nossas ferramentas

O Elixir já vem com um runner de testes e biblioteca de assertions chamado [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) — você não precisa instalar nada. Na verdade, o Phoenix já gerou alguns testes para nós. E como nunca prestamos atenção nisso, na verdade nós os quebramos algumas aulas atrás!

Dentro do seu projeto LiveView execute `mix test`:

```
....

  1) test GET / (LineupWeb.PageControllerTest)
     test/lineup_web/controllers/page_controller_test.exs:4
     Assertion with =~ failed
     code:  assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
     left:  "<!DOCTYPE html>A BUNCH OF HTML CODE!</html>"
     right: "Peace of mind from prototype to production"
     stacktrace:
       test/lineup_web/controllers/page_controller_test.exs:6: (test)


Finished in 0.04 seconds (0.01s async, 0.03s sync)
5 tests, 1 failure
```

Não se preocupe se você receber alguns avisos — vamos focar no erro. Em vermelho vibrante você deve ver que nosso teste renderizou um monte de código HTML mas esperava encontrar pelo menos "Peace of mind from prototype to production" escrito dentro dele. Para entender o que um teste falhando significa:

```
  1) test [Aqui está o nome do caso de teste] ([Aqui está o nome do módulo de teste])
     [aqui está o caminho relativo para o arquivo de teste]:[aqui está o número da linha onde este caso de teste está escrito]
     Assertion with =~ failed    <- [alguma informação sobre por que falhou, diz que um operador `=~` não passou]
     code:  [código de teste que falhou]
     left:  [o que está escrito no lado esquerdo do operador =~]
     right: [o que está escrito no lado direito do operador =~]
     stacktrace:
       [caminho relativo]:[número da linha]: (test)     <- [onde exatamente seu teste falhou dentro deste caso de teste]
```

Saber ler essas mensagens vai facilitar muito sua vida. O erro acima é um simples caso de "correspondência baseada em texto". Quando usado assim `body =~ parte` esperamos que `parte` esteja contida dentro de `body`. Neste caso, `html_response(conn, 200) =~ "Peace of mind from prototype to production"` esperávamos que o HTML resultante contivesse essa frase. Vamos até `test/lineup_web/controllers/page_controller_test.exs:6` e focar apenas no caso de teste:

```elixir
test "GET /", %{conn: conn} do
  conn = get(conn, ~p"/")
  assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
end
```

Como você pode ver, há muitas novidades aqui para entender. Por ora, vamos focar em corrigir este teste. Ao iniciarmos nosso projeto, podemos notar que a página raiz (/) tem um cabeçalho "Listing Tickets". Vamos atualizar nosso teste e executar `mix test` novamente.

```diff
test "GET /", %{conn: conn} do
  conn = get(conn, ~p"/")
- assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
+ assert html_response(conn, 200) =~ "Listing Tickets"
end
```

```sh
$ mix test
Running ExUnit with seed: 610698, max_cases: 28

.....
Finished in 0.08 seconds (0.03s async, 0.05s sync)
5 tests, 0 failures
```

E pronto, nossa suite de testes está passando!

## O teste do nosso módulo de contexto

Como já temos código novo para nosso sistema de gerenciamento de tickets, podemos começar a criar nossos casos de teste. Vamos criar o arquivo de teste do nosso módulo de contexto. Crie: `test/lineup/queue_test.exs` (talvez você precise criar a pasta `lineup` dentro de `test`).

```elixir
defmodule Lineup.QueueTest do
  use Lineup.DataCase

  alias Lineup.Queue

  describe "tickets" do
    alias Lineup.Queue.Ticket

    import Lineup.QueueFixtures

    test "create_ticket/1 with valid data creates a ticket" do
      valid_attrs = %{called_at: ~U[2026-04-27 16:00:00Z]}

      assert {:ok, %Ticket{} = ticket} = Queue.create_ticket(valid_attrs)
      assert ticket.called_at == ~U[2026-04-27 16:00:00Z]
    end

    test "change_ticket/1 returns a ticket changeset" do
      ticket = ticket_fixture()
      assert %Ecto.Changeset{} = Queue.change_ticket(ticket)
    end
  end
end
```

Para isso funcionar também vamos precisar de um helper — crie `test/support/fixtures/queue_fixtures.ex` (talvez você precise criar a pasta `fixtures`):

```elixir
defmodule Lineup.QueueFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lineup.Queue` context.
  """

  @doc """
  Generate a ticket.
  """
  def ticket_fixture(attrs \\ %{}) do
    {:ok, ticket} =
      attrs
      |> Enum.into(%{
        called_at: ~U[2026-04-27 16:00:00Z]
      })
      |> Lineup.Queue.create_ticket()

    ticket
  end
end
```

Agora o `mix test` pode ser usado para rodar aquele arquivo de teste específico; você precisa passar seu caminho relativo. Experimente:

```sh
$ mix test test/lineup/queue_test.exs
Running ExUnit with seed: 469161, max_cases: 28

..
Finished in 0.04 seconds (0.00s async, 0.04s sync)
2 tests, 0 failures
```

Vamos falar sobre o que acabamos de escrever! Primeiramente, em Elixir tentamos ter uma certa paridade entre onde o código vive e onde o respectivo arquivo de teste vive. No nosso caso, `lib/lineup/queue.ex` tem um arquivo de teste em `test/lineup/queue_test.exs`. Como você pode ver, adicionamos `_test` aos nomes de arquivos e módulos — então `Lineup.Queue` é testado por `Lineup.QueueTest`. Outra diferença é que para arquivos de teste usamos a extensão `.exs`, comum a scripts Elixir, enquanto `.ex` é usado para partes de projetos.

Assim como em LiveViews fazemos `use MyappWeb, :live_view`, também temos helpers para escrever testes. No nosso caso, como estamos trabalhando com dados regulares, fazemos `use Lineup.DataCase`. Esse módulo já está escrito dentro do seu projeto e, assim como o `LineupWeb`, vai importar e criar aliases para coisas úteis no seu caso de teste. Você pode abrir `test/support/data_case.ex` por curiosidade, mas a menos que você precise instalar algo lá, provavelmente não precisará se preocupar com ele.

Você também deve ter notado que temos `describe "tickets" do ... end` dentro do nosso arquivo de teste. O [describe/2](https://hexdocs.pm/ex_unit/ExUnit.Case.html#describe/2) do ExUnit serve para agrupar testes tanto no código quanto na formatação dos resultados. Mais adiante veremos como podemos usar isso para configurar código compartilhado entre múltiplos casos de teste individuais. Também vale mencionar que, como estamos testando o módulo de contexto do Lineup e módulos de contexto podem ter mais de um modelo Ecto, é útil separar cada parte da sua lógica de negócio.

No nosso primeiro caso de teste `"create_ticket/1 with valid data creates a ticket"` apenas verificamos em nossos testes unitários o que já construímos antes: passar alguns atributos para `Queue.create_ticket/2` vai gerar um novo ticket. Já no segundo caso de teste `"change_ticket/1 returns a ticket changeset"` garantimos que passar um ticket válido irá gerar um `%Ecto.Changeset{}`.

No topo do nosso caso de teste `change_ticket` usamos `ticket_fixture/1` para criar rapidamente um ticket simples que podemos usar no nosso código de teste. Importamos isso algumas linhas antes em `import Lineup.QueueFixtures` — e é basicamente isso que as fixtures servem para fazer.

Com ambos os testes definidos podemos garantir que saberemos de antemão se alguma vez quebrarmos esses contratos e verificar se nossos comportamentos esperados regrediram ou simplesmente mudaram de alguma forma.

## Resumindo

Nesta aula, demos nossos primeiros passos nos testes com Elixir e Phoenix:

1. Descobrimos que o Elixir vem com o ExUnit, um runner de testes e biblioteca de assertions nativo
2. Executamos nossa primeira suite de testes com `mix test` e encontramos um teste falhando
3. Você pode rodar um arquivo de teste específico passando seu caminho relativo, como `mix test test/inner/something_test.exs`
4. Aprendemos como ler e interpretar mensagens de falha de testes no ExUnit
5. O runner de testes nativo do Elixir se chama ExUnit
6. Em Elixir temos a convenção de colocar arquivos de teste dentro da pasta `test` com o mesmo caminho que teria na pasta `lib` (`lib/inner/something.ex` tem um teste em `test/inner/something_test.exs`), com módulos de teste tendo a nomenclatura `SomethingTest` e extensão `.exs`
7. Usamos blocos `describe` para organizar grupos de testes
8. Usamos fixtures para criar rapidamente dados de teste, como armazenar coisas no banco de dados
9. O Phoenix já vem com `Myapp.DataCase` para auxiliar com testes relacionados a dados (geralmente módulos de contexto).