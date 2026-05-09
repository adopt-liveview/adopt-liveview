%{
title: "Your First PubSub",
author: "Lubien",
tags: ~w(realtime),
section: "Real Time with LiveView",
description: "Track changes across LiveViews for multiple users",
previous_page_id: "v2-form-component",
next_page_id: "v2-ticket-creation-in-real-time",
}

---

Phoenix projects come with batteries include to let you ship real time software. Today we are going to talk about one of the major features of Phoenix: PubSub.

## Defining the problem

We are building a ticket queueing system where users can get their tickets and our main page should keep track of whoever is next in line. We don't want to ask users to keep refreshing the page whenever someone is arrives. We don't need to. To start working with PubSub (public subscriptions) we only need to think about two things:

- What are the triggers for a real time update?
- Who needs to know about what updated?

If you can answer those two you can define an use case for PubSubs. Let's do some code now.

## Our work scope

Lets write this down as an use case:

> Given I am a customer using this ticket system, I want to get a ticket and the staff will be notified about my presence on the queue. 

Now we translate that we have the use case let's translate it into actionable programming steps.

- What are the triggers for a real time update?
  - User creates a ticket.
- Who needs to know about what updated?
  - The ticket list.

## Broadcasts

When you want other LiveViews to be notified about something, we need to use PubSub broadcasts. Just think of it as a message being sent across to everyone that wants to hear about that. There are multiple ways to broadcast a message but as we are working with LiveView, we will prefer to use [`MyappWeb.Endpoint.broadcast/3`](https://hexdocs.pm/phoenix/1.8.7/Phoenix.Endpoint.html#c:broadcast/3). Let's play a little bit with it. 

On your terminal run the following to start an Interactive Elixir shell:

```elixir
$ iex -S mix
Interactive Elixir (1.19.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> alias LineupWeb.Endpoint
LineupWeb.Endpoint

iex(2)> Endpoint.broadcast("queue:tickets", "ticket_added", %{id: 1})
:ok
```

We alised our `LineupWeb.Endpoint` so we can just call `Endpoint.something` later one.

The broadcast function takes 3 arguments:

- A topic: can be any string.
- An event: also any string.
- A payload: a map of data to send with the event.

Since we are working with tickets we chose the topic to be `"queue:tickets"` as it relates to our context and model relationship, but it could have been anything really like "my-system-notifications123". As for the event name you want to be very clear to make sure that your code is easier to understand on the future. As for the last argument you can pass anything to that map. For now, we chose to pass a map with the ticket id so that the receiving LiveView can use it to update the UI.

So what? Nothing happened. Sending messages is not useful unless we have someone waiting for them.

## Subscriptions

The reason a topic exists on PubSubs is that we know who is interested in receiving messages on that topic. Lets go back to our interactive shell and try once more.

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

This time we used [`Endpoint.subscribe/2`](https://hexdocs.pm/phoenix/1.8.7/Phoenix.Endpoint.html#c:subscribe/2) to subscribe to the `"queue:tickets"` topic and `Endpoint.broadcast/3` to send a message to it. Afterwards we used the `flush()` to dump all messages this process received.

I might have just dropped a bomb on you: `iex` shells are a long running process and so are LiveViews. In Elixir, processes have a mailbox that will accumulate messages until they are read. Thats why `flush()` is so useful: it allows you to see all messages received by a process. Try it out:

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

Well, in actual LiveViews we will not be using `flush()`, we will handle the messages as they come so we update our UI accordingly.

## Summary!

- Always think about your use case before writting code.
- Broadcasts send messages to all processes that are listening to a certain topic.
- Subscriptions can be made by any process to receive messages from a topic.
- LiveViews are processes and so is `iex`.
- You can use `flush()` in `iex` to see all messages received by a process.
