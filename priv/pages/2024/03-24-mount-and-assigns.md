%{
title: "Assigns de uma LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Como funcionam variáveis em LiveView?",
previous_page_id: "explain-playground",
next_page_id: "your-first-mistakes"
}

---

## Armazenando estado

Uma funcionalidade importantíssima de um framework frontend é ser capaz de armazenar o estado da aplicação atual. ReactJS usa hooks, VueJS usa composition/options API e assim vai. Em LiveView chamamos o estado de uma view os `assigns` (no plural mesmo).

`assigns` são apenas um mapa do Elixir. Você pode armazenar em `assigns` tudo que você poderia armazenar em uma variável qualquer: listas, mapas, structs etc.

Um excelente lugar para escrever os `assigns` quando sua LiveView é gerada é no `callback` chamado `mount/3`.

Vamos criar um arquivo chamado `assigns.exs`:

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
    Hello <%= @name %>
    """
  end
end

LiveviewPlayground.start()
```

Inicie o servidor como `elixir assigns.exs` e veja o resultado.

Se você está se sentindo desesperado nesse momento não fique. Realmente 7 coisas novas foram adicionadas em apenas 5 linhas de código novas se compararmos ao `hello_liveview.exs` mas vamos destrinchar essas modificações uma de cada vez!

## O callback `mount/3`

A forma com que o framework LiveView envia informações para programadores poderem tratar os dados é através de callbacks. Estes nada mais são que funções que rodam quando algo acontece. O callback `mount/3` executa quando sua LiveView é inicializada. Seus três argumentos são, respectivamente:

- Parâmetros vindo do URL. Útil para rotas como `/users/:id` onde o `:id` viria nos parâmetros.
- Dados da sessão de navegação atual (se estiver configurado). Útil para sistemas de autenticação.
- Dados da conexão atual com o usuário acessando esta LiveView numa estrutura de dados chamada [Phoenix.LiveView.Socket](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Socket.html), mais conhecido apenas como `socket`.

Os dois primeiros argumentos serão explorados em mais detalhes em guias futuros, no momento iremos apenas ignorar eles por questão de simplicidade.

## A estrutuda de dados %Socket{}

Vamos direto ao ponto: gerência de estado LiveView completamente gira em torno de modificar o estado do seu `socket`. A função [`assign/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#assign/2) recebe o seu `socket` e quais assigns você deseja adicionar e aplica eles gerando um novo socket. Vamos experimentar! Atualize seu código do seguinte modo:

```elixir
def mount(_params, _session, socket) do
  socket.assigns |> dbg
  socket = assign(socket, name: "Lubien")
  socket.assigns |> dbg
  {:ok, socket}
end
```

Não esqueça de desligar e ligar o servidor novamente para ver as modificações.

%{
title: ~H"<code>`dbg/2`</code>",
description: ~H"""
O macro <.link navigate="https://hexdocs.pm/elixir/debugging.html#dbg-2" target="\_blank"><code>`dbg/2`</code></.link> é extremamente útil para fazer debug de código e iremos estar utilizando ele bastante durante as aulas. No geral a utilização será adicionando um `pipe` para ele como <code>`|> dbg`</code>. Ele diz o arquivo, linha, função e variáveis da coisa que você está debugando. Super poderoso.
"""
} %% .callout

Se você você verificar seu terminal verá informações como estas:

```elixir
[priv/examples/mount-and-assigns/assigns.exs:9: PageLive.mount/3]
socket.assigns #=> %{__changed__: %{}, flash: %{}, live_action: :index}

[priv/examples/mount-and-assigns/assigns.exs:11: PageLive.mount/3]
socket.assigns #=> %{name: "Lubien", __changed__: %{name: true}, flash: %{}, live_action: :index}
```

Como podemos ver, os assigns são apenas um mapa com alguns dados sobre sua LiveView. Explicando cada um:

- `__changed__`: é um mapa que a LiveView automaticamente popula quando algo muda para poder explicar para sua engine de renderização de HTML quais propriedades precisando ser atualizadas para gerar o HTML final de uma forma eficiente.
- `flash`: é um mapa usado para enviar mensagens de informação, sucesso e alertas para seus usuários. Usaremos ele no futuro.
- `live_action`: quando entrarmos no assunto de Router veremos que podemos usar esse dado para identificar onde estamos na aplicação.

Além disso, podemos notar que no segundo `dbg` já temos um novo dado, o `name` adicionado.

## Renderizando `assigns`

Vamos olhar mais uma vez nossa render function:

```elixir
def render(assigns) do
  ~H"""
  Hello <%= @name %>
  """
end
```

A forma com que você renderiza assigns em uma LiveView é utilizando `<%= %>`. A documentação chama isso de tags enquanto eu particularmente prefiro chamar de interpolação. Além disso, para ter acesso ao assign chamado `name` basta usar o atalho `@name`.

Por trás dos panos se você estiver numa render function `@name` é exatamente igual a `assigns.name`. Lembra que eu disse que o único argumento de uma render function era obrigatoriamente chamado `assigns`? Veja o que acontece se eu renomer ele para qualquer outro nome como `def render(variaveis) do`:

```sh
$ elixir priv/examples/mount-and-assigns/assigns.exs
** (RuntimeError) ~H requires a variable named "assigns" to exist and be set to a map
    (phoenix_live_view 0.18.18) expanding macro: Phoenix.Component.sigil_H/2
    priv/examples/mount-and-assigns/assigns.exs:16: PageLive.render/1
```

Porém se eu mudar minha render function para:

```elixir
def render(assigns) do
  ~H"""
  Hello <%= assigns.name %>
  """
end
```

Tudo funciona normalmente.

## Recapitulando

- O callback `mount/3` executa quando sua LiveView está sendo inicializada.
- A estrutura de dados `socket` contém o estado da sua LiveView para este usuário no momento.
- Conseguimos adicionar `assigns` usando a função `assign/2` passando o `socket` e os novos valores.
- A função `render/1` tem um atalho para escrever assigns usando `@nome_do_assign`.
