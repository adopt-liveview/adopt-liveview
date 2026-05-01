%{
title: "Formulário DRY",
author: "Lubien",
tags: ~w(getting-started),
section: "Form Component",
description: "Como evitar duplicação de código em formulários",
previous_page_id: "v2-editing-data",
next_page_id: "v2-live-component",
}

---

%{
title: "Esta aula é uma continuação direta da aula anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta aula talvez seja confuso pois ela é uma continuação direta do código da aula anterior. Caso você queira pular a aula anterior e começar direto nesta você pode clonar a versão inicial para esta aula usando o comando <code>`git clone https://github.com/adopt-liveview/lineup.git --branch editing-data-done`</code>.
"""
} %% .callout

Uma boa prática em programação é evitar repetir código sempre que possível. O princípio DRY (Don't Repeat Yourself, não se repita) é um mantra que você pode carregar consigo no seu dia a dia como desenvolvedor. No final da seção anterior, notamos uma quantidade considerável de repetição de código no formulário. Nesta seção, vamos analisar como evitar isso uma aula de cada vez.

## Usando `diff`

O comando shell `diff` pode ser uma ótima forma de comparar coisas quando elas são parecidas o suficiente. Vamos experimentar:

```sh
$ diff lib/lineup_web/live/ticket_live/new.ex lib/lineup_web/live/ticket_live/edit.ex
1c1
< defmodule LineupWeb.TicketLive.New do
---
> defmodule LineupWeb.TicketLive.Edit do
5d4
<   alias Lineup.Queue.Ticket
20c19
<           <.button navigate={~p"/"}>Cancel</.button>
---
>           <.button navigate={~p"/tickets/#{@ticket}"}>Cancel</.button>
28,29c27,28
<   def mount(_params, _session, socket) do
<     ticket = %Ticket{}
---
>   def mount(%{"id" => id}, _session, socket) do
>     ticket = Queue.get_ticket!(id)
35c34
<      |> assign(:page_title, "New Ticket")
---
>      |> assign(:page_title, "Edit Ticket")
51,52c50,51
<     case Queue.create_ticket(ticket_params) do
<       {:ok, _ticket} ->
---
>     case Queue.update_ticket(socket.assigns.ticket, ticket_params) do
>       {:ok, ticket} ->
55,56c54,55
<          |> put_flash(:info, "Ticket created successfully")
<          |> push_navigate(to: ~p"/")}
---
>          |> put_flash(:info, "Ticket updated successfully")
>          |> push_navigate(to: ~p"/tickets/#{ticket}")}
```

## Analisando as partes

Vamos focar em dois arquivos: `TicketLive.New` (em `lib/lineup_web/live/ticket_live/new.ex`) e `TicketLive.Edit` (em `lib/lineup_web/live/ticket_live/edit.ex`). Ambos têm:

1. Uma função `mount/3` que inicializa o formulário, mas apenas o módulo `Edit` precisa do ID.
2. Exatamente o mesmo `handle_event("validate" ...)`.
3. Exatamente o mesmo `handle_event("save", ...)`.
4. Pequenas diferenças em como `save_ticket/2` lida com o salvamento dos dados, a mensagem flash e o redirecionamento.
5. Um `<.form>` com os mesmos dados, mas com rota diferente para o botão "Cancel".

Quando precisarmos adicionar um novo campo, teríamos que adicioná-lo em ambos os arquivos. Quando precisarmos adicionar alguma validação específica (por exemplo, validar se o nome do ticket é duplicado), teríamos que fazer isso em ambos os formulários. Você consegue ver onde quero chegar?

## Reutilizando a mesma LiveView mais de uma vez

Não é contra as regras reutilizar uma LiveView em rotas diferentes. Na verdade, vamos fazer isso agora. Renomeie `LineupWeb.TicketLive.New` para `LineupWeb.TicketLive.Form` e não se esqueça de renomear o arquivo para `form.ex` também!

No seu router, edite `/tickets/:new` e `/tickets/:id/edit` para usar essa mesma LiveView:

```elixir
scope "/", LineupWeb do
  pipe_through :browser

  live "/", TicketLive.Index, :index
  live "/tickets/new", TicketLive.Form, :new
  live "/tickets/:id", TicketLive.Show, :show
  live "/tickets/:id/edit", TicketLive.Form, :edit
end
```

Para verificar o estrago que você fez, execute `mix test`:

```rs
$ mix test
Compiling 3 files (.ex)
Generated lineup app
Running ExUnit with seed: 603750, max_cases: 28

..........

  1) test Index updates ticket in listing (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:46
     Assertion with =~ failed
     code:  assert render(edit_form_live) =~ "Edit Ticket"
     left:  "A LOT OF HTML" <> ...
     right: "Edit Ticket"
     stacktrace:
       test/lineup_web/live/ticket_live_test.exs:55: (test)

.

  2) test Show updates ticket and returns to show (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:77
     ** (ArgumentError) expected LiveView to redirect to "/tickets/1/edit", but got "/tickets/1/edit"
     code: |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")
     stacktrace:
       (phoenix_live_view 1.1.28) lib/phoenix_live_view/test/live_view_test.ex:1796: Phoenix.LiveViewTest.__follow_redirect__/4
       test/lineup_web/live/ticket_live_test.exs:84: (test)

..
Finished in 0.1 seconds (0.05s async, 0.1s sync)
15 tests, 2 failures
```

Testes unitários são uma bênção porque nos ajudam a garantir que nosso código funciona como esperado. Agora que temos testes falhando, vamos corrigi-los.

### Título personalizado por rota

Vamos olhar para o nosso primeiro teste falhando:

```sh
  1) test Index updates ticket in listing (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:46
     Assertion with =~ failed
     code:  assert render(edit_form_live) =~ "Edit Ticket"
     left:  "A LOT OF HTML" <> ...
     right: "Edit Ticket"
     stacktrace:
       test/lineup_web/live/ticket_live_test.exs:55: (test)
```

Como a assertion falhando é `assert render(edit_form_live) =~ "Edit Ticket"`, isso significa que simplesmente precisamos atualizar o título HTML de acordo com a rota atual. Isso pode ser feito facilmente introduzindo uma variável que você não conhecia até agora: `socket.assigns.live_action`. Como nosso router definiu:

```elixir
live "/tickets/new", TicketLive.Form, :new
live "/tickets/:id/edit", TicketLive.Form, :edit
```

Tanto `:new` quanto `:edit` são valores possíveis para `socket.assigns.live_action` e nada mais. Podemos aproveitar isso na nossa `TicketLive.Form` assim:

```elixir
@impl true
def mount(_params, _session, socket) do
  ticket = %Ticket{}
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  {:ok,
   socket
   |> assign(:ticket, ticket)
   |> assign(:form, form)
   |> apply_action(socket.assigns.live_action)}
end

defp apply_action(socket, :edit) do
  socket
  |> assign(:page_title, "Edit Ticket")
end

defp apply_action(socket, :new) do
  socket
  |> assign(:page_title, "New Ticket")
end
```

Criamos uma função auxiliar chamada `apply_action/2` para verificar qual é o `socket.assigns.live_action` e atribuir o `@page_title` de acordo. Se você acessar `/tickets/:id/edit` pode confirmar que "Edit Ticket" está funcionando novamente! Quanto aos nossos testes unitários:

```sh
$ mix test
Running ExUnit with seed: 192910, max_cases: 28

.............

  1) test Show updates ticket and returns to show (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:77
     ** (ArgumentError) expected LiveView to redirect to "/tickets/1", but got "/"
     code: |> follow_redirect(conn, ~p"/tickets/#{ticket}")
     stacktrace:
       (phoenix_live_view 1.1.28) lib/phoenix_live_view/test/live_view_test.ex:1796: Phoenix.LiveViewTest.__follow_redirect__/4
       test/lineup_web/live/ticket_live_test.exs:92: (test)



  2) test Index updates ticket in listing (LineupWeb.TicketLiveTest)
     test/lineup_web/live/ticket_live_test.exs:46
     ** (ArgumentError) expected LiveView to redirect to "/tickets/1", but got "/"
     code: |> follow_redirect(conn, ~p"/tickets/#{ticket}")
     stacktrace:
       (phoenix_live_view 1.1.28) lib/phoenix_live_view/test/live_view_test.ex:1796: Phoenix.LiveViewTest.__follow_redirect__/4
       test/lineup_web/live/ticket_live_test.exs:61: (test)


Finished in 0.1 seconds (0.06s async, 0.1s sync)
15 tests, 2 failures
```

Não desanime! Corrigimos um problema, agora é hora de corrigir o próximo.

### Tratando edições

Agora nosso código não está atualizando nenhum ticket, mas também está criando novos sempre que você pressiona "Save" e te redireciona para a página raiz. Isso está errado. Para resolver isso, precisamos primeiro entender a diferença entre criar um novo ticket e atualizar um existente.

Algoritmo de criação:
1. Armazenar `%Ticket{}` vazio em `socket.assigns.ticket`.
2. Usuário pressiona "Save" para enviar os `ticket_params` atualizados.
3. Executar `Queue.create_ticket(ticket_params)`.

Algoritmo de atualização:
1. Buscar `%Ticket{}` pelo `id` da URL nos `params` e armazenar em `socket.assigns.ticket`.
2. Usuário pressiona "Save" para enviar os `ticket_params` atualizados.
3. Executar `Queue.update_ticket(socket.assigns.ticket, ticket_params)`.

Com esse conhecimento podemos concluir que precisamos mudar como obtemos o `%Ticket{}` e como o salvamos. Podemos aproveitar `socket.assigns.live_action` mais uma vez a nosso favor. Edite a `TicketLive.Form` novamente assim:

```elixir
@impl true
def mount(params, _session, socket) do
  {:ok,
   socket
   |> apply_action(socket.assigns.live_action, params)}
end

defp apply_action(socket, :edit, %{"id" => id}) do
  ticket = Queue.get_ticket!(id)
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  socket
  |> assign(:page_title, "Edit Ticket")
  |> assign(:ticket, ticket)
  |> assign(:form, to_form(form))
end

defp apply_action(socket, :new, _params) do
  ticket = %Ticket{}
  changeset = Queue.change_ticket(ticket)
  form = to_form(changeset)

  socket
  |> assign(:page_title, "New Ticket")
  |> assign(:ticket, ticket)
  |> assign(:form, to_form(form))
end

# handle_event("validate", ...) não muda nada!

def handle_event("save", %{"ticket" => ticket_params}, socket) do
  save_ticket(socket, socket.assigns.live_action, ticket_params)
end

defp save_ticket(socket, :edit, ticket_params) do
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

defp save_ticket(socket, :new, ticket_params) do
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

Movemos mais código do `mount/3` para o `apply_action/3` e agora esse método também recebe `params` para poder usar o `id` em `:edit` e ignorá-los em `:new`. Para o `handle_event("save" ...)` fizemos o mesmo, passando `socket.assigns.live_action` para criar uma cláusula por action. O conteúdo de cada `save_ticket/3` agora se comporta exatamente como a `TicketLive.New` e a `TicketLive.Edit` se comportavam separadamente, mas desta vez compartilhamos tudo que antes estava duplicado. Não se esqueça de deletar `LineupWeb.TicketLive.Edit` se ainda não o fez. Agora o `mix test` deve estar passando em todos os testes.

### Sucesso!

Com esta pequena modificação, conseguimos centralizar o formulário em um único lugar. Futuras adições ao formulário afetarão ambas as páginas sem precisarmos duplicar código.

Se você sentiu dificuldade de acompanhar o código nesta aula, pode ver o código pronto usando `git checkout form-component-done` ou clonando em outra pasta com `git clone https://github.com/adopt-liveview/lineup.git --branch form-component-done`.

## Resumindo!

- Manter o código DRY facilita a manutenção dele no futuro.
- Quando você sentir necessidade de refatorar código para deixá-lo mais enxuto, analise os pontos de repetição.
- Os testes serão uma grande ajuda quando você precisar refatorar sem quebrar sua aplicação. Você notou que não mudamos uma única linha de código nos nossos testes durante esta aula?