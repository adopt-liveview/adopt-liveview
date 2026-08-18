%{
title: "Configurando a View Transitions API",
author: "Lubien",
tags: ~w(snippets view-transitions),
section: "Snippets",
description: "Um guia passo a passo para habilitar a View Transitions API nativa em cima do Phoenix LiveView.",
previous_page_id: nil,
next_page_id: nil,
}

---

A [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API) permite que o navegador anime mudanças no DOM entre dois estados, dando a você cross-fades suaves e transições de elementos compartilhados de graça. Este snippet mostra como conectar tudo isso em uma aplicação Phoenix LiveView para que você possa disparar transições tanto em navegação por links quanto em atualizações vindas do servidor.

Siga os passos na ordem. Cada passo é construído em cima do anterior, e ao final do passo 3 todas as peças estarão conectadas.

## Passo 1: Adicione o `ViewTransitionHook`

Abra o arquivo `assets/js/app.js` e adicione o hook abaixo próximo ao topo do arquivo. Esse hook intercepta cliques nos links em que você optar por usá-lo e marca os elementos que devem ser animados antes de delegar a navegação de volta ao LiveView.

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

A função `startViewTransition` que ele referencia será definida no Passo 3 — não se preocupe, tudo estará devidamente conectado ao final do guia.

Agora registre o hook no `LiveSocket` para que o LiveView consiga encontrá-lo:

```diff
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
-  hooks: {...colocatedHooks},
+  hooks: { ...colocatedHooks, ViewTransitionHook },
```

## Passo 2: Prepare o `onDocumentPatch`

A View Transitions API precisa ser avisada quando o DOM está prestes a mudar, para que ela possa capturar os snapshots do "antes" e do "depois". Vamos fazer isso a partir do callback `onDocumentPatch` do DOM do LiveView.

Primeiro, adicione essas três variáveis a nível de módulo **acima** da declaração do `liveSocket`. Elas funcionam como um pequeno buffer que coleta quais elementos e tipos de transição vão participar do próximo patch.

```javascript
let transitionTypes = [];
let transitionEls = [];
let scheduleTransition = null;
```

Agora adicione uma opção `dom` na configuração do seu `LiveSocket` com um handler `onDocumentPatch` que envelopa o callback `start` do LiveView dentro de uma chamada a `document.startViewTransition`:

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

Depois das duas edições, seu bloco `LiveSocket` deve estar assim:

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

## Passo 3: Suporte ao evento global `phx:start-view-transition`

Agora podemos definir `startViewTransition`, que é usada tanto pelo hook (do Passo 1) quanto por qualquer `JS.dispatch("phx:start-view-transition", ...)` disparado a partir dos seus templates renderizados no servidor.

Cole o seguinte **depois** de `liveSocket.connect()`:

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

Essa função faz duas coisas: marca o elemento com um `view-transition-name` único (vindo das opções do JS ou do atributo `data-transition-name`) e enfileira a transição para que o próximo `onDocumentPatch` envelope a atualização em uma chamada `document.startViewTransition`.

## Passo 4: Cole o CSS de exemplo

Adicione o CSS abaixo à sua folha de estilos principal (por exemplo, `assets/css/app.css`). Ele define padrões sensatos para animações de entrada/saída em nível de página, respeita `prefers-reduced-motion` e inclui um exemplo compartilhado para o grupo de transição `role-slide-out-left`.

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

::view-transition-old(role-slide-out-left) {
    opacity: 1;
}

::view-transition-group(role-slide-out-left) {
    opacity: 1;
    animation-name: slide-out-to-left;
    z-index: 1;
}
::view-transition-old(role-slide-out-left) {
    animation-name: slide-out-to-left;
    opacity: 1;
}
::view-transition-new(role-slide-out-left) {
    opacity: 1;
}


/* </View Transitions> */
```

Fique à vontade para customizar qualquer um dos keyframes, durações, easings ou regras de transition-group para casar com a sua marca. A API é intencionalmente dirigida por CSS, então a maioria dos ajustes vive aqui, não no JavaScript.

## Uso

### Com navegação via `<.link>`

Adicione `phx-hook="ViewTransitionHook"` em qualquer `<.link>` que deva disparar uma view transition. Em seguida, coloque `data-transition-name="NOMEIE_SUA_TRANSICAO_AQUI"` nos elementos internos específicos que você quer animar (para transições de elementos compartilhados entre a página atual e a próxima).

```heex
<.link id={...} navigate={...} class="..." phx-hook="ViewTransitionHook">
  ...
  <div class="..." data-transition-name="match-title">
    {@title}
  </div>
</.link>
```

> ⚠️ **IDs únicos são obrigatórios.** Todo elemento que participa de uma view transition precisa de um `id` estável e único (tanto no próprio link quanto em qualquer filho que use `data-transition-name`). Se dois elementos acabarem compartilhando o mesmo transition name durante a mesma transição, o navegador vai se recusar a animar e você verá erros no console de desenvolvedor.

### Durante navegação com a página no mesmo lugar

Quando um LiveView faz patch da página atual (em vez de navegar para uma nova), o hook não dispara porque não há clique. Nesse caso, use `JS.dispatch/2` no elemento mais externo que você quer animar para fora, ligado a um binding de ciclo de vida do LiveView como `phx-remove`.

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

O mapa `detail` é o que alimenta o `startViewTransition`: `transition_name` vira o `view-transition-name` do CSS, e `type` é empurrado para a lista de `types` da transição, o que permite escrever regras `@view-transition` específicas por tipo.

## Recapitulando

- **Passo 1** adicionou o `ViewTransitionHook` para permitir que links individuais entrem no fluxo das view transitions e o registrou no `LiveSocket`.
- **Passo 2** conectou o `onDocumentPatch` para que os patches do DOM feitos pelo LiveView sejam envelopados em `document.startViewTransition`, com um fallback seguro para navegadores que ainda não suportam as opções por callback (é com você, Firefox 144).
- **Passo 3** definiu o helper `startViewTransition` e o conectou ao evento global `phx:start-view-transition`, para que despachos vindos do JS e do servidor compartilhem o mesmo caminho de código.
- **Passo 4** trouxe um conjunto inicial de CSS com padrões sensatos, tratamento de reduced-motion e um exemplo de transição nomeada.

Daqui em diante você pode animar links adicionando `phx-hook="ViewTransitionHook"` e `data-transition-name` em qualquer filho, ou animar patches no mesmo lugar disparando `phx:start-view-transition` a partir de bindings de ciclo de vida do LiveView. Só lembre-se de manter esses IDs e transition names únicos!
