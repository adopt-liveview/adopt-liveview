%{
title: "Cleaning things up",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Let's remove some dead code and see what we've got",
previous_page_id: "v2-my-first-liveview-project",
next_page_id: "v2-saving-data"
}

---

%{
title: "This lesson is a direct continuation of the previous lesson",
type: :warning,
description: ~H"""
If you hopped directly into this page, it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git`</code>.
"""
} %% .callout

Before we proceed, let's do some house cleaning! Open `lib/lineup_web/router.ex` so we can change our root path from a dead view (just a fancy way of saying Controller Action) to a LiveView.

```elixir
scope "/", LineupWeb do
  pipe_through :browser

  # Delete this
  get "/", PageController, :home
  # Add this
  live "/tickets", TicketLive.Index, :index
end
```

Now we need to create our first LiveView in `lib/lineup_web/live/ticket_live/index.ex`:

```elixir
defmodule LineupWeb.TicketLive.Index do
  use LineupWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Tickets")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tickets
      </.header>
      List tickets here
    </Layouts.app>
    """
  end
end
```

We have new things to talk about here!

## The `@page_title` assign

This is a special assign that will be used to populate your LiveView's `<title>content</title>` tag. Head to `lib/lineup_web/components/layouts/root.html.heex` and let's change it a little bit!

```diff
- <.live_title default="Lineup" suffix=" · Phoenix Framework">
-   {assigns[:page_title]}
- </.live_title>
+ <.live_title default="Lineup" suffix=" · LineUp App" phx-no-format>{assigns[:page_title]}</.live_title>
```

Now we have a proper suffix for our app. Make sure to add `page_title` to all your LiveViews!

## The `Layouts.app` component

New Phoenix projects now come with layout components inside `YouappWeb.Layouts` so you can easily tweak them or add more. As you might expect, `use LineupWeb, :live_view` has aliases for `alias LineupWeb.Layouts` so you can use `<Layouts.app flash={@flash}>`. For now, ignore `@flash` assignment, we will look at it very soon.

Let's tweak our main template! Head out to `lib/lineup_web/components/layouts.ex` and change your `def app(assigns) do` like this:

```elixir
def app(assigns) do
  ~H"""
  <header class="navbar px-4 sm:px-6 lg:px-8">
    <div class="flex-1">
      <a href="/" class="flex-1 flex w-fit items-center gap-2">
        <span class="text-2xl font-bold tracking-tight text-primary">
          Line<span class="text-base-content">Up</span>
        </span>
        <span class="text-xs font-medium text-base-content/60 -ml-1">App</span>
      </a>
    </div>
    <div class="flex-none">
      <ul class="flex flex-column px-1 space-x-4 items-center">
        <li>
          <.theme_toggle />
        </li>
      </ul>
    </div>
  </header>

  <main class="px-4 py-20 sm:px-6 lg:px-8">
    <div class="mx-auto max-w-2xl space-y-4">
      {render_slot(@inner_block)}
    </div>
  </main>

  <.flash_group flash={@flash} />
  """
end
```

We just edited the logo to use a text and removed some Phoenix references so our app starts to feel like our own. We didn't remove the theme toggle though because it's quite nice to have it for our own users. With tailwind already setup to have theme toggle we can add classes with `dark:class-name` that only work in dark theme.

## Deleting dead code

Since we won't be using those anymore, let's remove dead files:

```sh
rm priv/static/images/logo.svg
rm lib/lineup_web/controllers/page_html/home.html.heex
```

And we can also remove our dead controller action in `lib/lineup_web/controllers/page_controller.ex`:

```diff
defmodule LineupWeb.PageController do
  use LineupWeb, :controller

-  def home(conn, _params) do
-    render(conn, :home)
-  end
end
```

## Recap!

- The `@page_title` assign is a magical assign to update HTML title tag.
- Don't forget to update your `<.live_title>` in your root template to match your project name when you get started.
- `YouappWeb.Layouts` is where layouts are going to be created to be used alongside your LiveViews.
- Delete your dead code. Coworkers will praise you.
