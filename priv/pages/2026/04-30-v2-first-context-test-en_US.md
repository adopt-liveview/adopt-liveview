%{
title: "First context test",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Lets use mix test for the first",
previous_page_id: "v2-saving-data",
next_page_id: "v2-listing-data"
}

---

%{
title: "This class is a direct continuation of the previous class",
type: :warning,
description: ~H"""
If you hopped directly into this page it might be confusing because it is a direct continuation of the code from the previous lesson. If you want to skip the previous lesson and start straight with this one, you can clone the initial version for this lesson using the command <code>`git clone https://github.com/adopt-liveview/lineup.git --branch saving-data-done`</code>.
"""
} %% .callout

I might be biased since I like Elixir and Phoenix so much to say this but I can tell you that this is the stack I'm most comfortable writting test for frontend code that I've ever been. And there's a good reason for it: HEEx code is just a as functional as a frontend can get! You pass arguments over assigns and you get a generated HTML code.

Of course right now you must be cursing at me for claiming since there are obvious side effects within HEEx code such as navigation, form update/submit events and even JS calls with JS commands. But give me a few lessons to show you that it will all make sense in the end.

## Our tools

Elixir ships with a test runner and assertion library called [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html), you don't need to install anything. In fact, we already have some tests built in by Phoenix. Also since we never paid attention to we actually broke it many lessons ago!

Inside your LiveView project run `mix test`:

```
....

  1) test GET / (LineupWeb.PageControllerTest)
     test/lineup_web/controllers/page_controller_test.exs:4
     Assertion with =~ failed
     code:  assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
     left:  "<!DOCTYPE html>A BUNCH OF HTML CODE!</html>"
     right: "Peace of mind from prototype to production"
     stacktrace:
       test/lineup_web/controllers/page_controller_test.exs:6: (test)


Finished in 0.04 seconds (0.01s async, 0.03s sync)
5 tests, 1 failure
```

Don't worry if you get some warnings, lets focus on the error. In a vibrant red color you should see that our test rendered a bunch of HTML code but it expected to at least have "Peace of mind from prototype to production" written inside it. To digest what a failing test mean:

```
  1) test [Here's the name of the test case] ([Here's the name of the test module])
     [here's the relative path to the test file]:[here's the line number where this test case is written]
     Assertion with =~ failed    <- [some information about why it failed, it says a `=~` operator did not pass]
     code:  [test code that failed]
     left:  [what's written inside the left hand side of the =~ operator]
     right: [what's written inside the right hand side of the =~ operator]
     stacktrace:
       [relative path]:[line number]: (test)     <- [where exactly your test failed inside this test case]
```

Knowing how to read those will make your life easier. The error above is a simple case "text-based match". When used like this `body =~ part` we expected `part` to be contained inside `body`. In this case `html_response(conn, 200) =~ "Peace of mind from prototype to production"` we expected the result HTML to contain that phrase. Let's head out to `test/lineup_web/controllers/page_controller_test.exs:6`, focus solely on the test case:

```elixir
test "GET /", %{conn: conn} do
  conn = get(conn, ~p"/")
  assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
end
```

As you can see we have tons of new things here to understand. For now lets focus on fixing this test. By starting our Super Store project we can spot that the root page (/) has a "Listing Products" heading. Let's update our test and run `mix test again`.

```diff
test "GET /", %{conn: conn} do
  conn = get(conn, ~p"/")
- assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
+ assert html_response(conn, 200) =~ "Listing Tickets"
end
```

```sh
$ mix test
Running ExUnit with seed: 610698, max_cases: 28

.....
Finished in 0.08 seconds (0.03s async, 0.05s sync)
5 tests, 0 failures
```

And that's it, we have our test suite passing!

## Our context module test

Since we already have some new code for our ticket management system we might as well starting building our test cases. Lets create our context module test file. Create: `test/lineup/queue_test.exs` (you might need to create the `lineup` folder inside `test`).

