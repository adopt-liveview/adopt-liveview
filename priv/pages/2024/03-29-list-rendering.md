%{
title: "Renderização de listas",
author: "Lubien",
tags: ~w(getting-started),
section: "Estruturas de Controle",
description: "Vamos por um pouco de escala no HTML"
}

---

Templates HEEx definem múltiplas maneiras de você renderizar múltiplos elementos vindos de uma lista. Vamos estudar cada possibilidade e quando usar cada uma.

## Renderizando listas com a compreensão `for`

Quem já tem experiência com elixir já conhece a compreensão `for`. Ela é totalmente viável dentro do HEEx. Crie e execute um arquivo chamado `classic_for.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Podemos renderizar qualquer lista em um assign usando o formato `<%= for item <- @items %>`. Vale mencionar que é necessário o `=` na tag para que o resultado seja renderizado.

%{
title: ~H"Por que a variável <code>`food`</code> não usa <code>`@`</code>?",
description: ~H"""
Lembre-se que o <code>`@`</code> representa <code>`assigns.`</code>, a variável <code>`@foods`</code> vem justamente dos assigns porém a variável <code>`food`</code> é localmente criada pelo `for` loop portanto não funcionaria usando <code>`@`</code>.
"""
} %% .callout

Apesar da sua simplicidade este método de renderizar listas tem duas desvantagens:

1. Toda vez que qualquer assign mudar, o loop será executado novamente. Não importa se o assign que mudou não tenha relacionamento com o loop.
2. A lista de elementos vai ficar salva em memória na LiveView enquanto a LiveView estiver ligada para esse usuário.

## Evite processar listas dentro do HEEx

Digamos que você não gostaria de renderizar um elemento em específico da lista. Poderíamos simplesmente adicionar a nossa compreensão um filtro. Crie e execute um arquivo chamado `classic_for_filter.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods, food != "banana" do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Apenas adicionando `, food != "banana"` conseguimos remover um elemento indesejado! Porém isso introduz mais um problema a forma de renderizar listas: toda vez que um assign mudar vamos filtrar e renderizar a lista novamente.

A recomendação oficial do time do Phoenix é que você evite ao máximo fazer qualquer tipo de cálculo dentro de sua `render/1`, processe o seu assign de antemão. Crie e execute um arquivo chamado `class_for_filter_beforehand.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    foods = Enum.filter(["apple", "banana", "carrot"], fn food -> food != "banana" end)
    socket = assign(socket, foods: foods)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Desta vez nossa `render/1` se beneficia de não ter que processar o filtro e também do fato que existem menos elementos para serem renderizados!

## Simplificando renderização de listas com o atributo especial `:for`

Assim como o bloco `if` possui a versão `:if`, a compreensão `for` tem uma versão em atributo especial HEEx `:for`. Crie e execute um arquivo chamado `special_for.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <li :for={food <- @foods}><%= food %></li>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Nosso código ganhou um pouco mais de legibilidade e simplicidade. Porém este formato possui as mesmas desvantagens do método anterior. Como podemos ter uma renderização de listas que não consome memória para sempre e que não re-renderiza quando outros assigns mudam?

## Renderização eficiente com streams

O time do Phoenix adicionou ao LiveView uma maneira eficiente de gerenciar listas grandes ou potencialmente infinitas chamada Streams. Crie e execute um arquivo chamado `streams.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      stream(socket, :foods, [
        %{id: 1, name: "apple"},
        %{id: 2, name: "banana"},
        %{id: 3, name: "carrot"}
      ])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul id="food-stream" phx-update="stream">
      <li :for={{dom_id, food} <- @streams.foods} id={dom_id}>
        <%= food.name %>
      </li>
    </ul>
    """
  end
end

LiveviewPlayground.start()
```

Imediatamente notamos um pouquinho mais de complexidade no nosso código. Vamos entender ele no passo-a-passo.

Para definir uma stream nós usamos a função [`stream/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4). Ela recebe nosso socket, o nome da stream como átomo e o valor inicial. Come você pode ver tivemos que transformar de uma lista simples de strings para uma lista de mapas. O motivo é que, para poder entender quais elementos já foram renderizados na página, as streams precisam de um `id` no item da stream. Apesar de ser um pouco chato para códigos simples, se estivéssemos trabalhando com um banco de dados provavelmente o `id` já estaria incluso.

A próxima modificação acontece no nosso código HEEx. O elemento pai da lista a ser renderizada obrigatoriamente precisa de um atributo `id` único para que o LiveView saiba quem contém os elementos renderizados e devemos adicionar um atributo especial `phx-update="stream"` para definir que os filhos deste elemento são parte de uma stream.

Dentro do nosso `ul` mativemos o `:for` especial porem dessa vez nós lemos o assigns especial `@streams.foods`. Toda vez que uma cria uma stream com `algum_nome` você gera um assign especial `@streams.algum_nome`. Não só isso, nosso `:for` agora lê duas variáveis: um `dom_id` e a `food` em si. O `dom_id` é necessário para que, se houver necessidade, nós possamos atualizar/remover/mover elementos da nossa stream de maneira eficiente.

Como você deve imaginar, streams são muito mais poderosas que o simples `:for`. No futuro iremos falar mais sobre streams em detalhes.

%{
title: "Devo sempre usar streams então?",
description: ~H"""
Não deixe o demônio da otimização precoce lhe vencer. Se você está começando algo, vá no simples e use <code>`for`</code> ou <code>`:for`</code>. Se for trabalhar com muitos itens considere streams. Entendo que armazenar as listas em memória pode parecer desperdício mas na realidade estamos falando de um dado que no geral pode ser desprezível de tão pequeno em memória RAM dependendo do tamanho da sua lista.
"""
} %% .callout

## Resumindo!

- Você pode usar o a compreensão em bloco `for` para renderizar listas facilmente.
- O HEEx também tem uma versão em atributo especial `:for` para deixar seu código mais simples e legível.
- Ambas as soluções `for` e `:for` ganham em simplicidade porém carregam memória extra no servidor e são executadas novamente sempre que um assign muda.
- Para renderização eficiente de muitos ou infinitos dados o LiveView possui streams como solução, perdendo apenas no fato de que precisa de um setup inicial um pouco maior.
