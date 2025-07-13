%{
title: "My First Test",
author: "Lubien",
tags: ~w(testing),
section: "Testing",
description: "Learning how to write your first Elixir test",
previous_page_id: "modal-form",
}

---

I might be biased since I like Elixir and Phoenix so much to say this but I can tell you that this is the stack I'm most comfortable writting test for frontend code that I've ever been. And there's a good reason for it: HEEx code is just a as functional as a frontend can get! You pass arguments over assigns and you get a generated HTML code.

Of course right now you must be cursing at me for claiming since there are obvious side effects within HEEx code such as navigation, form update/submit events and even JS calls with JS commands. But give me a few lessons to show you that it will all make sense in the end.

%{
title: "Prerequisites",
type: :warning,
description: ~H"""
This lesson assumes you've completed the previous lessons and have a Phoenix LiveView project set up. If you want to start directly with this lesson, you can clone the repository using <code>`git clone https://github.com/adopt-liveview/first-tests.git`</code>.
"""
} %% .callout

## Our tools

Elixir ships with a test runner and assertion library called [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html), you don't need to install anything. In fact, we already have some tests built in by Phoenix. Also since we never paid attention to we actually broke it many lessons ago!

Inside your LiveView project run `mix test`:

```
$ mix test
....

  1) test GET / (SuperStoreWeb.PageControllerTest)
     test/super_store_web/controllers/page_controller_test.exs:4
     Assertion with =~ failed
     code:  assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
     left:  "<!DOCTYPE html>A BUNCH OF HTML CODE!</html>"
     right: "Peace of mind from prototype to production"
     stacktrace:
       test/super_store_web/controllers/page_controller_test.exs:6: (test)


Finished in 0.06 seconds (0.02s async, 0.04s sync)
5 tests, 1 failure

Randomized with seed 60801
```

Don't worry if you get some warnings, lets focus on the error. In a vibrant read color you should see that our test rendered a bunch of HTML code but it expected to at least have "Peace of mind from prototype to production" written inside it. To digest what a failing test mean:

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

Knowing how to read those will make your life easier. The error above is a simple case "text-based match". When used like this `body =~ part` we expected `part` to be contained inside `body`. In this case `html_response(conn, 200) =~ "Peace of mind from prototype to production"` we expected the result HTML to contain that phrase. Let's head out to `test/super_store_web/controllers/page_controller_test.exs:4`, focus solely on the test case:

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
+ assert html_response(conn, 200) =~ "Listing Products"
end
```

```
$ mix test
.....
Finished in 0.05 seconds (0.02s async, 0.03s sync)
5 tests, 0 failures

Randomized with seed 811883
```

And that's it, we have our test suite passing!

## Recap

In this lesson, we've taken our first steps into testing with Elixir and Phoenix:

1. We discovered that Elixir comes with ExUnit, a built-in test runner and assertion library
2. We ran our first test suite using `mix test` and encountered a failing test
3. We learned how to read and interpret test failure messages in ExUnit
