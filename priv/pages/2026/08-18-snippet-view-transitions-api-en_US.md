%{
title: "Setting up View Transitions API",
author: "Lubien",
tags: ~w(snippets view-transitions),
section: "Snippets",
description: "A step-by-step guide to enable the native View Transitions API on top of Phoenix LiveView.",
previous_page_id: nil,
next_page_id: nil,
}

---

The [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API) lets the browser animate DOM changes between two states, giving you smooth cross-fades and shared-element transitions for free. This snippet walks you through wiring it up inside a Phoenix LiveView app so you can trigger transitions both on link navigation and on server-driven page updates.

## Step 1: Add the `ViewTransitionHook`

Open your `assets/js/app.js` and add the following hook near the top of the file. This hook intercepts clicks on links you opt-in and marks the elements that should be animated before delegating navigation back to LiveView.

```javascript
const ViewTransitionHook = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault();

      const $parentOrSelf = this.el.dataset.parentId
        ? this.el.closest(`#${this.el.dataset.parentId}`)
        : this.el;

      if ($parentOrSelf) {
        $parentOrSelf.classList.add("navigating");

        if ($parentOrSelf.dataset.transitionName) {
          startViewTransition({ target: $parentOrSelf });
        }
        for (const child of $parentOrSelf.querySelectorAll(
          "[data-transition-name]",
        )) {
          child.classList.add("navigating");
          startViewTransition({ target: child });
        }
      } else {
        console.error("No parent or self found for transition", this.el);
      }

      liveSocket.js().navigate(this.el.href);
    });
  },
};
```

The `startViewTransition` helper it references will be defined in Step 3 — don't worry, everything is fully wired up by the end of the guide.

Now register the hook on the `LiveSocket` so LiveView can find it:

```diff
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
-  hooks: {...colocatedHooks},
+  hooks: { ...colocatedHooks, ViewTransitionHook },
```

## Step 2: Prepare `onDocumentPatch`

The View Transitions API needs to be told when the DOM is about to change so it can capture the "before" and "after" snapshots. We'll do that from LiveView's `onDocumentPatch` DOM callback.

First, add these three module-level variables **above** the `liveSocket` declaration. They act as a small buffer that collects which elements and transition types should participate in the next patch.

```javascript
let transitionTypes = [];
let transitionEls = [];
let scheduleTransition = null;
```

Now add a `dom` option to your `LiveSocket` config with an `onDocumentPatch` handler that wraps LiveView's `start` callback in a `document.startViewTransition` call:

```javascript
dom: {
    onDocumentPatch(start) {
      const update = () => {
        // reset transitionEls
        transitionEls.forEach((el) => (el.style.viewTransitionName = ""));
        transitionEls = [];
        transitionTypes = [];
        scheduleTransition = null;
        start();
      };
      const supportsViewTransitions =
        typeof document.startViewTransition === "function";
      if (
        supportsViewTransitions &&
        (transitionEls.length !== 0 || scheduleTransition)
      ) {
        // firefox 144 doesn't support the callbackOptions yet, so fallback to the basic version.
        try {
          document.startViewTransition({
            // tsc somehow doesn't know about the `update` param??!
            // @ts-expect-error
            update,
            types: transitionTypes.length ? transitionTypes : ["same-document"],
          });
        } catch (error) {
          document.startViewTransition(update);
        }
      } else {
        update();
      }
    },
  },
```

After both edits, your `LiveSocket` block should look like this:

```javascript
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: { ...colocatedHooks, ViewTransitionHook },
  dom: {
    onDocumentPatch(start) {
      const update = () => {
        // reset transitionEls
        transitionEls.forEach((el) => (el.style.viewTransitionName = ""));
        transitionEls = [];
        transitionTypes = [];
        scheduleTransition = null;
        start();
      };
      const supportsViewTransitions =
        typeof document.startViewTransition === "function";
      if (
        supportsViewTransitions &&
        (transitionEls.length !== 0 || scheduleTransition)
      ) {
        // firefox 144 doesn't support the callbackOptions yet, so fallback to the basic version.
        try {
          document.startViewTransition({
            // tsc somehow doesn't know about the `update` param??!
            // @ts-expect-error
            update,
            types: transitionTypes.length ? transitionTypes : ["same-document"],
          });
        } catch (error) {
          document.startViewTransition(update);
        }
      } else {
        update();
      }
    },
  },
})
```

## Step 3: Support the global `phx:start-view-transition` event

Now we can define `startViewTransition`, which is used by both the hook (from Step 1) and by any `JS.dispatch("phx:start-view-transition", ...)` calls from your server-rendered templates.

Paste the following **after** `liveSocket.connect()`:

```javascript
function startViewTransition(e) {
  const target = e.target;
  const opts = e.detail || {};
  const transition_name =
    opts.transition_name ||
    (target && target.dataset && target.dataset.transitionName);
  if (target && target.style && transition_name && target !== window) {
    target.style.viewTransitionName = transition_name;
    transitionEls.push(e.target);
  }
  if (opts.type) {
    transitionTypes.push(opts.type);
  }
  scheduleTransition = true;
}

