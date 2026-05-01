%{
title: "JS.push/1",
author: "Lubien",
tags: ~w(getting-started),
section: "Eventos",
description: "Como enviar dados com eventos de uma forma alternativa",
previous_page_id: "v2-phx-value",
next_page_id: "v2-multiple-pushes"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nessa página, pode ficar confuso porque é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por aqui, você pode clonar a versão inicial desta aula com o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

Na aula anterior aprendemos como usar o binding `phx-value-*` para passar valores em um evento. Recapitulando:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="+5" phx-click="add" phx-value-amount={+5} />
    <input type="button" value="+10" phx-click="add" phx-value-amount={+10} />
    <input type="button" value="-5" phx-click="add" phx-value-amount={-5} />
    <input type="button" value="-10" phx-click="add" phx-value-amount={-10} />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    amount = String.to_integer(amount)
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end
```

No entanto, falamos sobre como os valores serão enviados estritamente como strings. O LiveView também possui uma forma alternativa de disparar eventos chamada [`JS.push/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#push/2), que faz parte dos chamados JS Commands. Atualize seu `page_live.ex` para usar `JS.push/2`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="+5" phx-click={JS.push("add", value: %{amount: +5})} />
    <input type="button" value="+10" phx-click={JS.push("add", value: %{amount: +10})} />
    <input type="button" value="-5" phx-click={JS.push("add", value: %{amount: -5})} />
    <input type="button" value="-10" phx-click={JS.push("add", value: %{amount: -10})} />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end
```

Simplificamos nossa LiveView usando `JS.push/2` diretamente no binding `phx-click` e definindo que estamos disparando o evento `"add"` e o valor será `%{amount: INTEGER}`. Este `phx-click` será serializado como JSON para que, quando o botão for clicado, o `amount` seja um inteiro como esperado.

## Dica extra: usando loops para evitar código duplicado

Poderíamos evitar alguma duplicação de código usando um simples `:for`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: {@temperature_celsius}C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input
      :for={value <- [5, 10, -5, -10]}
      type="button"
      value={"Add #{value}"}
      phx-click={JS.push("add", value: %{amount: value})}
    />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end
```

Essa dica também funciona para a aula anterior com `phx-value-amount`. Leve isso como uma tarefa para tentar fazer com o código da aula anterior.

## Resumindo!

- Usando JS Commands podemos trocar uma combinação de bindings `phx-click` + `phx-value-*` por apenas um binding `phx-click` contendo um `JS.push/2`.
- `JS.push/2` simplifica a serialização de dados que não são strings nos valores porque inteiros fazem parte do que o JSON suporta, então os dados disparados serão um inteiro como esperado.