%{
title: "Renderização de listas",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "Vamos por um pouco de escala no HTML",
previous_page_id: "v2-conditional-rendering",
next_page_id: "v2-phx-value"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nessa página, pode ficar confuso porque é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por aqui, você pode clonar a versão inicial desta aula com o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

Templates HEEx possuem várias formas de renderizar múltiplos elementos a partir de uma lista. Vamos estudar cada possibilidade e quando usar cada uma delas.

## Renderizando listas com a compreensão `for`

Quem já tem experiência com Elixir conhece as compreensões de lista `for`. Ela é totalmente viável dentro do HEEx também. Atualize seu `page_live.ex` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li>{food}</li>
      <% end %>
    </ul>
    """
  end
end
```

Podemos renderizar qualquer lista em um assign usando o formato `<%= for item <- @items %>`. Vale mencionar que o `=` na tag é necessário para que o resultado seja renderizado.

%{
title: ~H"Por que a variável <code>`food`</code> não começa com <code>`@`</code>?",
description: ~H"""
Lembre-se que o <code>`@`</code> representa <code>`assigns.`</code>; a variável <code>`@foods`</code> vem justamente dos assigns, mas a variável <code>`food`</code> é criada localmente pelo loop <code>`for`</code>, portanto não funcionaria usando <code>`@`</code>.
"""
} %% .callout

Apesar da sua simplicidade, este método de renderizar listas tem duas desvantagens:

1. O loop será executado novamente toda vez que qualquer assign mudar. Não importa se o assign que mudou não tem relação com o loop.
2. A lista de elementos ficará salva em memória na LiveView enquanto ela estiver ativa para aquele usuário, mesmo que você não precise dela.

## Evite processar listas dentro do HEEx

Digamos que você não queira renderizar um elemento específico da lista. Poderíamos simplesmente adicionar um filtro à nossa compreensão `for`. Vá em frente e atualize `page_live.ex` com o seguinte:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods, food != "banana" do %>
        <li>{food}</li>
      <% end %>
    </ul>
    """
  end
end
```

Apenas adicionando `, food != "banana"` conseguimos remover um elemento indesejado! No entanto, isso introduz outro problema na forma como renderizamos listas: toda vez que um assign mudar, filtraremos e renderizaremos a lista novamente.

A recomendação oficial do time do Phoenix é que você evite ao máximo fazer qualquer tipo de cálculo dentro do seu `render/1`. Processe seu código antes de atribuí-lo ao seu socket. Agora atualize `page_live.ex` para filtrar a lista com antecedência:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    foods = Enum.filter(["apple", "banana", "carrot"], fn food -> food != "banana" end)
    socket = assign(socket, foods: foods)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li>{food}</li>
      <% end %>
    </ul>
    """
  end
end
```

Desta vez nossa `render/1` se beneficia de não ter que processar o filtro repetidamente e também do fato de haver menos elementos para renderizar!

## Simplificando a renderização de listas com o atributo especial `:for`

Assim como o bloco `if` tem a versão `:if`, a compreensão `for` tem seu atributo especial HEEx `:for`. Atualize `page_live.ex` para experimentar:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <li :for={food <- @foods}>{food}</li>
    </ul>
    """
  end
end
```

Nosso código ganhou um pouco mais de legibilidade e simplicidade. No entanto, esse formato tem as mesmas desvantagens do método anterior. Como podemos ter renderização de lista que não consome memória para sempre e que não re-renderiza quando assigns mudam?

## Renderização eficiente com streams

O time do Phoenix adicionou ao LiveView uma forma eficiente de gerenciar listas grandes ou potencialmente infinitas chamada Streams. Atualize `page_live.ex` para usar streams:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
        {food.name}
      </li>
    </ul>
    """
  end
end
```

Imediatamente podemos notar um aumento de complexidade no código. Vamos entendê-lo passo a passo.

Para definir um stream usamos a função [`stream/4`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4). Ela recebe nosso socket, o nome do stream como um átomo e o valor inicial. Como você pode ver, tivemos que transformar de uma simples lista de strings para uma lista de mapas. O motivo é que streams precisam de um `id` no item do stream para que o LiveView entenda quais elementos já foram renderizados na página. Embora seja um pouco chato para coisas simples, se estivéssemos trabalhando com um banco de dados o `id` provavelmente já estaria incluído, então para a maioria dos casos de uso reais isso não é problema algum.

A próxima mudança aconteceu dentro do nosso código HEEx. O elemento pai da lista DEVE ter um atributo `id` único para que o LiveView saiba quem contém os elementos renderizados, e devemos adicionar um atributo especial `phx-update="stream"` para definir que os filhos desse elemento fazem parte de um stream.

Dentro do nosso `ul` mantivemos o `:for` especial, mas desta vez lemos o assign especial `@streams.foods`. Toda vez que um stream é criado com `:algum_nome` você gera um assign especial `@streams.algum_nome`. Não só isso, nosso `:for` agora itera elementos com duas variáveis dentro de uma tupla: um `dom_id` e o próprio `food`. O `dom_id` é necessário para que possamos atualizar/remover/mover elementos do nosso stream de forma eficiente se necessário.

Como você pode imaginar, streams são muito mais poderosos do que simples compreensões `:for`. No futuro falaremos mais sobre streams em detalhes.

%{
title: "Devo sempre usar streams?",
description: ~H"""
Não deixe que o demônio da otimização precoce te vença. Se você está começando algo, vá pelo simples e use <code>`for`</code> ou <code>`:for`</code>. Se você vai trabalhar com muitos itens, considere streams. Entendo que armazenar listas em memória pode parecer um desperdício, mas na realidade estamos falando de dados que em geral podem ser negligenciáveis porque são muito pequenos em termos de uso de RAM dependendo do tamanho da sua lista.
"""
} %% .callout

## Resumindo!

- Você pode usar a compreensão de bloco `for` para renderizar listas facilmente.
- HEEx também tem uma versão com atributo especial `:for` para deixar seu código mais simples e legível.
- Ambas as soluções `for` e `:for` ganham em simplicidade, mas requerem memória extra no servidor e são executadas novamente sempre que um assign mudar.
- O LiveView tem streams como solução para renderização eficiente de dados numerosos ou infinitos, com a única ressalva de que requer uma configuração inicial um pouco maior (a menos que você esteja usando um banco de dados 😉).