window.addEventListener("phx:start-view-transition", startViewTransition);
```

This function does two things: it tags the element with a unique `view-transition-name` (either from JS options or from the `data-transition-name` attribute) and it queues the transition so the next `onDocumentPatch` will wrap the update in `document.startViewTransition`.

## Step 4: Paste the example CSS

Drop the CSS below into your main stylesheet (for example, `assets/css/app.css`). It defines sensible defaults for page-level enter/exit animations, respects `prefers-reduced-motion`, and includes a shared example for a `event-slide-out-left` transition group.

```css
/* <View Transitions> */

:root {
    --enter-anim:
        210ms cubic-bezier(0, 0, 0.2, 1) 90ms both fade-in,
        300ms cubic-bezier(0.4, 0, 0.2, 1) both slide-from-right;
    --exit-anim:
        90ms cubic-bezier(0.4, 0, 1, 1) both fade-out,
        300ms cubic-bezier(0.4, 0, 0.2, 1) both slide-to-left;
}

@view-transition {
    navigation: auto;
    view-transition-type: page;
}

@media (prefers-reduced-motion) {
    ::view-transition-group(*),
    ::view-transition-old(*),
    ::view-transition-new(*) {
        animation: none !important;
    }
}
@keyframes fade-in {
    from {
        opacity: 0;
    }
}
@keyframes fade-out {
    to {
        opacity: 0;
    }
}
@keyframes slide-from-right {
    from {
        transform: translateX(30px);
    }
}
@keyframes slide-to-left {
    to {
        transform: translateX(-30px);
    }
}
@keyframes slide-out-to-left {
    to {
        translate: -100vw 0;
    }
}
@keyframes slide-out-to-bottom {
    to {
        translate: 0 100vh;
    }
}

::view-transition-old(event-slide-out-left) {
    opacity: 1;
}

::view-transition-group(event-slide-out-left) {
    opacity: 1;
    animation-name: slide-out-to-left;
    z-index: 1;
}
::view-transition-old(event-slide-out-left) {
    animation-name: slide-out-to-left;
    opacity: 1;
}
::view-transition-new(event-slide-out-left) {
    opacity: 1;
}


/* </View Transitions> */
```

Feel free to customize any of the keyframes, durations, easings, or transition-group rules to match your brand. I literally copy and paste code from my own projects here.

## Usage

### With `<.link>` navigation

Attach `phx-hook="ViewTransitionHook"` to any `<.link>` that should trigger a view transition. Then add `data-transition-name="NAME_YOUR_TRANSITION_HERE"` on the specific inner elements you want to animate (for shared-element transitions between the current and next page).

```heex
<.link id={...} navigate={...} class="..." phx-hook="ViewTransitionHook">
  ...
  <div class="..." data-transition-name="match-title">
    {@title}
  </div>
</.link>
```

> ⚠️ **Unique IDs are mandatory.** Every element that participates in a view transition needs a stable, unique `id`. 

### During in-place page navigation

When a LiveView patches the current page (as opposed to navigating to a new one), the hook won't fire because there's no click. In that case, use `JS.dispatch/2` on the outermost element you want to animate out, tied to a LiveView lifecycle binding like `phx-remove`.

```heex
<article
  id="event-card"
  class="..."
  phx-remove={
    JS.dispatch("phx:start-view-transition",
      to: "#event-card",
      detail: %{transition_name: "event-slide-out-left", type: "page"}
    )
  }
>
```

The `detail` map is what feeds `startViewTransition`: `transition_name` becomes the CSS `view-transition-name`, and `type` is pushed into the transition's `types` list, which lets you write targeted `@view-transition` rules per type.

## Recap

- **Step 1** added `ViewTransitionHook` for opting individual links into view transitions and registered it on the `LiveSocket`.
- **Step 2** wired `onDocumentPatch` so LiveView DOM patches are wrapped in `document.startViewTransition`, with a safe fallback for browsers that don't yet support the callback options (looking at you, Firefox 144).
- **Step 3** defined the `startViewTransition` helper and hooked it up to the global `phx:start-view-transition` event.
- **Step 4** provided a starter CSS set with sane defaults, reduced-motion handling, and an example named transition.

From here you can animate links by adding `phx-hook="ViewTransitionHook"` plus `data-transition-name` on any children, or animate in-place patches by dispatching `phx:start-view-transition` from LiveView lifecycle bindings. Just remember to keep those IDs and transition names unique!
