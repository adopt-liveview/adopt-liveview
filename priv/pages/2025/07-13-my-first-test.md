%{
title: "Meu Primeiro Teste",
author: "Lubien",
tags: ~w(testing),
section: "Testing",
description: "Aprendendo como escrever seu primeiro teste em Elixir",
previous_page_id: "modal-form",
}

---

Eu posso estar sendo parcial, já que gosto tanto de Elixir e Phoenix, mas posso dizer que esta é a stack com a qual me sinto mais confortável escrevendo test para código frontend que já utilizei. E há uma boa razão para isso: o código HEEx é tão funcional quanto um frontend pode ser! Você passa argumentos através de assigns e obtém um código HTML gerado.

Claro que agora você deve estar me amaldiçoando por afirmar isso, já que existem side effects óbvios no código HEEx, como navegação, eventos de update/submit de formulários e até chamadas JS com comandos JS. Mas aguarde algumas lições para que eu possa mostrar que tudo fará sentido no final.

%{
title: "Pré-requisitos",
type: :warning,
description: ~H"""
Esta lição presume que você completou as lições anteriores e tem um projeto Phoenix LiveView configurado. Se quiser começar diretamente com esta lição, você pode clonar o repositório usando <code>`git clone https://github.com/adopt-liveview/first-tests.git`</code>.
"""
} %% .callout

## Nossas ferramentas

Elixir vem com um test runner e biblioteca de assertions chamada [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html), você não precisa instalar nada. Na verdade, já temos alguns tests criados pelo Phoenix. Além disso, como nunca prestamos atenção, acabamos quebrando esses tests há muitas lições atrás!

Dentro do seu projeto LiveView, execute `mix test` no terminal:

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

Não se preocupe se você receber alguns warnings, vamos focar no erro. Em uma cor vermelha vibrante, você deve ver que nosso test renderizou um monte de código HTML, mas esperava que pelo menos tivesse "Peace of mind from prototype to production" escrito dentro dele. Para entender o que significa um test com falha:

```
  1) test [Aqui está o nome do test case] ([Aqui está o nome do test module])
     [aqui está o caminho relativo para o arquivo de test]:[aqui está o número da linha onde este test case está escrito]
     Assertion with =~ failed    <- [algumas informações sobre por que falhou, diz que um operador `=~` não passou]
     code:  [código de test que falhou]
     left:  [o que está escrito no lado esquerdo do operador =~]
     right: [o que está escrito no lado direito do operador =~]
     stacktrace:
       [caminho relativo]:[número da linha]: (test)     <- [onde exatamente seu test falhou dentro deste test case]
```

Saber como ler isso tornará sua vida mais fácil. O erro acima é um caso simples de "texto contem substring". Quando usado assim `body =~ part`, esperávamos que `part` estivesse contido dentro de `body`. Neste caso em `html_response(conn, 200) =~ "Peace of mind from prototype to production"`, esperávamos que o HTML resultante contivesse essa frase. Vamos verificar `test/super_store_web/controllers/page_controller_test.exs:4`, focando apenas no test case:

```elixir
test "GET /", %{conn: conn} do
  conn = get(conn, ~p"/")
  assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
end
```

Como você pode ver, temos muitas coisas novas para entender aqui. Por enquanto, vamos nos concentrar em corrigir este test. Ao iniciar nosso projeto Super Store, podemos notar que a página raiz (/) tem um header "Listing Products". Vamos atualizar nosso test e executar `mix test` novamente.

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

E pronto, temos nossa suite de tests passando!

## Recapitulação

Nesta lição, demos nossos primeiros passos no testes com Elixir e Phoenix:

1. Descobrimos que Elixir vem com ExUnit, um test runner e biblioteca de assertions integrados
2. Executamos nossa primeira test suite usando `mix test` e encontramos um test com falha
3. Aprendemos a ler e interpretar mensagens de falha de testes no ExUnit
