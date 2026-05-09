%{
title: "Seu Primeiro PubSub",
author: "Lubien",
tags: ~w(realtime),
section: "Tempo Real com LiveView",
description: "Acompanhe mudanças entre LiveViews para múltiplos usuários",
previous_page_id: "v2-form-component",
next_page_id: "v2-ticket-creation-in-real-time",
}

---

Projetos Phoenix já vêm com tudo que você precisa para criar software em tempo real. Hoje vamos falar sobre uma das principais funcionalidades do Phoenix: o PubSub.

## Definindo o problema

Estamos construindo um sistema de fila de tickets onde os usuários podem pegar seus tickets e nossa página principal deve acompanhar quem é o próximo na fila. Não queremos que os usuários fiquem atualizando a página toda vez que alguém chega. Não precisamos disso. Para começar a trabalhar com PubSub (assinaturas públicas) precisamos pensar apenas em duas coisas:

- Quais são os triggers para uma atualização em tempo real?
- Quem precisa saber sobre o que foi atualizado?

Se você conseguir responder essas duas perguntas, você pode definir um caso de uso para PubSubs. Vamos ao código.

## Nosso escopo

Vamos escrever isso como um caso de uso:

> Eu, como cliente usando este sistema de tickets, quero pegar um ticket e a equipe será notificada sobre minha presença na fila.

Agora que temos o caso de uso, vamos traduzi-lo em etapas que podemos programar.

- Quais são os triggers para uma atualização em tempo real?
  - O usuário cria um ticket.
- Quem precisa saber sobre o que foi atualizado?
  - A lista de tickets.

## Broadcasts

Quando você quer que outras LiveViews sejam notificados sobre algo, precisamos usar broadcasts do PubSub. Pense nisso como uma mensagem sendo enviada para todos que querem ouvi-la. Existem várias formas de fazer um broadcast, mas como estamos trabalhando com LiveView, vamos preferir usar [`MyappWeb.Endpoint.broadcast/3`](https://hexdocs.pm/phoenix/1.8.7/Phoenix.Endpoint.html#c:broadcast/3). Vamos brincar um pouco com isso.

No seu terminal, execute o seguinte para iniciar um shell Elixir interativo:

```elixir
$ iex -S mix
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> alias LineupWeb.Endpoint
LineupWeb.Endpoint

iex(2)> Endpoint.broadcast("queue:tickets", "ticket_added", %{id: 1})
:ok
```

Criamos um alias para o nosso `LineupWeb.Endpoint` para podermos chamar `Endpoint.algo` depois.

A função broadcast recebe 3 argumentos:

- Um tópico: pode ser qualquer string.
- Um evento: também qualquer string.
- Um payload: um mapa de dados para enviar com o evento.

Como estamos trabalhando com tickets, escolhemos o tópico `"queue:tickets"` pois ele se relaciona com nossos contexto e modelo, mas poderia ser qualquer coisa como "minhas-notificacoes-do-sistema-123". Para o nome do evento, queremos ser bem claros para garantir que nosso código seja mais fácil de entender no futuro. Para o último argumento, você pode passar qualquer coisa como um mapa. Por enquanto, escolhemos passar um mapa com o id do ticket para que a LiveView possa usá-lo para atualizar a UI.

E daí? Nada aconteceu. Enviar mensagens não é útil a menos que tenhamos alguém esperando por elas.

## Subscriptions

O motivo de um tópico existir no PubSub é que saberemos quem está interessado em receber mensagens sobre aquele tópico. Vamos voltar ao nosso `iex` e tentar mais uma vez.

```elixir
iex(3)> Endpoint.subscribe("queue:tickets")
:ok

iex(4)> Endpoint.broadcast("queue:tickets", "ticket_added", %{id: 1})
:ok

iex(5)> flush()
%Phoenix.Socket.Broadcast{
  topic: "queue:tickets",
  event: "ticket_added",
  payload: %{id: 1}
}
:ok
```

Desta vez usamos [`Endpoint.subscribe/2`](https://hexdocs.pm/phoenix/1.8.7/Phoenix.Endpoint.html#c:subscribe/2) para assinar o tópico `"queue:tickets"` e `Endpoint.broadcast/3` para enviar uma mensagem a ele. Depois usamos `flush()` para mostrar todas as mensagens recebidas por este processo.

Talvez eu tenha acabado de soltar uma bomba: shells `iex` são processos de longa duração e os LiveViews também são. No Elixir, processos têm uma caixa de entrada que acumula mensagens até que sejam lidas. É por isso que `flush()` é tão útil: ele permite que você veja todas as mensagens recebidas por um processo. Experimente:

```elixir
iex(6)> Endpoint.broadcast("queue:tickets", "ticket_added", %{id: 2})
:ok

iex(7)> Endpoint.broadcast("queue:tickets", "ticket_added", %{id: 3})
:ok

iex(8)> flush()
%Phoenix.Socket.Broadcast{
  topic: "queue:tickets",
  event: "ticket_added",
  payload: %{id: 2}
}
%Phoenix.Socket.Broadcast{
  topic: "queue:tickets",
  event: "ticket_added",
  payload: %{id: 3}
}
:ok
```

Bem, em LiveViews reais não vamos usar `flush()`, vamos tratar as mensagens conforme elas chegam para atualizar nossa UI adequadamente.

## Resumo!

- Sempre pense no seu caso de uso antes de escrever código.
- Broadcasts enviam mensagens para todos os processos que estão ouvindo um determinado tópico.
- Subscriptions podem ser feitas por qualquer processo para receber mensagens de um tópico.
- LiveViews são processos e o `iex` também é.
- Você pode usar `flush()` no `iex` para ver todas as mensagens recebidas por um processo.