```elixir
defmodule Lineup.QueueTest do
  use Lineup.DataCase

  alias Lineup.Queue

  describe "tickets" do
    alias Lineup.Queue.Ticket

    import Lineup.QueueFixtures

    test "create_ticket/1 with valid data creates a ticket" do
      valid_attrs = %{called_at: ~U[2026-04-27 16:00:00Z]}

      assert {:ok, %Ticket{} = ticket} = Queue.create_ticket(valid_attrs)
      assert ticket.called_at == ~U[2026-04-27 16:00:00Z]
    end

    test "change_ticket/1 returns a ticket changeset" do
      ticket = ticket_fixture()
      assert %Ecto.Changeset{} = Queue.change_ticket(ticket)
    end
  end
end
```

For that to work we will also need a helper so create `test/support/fixtures/queue_fixtures.ex` (you might need to create the `fixtures` folder):

```elixir
defmodule Lineup.QueueFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lineup.Queue` context.
  """

  @doc """
  Generate a ticket.
  """
  def ticket_fixture(attrs \\ %{}) do
    {:ok, ticket} =
      attrs
      |> Enum.into(%{
        called_at: ~U[2026-04-27 16:00:00Z]
      })
      |> Lineup.Queue.create_ticket()

    ticket
  end
end
```

Now we can use `mix test` can be done to run that specific test file, you have pass its relative path. Try it:

```sh
$ mix test test/lineup/queue_test.exs
Running ExUnit with seed: 469161, max_cases: 28

..
Finished in 0.04 seconds (0.00s async, 0.04s sync)
2 tests, 0 failures
```

Let's talk about what we just wrote! First of all in elixir we try to have some parity between where code lives and where their respective test case lives. In our case `lib/lineup/queue.ex` has a test file in `test/lineup/queue_test.exs`. Also as you can see we append `_test` to file and module names so `Lineup.Queue` is tested by `Lineup.QueueTest`. Another difference is that for test files we use the `.exs` extension which is common to Elixir scripts whilst `.ex` is used for parts of projects.

Just like in LiveViews we `use MyappWeb, :live_view` we also have helpers to write tests. In our case since we are working with regular data we `use Lineup.DataCase`. That module is already written inside your project and just like `LineupWeb` it will import and alias useful things for your test case. You can open `test/support/data_case.ex` in case you're curious but unless you need to install something in there its likely you wont need to bother with it at all.

You might have also noticed that we have `describe "tickets" do ... end` inside our test file. ExUnit's [describe/2](https://hexdocs.pm/ex_unit/ExUnit.Case.html#describe/2) works to group tests together not only in code but also when formatting then. Later on we will see how we can use them to setup common shared code alongside multiple individual test cases inside it. Also its worth mentioning that since we are testing the Linup context module and context modules can have more than one ecto model its useful to have them separate each part of your business logic. 

In our first test case `"create_ticket/1 with valid data creates a ticket"` we just verify in our unit tests what we already built before: passing some attributes to `Queue.create_ticket/2` will generate a new ticket. As for our second test case `"change_ticket/1 returns a ticket changeset"` we ensure that passing a valid ticket will generate an `%Ecto.Changeset{}`.

At the very top of our `change_ticket` test case we use `ticket_fixture/1` to quickly create a simple ticket that we can use in our test code. We imported that just a few lines before in `import Lineup.QueueFixtures` and thats basically what fixtures are meant to do.

With both tests set we can ensure that we will know beforehand if we ever break those contracts and we can check that our expected behaviors might have regressed or just changed some how.

## Recap

In this lesson, we've taken our first steps into testing with Elixir and Phoenix:

1. We discovered that Elixir comes with ExUnit, a built-in test runner and assertion library
2. We ran our first test suite using `mix test` and encountered a failing test
3. You can run a specific test file by passing its relative path such as `mix test test/inner/something_test.exs`
4. We learned how to read and interpret test failure messages in ExUnit
5. Elixir's built-in test runner is called ExUnit
6. In Elixir we have a convention of placing test files inside `test` folder with the same path as it would have been in `lib` folder (`lib/inner/something.ex` has a test in `test/inner/something_test.exs`), with test modules having `SomethingTest` naming and `.exs` extension
7. We use `describe` blocks to organize groups of tests
8. We use fixtures to quickly create some test data such as storing things in the database
9. Phoenix will come with `Myapp.DataCase` to help with tests related to data (usually context modules).
