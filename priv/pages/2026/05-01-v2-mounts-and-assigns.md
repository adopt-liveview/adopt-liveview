%{
title: "LiveView Assigns",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Como funcionam as variáveis em LiveView?",
previous_page_id: "v2-anatomy-of-a-liveview",
next_page_id: "v2-your-first-mistakes"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto nesta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch first-liveview-done`</code>.
"""
} %% .callout

## Armazenando estado

Uma funcionalidade importantíssima de um framework frontend é ser capaz de armazenar o estado da aplicação atual. ReactJS usa hooks, VueJS usa composition/options API e assim vai. Em LiveView chamamos o estado de uma view de `assigns` (no plural mesmo).

`assigns` são apenas um mapa do Elixir. Você pode armazenar no mapa de `assigns` tudo que você poderia armazenar em uma variável qualquer: listas, mapas, structs etc.

Um excelente lugar para definir os `assigns` quando sua LiveView é gerada é num `callback` chamado `mount/3`.

Vamos editar nosso `page_live.ex` apenas um pouco:

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
    """
  end
end
```

Inicie o servidor com `mix phx.server` caso ainda não tenha feito.

Se você está se sentindo desesperado nesse momento, não fique. Realmente 7 coisas novas foram adicionadas em apenas 5 linhas de código novas se compararmos ao código anterior, mas vamos destrinchar essas modificações uma de cada vez!

## O callback `mount/3`

A forma com que o framework LiveView envia informações para programadores poderem tratar os dados é através de callbacks. Estes nada mais são que funções que rodam quando algo acontece. O callback `mount/3` executa quando sua LiveView é inicializada. Seus três argumentos são, respectivamente:

- Parâmetros vindo da URL. Útil para rotas como `/users/:id` onde o `:id` viria nos parâmetros.
- Dados da sessão de navegação atual (se estiver configurado). Útil para autenticação.
- Dados da conexão atual com o usuário acessando esta LiveView numa estrutura de dados chamada [Phoenix.LiveView.Socket](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Socket.html), mais conhecida apenas como `socket`.

Os dois primeiros argumentos serão explorados em mais detalhes em guias futuros. Por enquanto vamos apenas ignorá-los por questão de simplicidade.

## A estrutura de dados %Socket{}

Vamos direto ao ponto: a gerência de estado em LiveView gira essencialmente em torno de modificar o estado do seu socket. A função [`assign/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#assign/2) recebe o seu `socket` e quais assigns você deseja adicionar e os aplica gerando um novo socket. Vamos experimentar! Atualize seu código do seguinte modo:

```elixir
def mount(_params, _session, socket) do
  socket.assigns |> dbg
  socket = assign(socket, name: "Lubien")
  socket.assigns |> dbg
  {:ok, socket}
end
```

%{
title: ~H"<code>`dbg/2`</code>",
description: ~H"""
O macro <.link navigate="https://hexdocs.pm/elixir/debugging.html#dbg-2" target="\_blank"><code>`dbg/2`</code></.link> é extremamente útil para fazer debug de código e iremos utilizá-lo bastante durante as aulas. No geral, a utilização será adicionando um `pipe` para ele como <code>`|> dbg`</code>. Ele informa o arquivo, linha, função e variáveis da coisa que você está debugando. Super poderoso.
"""
} %% .callout

Se você verificar seu terminal, verá informações como estas:

```elixir
[(myapp 0.1.0) lib/myapp_web/live/page_live.ex:5: MyappWeb.PageLive.mount/3]

socket.assigns #=> %{flash: %{}, __changed__: %{}, live_action: :home}


[(myapp 0.1.0) lib/myapp_web/live/page_live.ex:7: MyappWeb.PageLive.mount/3]

socket.assigns #=> %{name: "Lubien", flash: %{}, __changed__: %{name: true}, live_action: :home}
```

Como podemos ver, os assigns são apenas um mapa com alguns dados sobre sua LiveView. Explicando cada um:

- `__changed__`: é um mapa que a LiveView automaticamente popula quando algo muda para poder explicar para sua engine de renderização de HTML quais propriedades precisam ser atualizadas para gerar o HTML final de forma eficiente.
- `flash`: é um mapa usado para enviar mensagens de informação, sucesso e alertas para seus usuários. Usaremos ele no futuro.
- `live_action`: quando entrarmos no assunto de Router veremos que podemos usar esse dado para identificar onde estamos na aplicação.

Além disso, podemos notar que no segundo `dbg` já temos um dado novo — o assign `name` foi adicionado.

## Renderizando `assigns`

Vamos olhar mais uma vez nossa render function:

```elixir
def render(assigns) do
  ~H"""
  Hello {@name}
  """
end
```

A forma com que você renderiza assigns em uma LiveView é usando `{alguma_coisa}`. A documentação chama isso de tags, enquanto eu particularmente prefiro chamar de interpolação. Além disso, para ter acesso ao assign chamado `name` basta usar o atalho `@name`. Outra forma de renderizar assigns em uma LiveView é usando `<%= %>`, mas você deve preferir o atalho `{}` sempre que possível. Veremos casos onde a sintaxe `<%= %>` é necessária no futuro. Projetos antigos de LiveView usavam `<%= %>` antes de `{}` ser introduzido, mas atualizar o LiveView deve converter a maioria deles para a nova sintaxe usando o formatter.

Por trás dos panos, dentro de uma render function, usar `@name` é exatamente igual a `assigns.name`. Lembra que eu disse que o único argumento de uma render function era obrigatoriamente chamado `assigns`? Veja o que acontece se eu renomeá-lo para qualquer outro nome como `def render(variables) do`:

```sh
== Compilation error in file lib/myapp_web/live/page_live.ex ==
** (RuntimeError) ~H requires a variable named "assigns" to exist and be set to a map
    (phoenix_live_view 1.1.16) expanding macro: Phoenix.Component.sigil_H/2
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: MyappWeb.PageLive.render/1
```

Porém se eu mudar minha render function de volta para:

```elixir
def render(assigns) do
  ~H"""
  Hello {@name}
  """
end
```

Tudo funciona normalmente.

## Resumindo!

- O callback `mount/3` executa quando sua LiveView está sendo inicializada.
- A estrutura de dados `socket` contém o estado da sua LiveView para este usuário no momento.
- Conseguimos adicionar `assigns` usando a função `assign/2` passando o `socket` e os novos valores.
- A função `render/1` tem um atalho para escrever assigns usando `@name` em vez de `assigns.name`.