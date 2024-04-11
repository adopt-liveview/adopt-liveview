%{
title: "Your first Live View",
author: "Lubien",
tags: ~w(getting-started),
section: "Introduction",
description: "How to start programming with LiveView?",
previous_page_id: "getting-started",
next_page_id: "explain-playground"
}

---

## One step at a time

The Phoenix framework brings with it several tools configured so you don't have to worry: sending emails, real-time presence system, clustering, etc. This is amazing when you need to deliver a product as quickly as possible but it can be daunting when you're just starting out.

To make it easier to understand I built a very lean version of LiveView called [LiveView Playground](https://hexdocs.pm/liveview_playground/0.1.1/readme.html). We will use it at the beginning of this course and gradually add more features so you understand how things work in Phoenix and LiveView bit by bit.

## The most basic LiveView

For simple scripts the `elixir` command briefly executes a file. Let's create a file called `hello_liveview.exs`.

```elixir
# contents of hello_liveview.exs

Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end

LiveviewPlayground.start()
```

%{
title: ".ex or .exs?",
description: ~H"""
<CursoWeb.CoreComponents.prose>
The extension of real project files in elixir is <code>.ex</code>, whereas the extension <code>.exs</code> is more often used to denote that this file is just a separate script that is not part of the main project. We also use <code>.exs</code> as an extension for our tests.
</CursoWeb.CoreComponents.prose>
"""
} %% .callout

Then just run `elixir hello_liveview.exs` in your terminal and the server will be available at http://localhost:4000

## Try it out

Try putting some HTML in your `render/1` function. To be able to see the changes you will need to shut down the server with `Control+c` twice and run the project again.

## Success!

Now that you have LiveView Playground in your hands, in the next steps we will understand what each piece of this code represents.
