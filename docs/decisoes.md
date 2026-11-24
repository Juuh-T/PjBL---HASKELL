# Decisões de modelagem e limitações conhecidas

## Camada 1: Tipos e Dados do Campeonato

### Decisões

- **`Partida` e `Linha` são records, não tuplas.** Numa tupla
  `(Int, String, Int, Int, String)`, trocar os gols do mandante com os do
  visitante compila sem aviso. Com campos nomeados (`golsMandante`,
  `golsVisitante`), cada valor é lido pelo nome, e o record ainda gera as
  funções de acesso usadas nas outras camadas.
- **`Resultado` é um tipo soma (`Vitoria | Empate | Derrota`), não `String`
  nem `Int`.** O conjunto de valores é fechado: um `"v"` minúsculo não
  compila, e com `-Wall` o compilador avisa se algum caso ficar sem
  tratamento (por exemplo, em `pontos`, na Camada 2).
- **`Linha` guarda só contagens** (jogos, vitórias, empates, derrotas, gols
  pró e gols contra). Pontos, saldo e aproveitamento não são armazenados: são
  calculados a partir das contagens na Camada 2 (`pontosLinha`, `saldo`,
  `aproveitamento`). Assim, não existe uma `Linha` com pontos que não batem
  com as vitórias e os empates.
- **`resultadoPara` devolve `Maybe Resultado`.** Um time que não jogou a
  partida não tem resultado, e o `Nothing` obriga quem chama a tratar esse
  caso. O resultado vem de `compare` sobre os gols, invertendo a ordem dos
  argumentos para o visitante, e o `case` cobre `GT`, `EQ` e `LT`.
- **`times` usa `sort . nub`.** `nub` remove as repetições e `sort` coloca em
  ordem alfabética, como pede o enunciado. `nub` é quadrático, o que não pesa
  num campeonato com poucos times.
- **`Tipos.hs` exporta tudo** (`module Tipos where`), porque as três camadas
  usam todos os tipos, campos e consultas.
- **O campeonato de teste existe em dois formatos:** `campeonatoTeste`
  (`[Partida]`, em `Tipos.hs`) e `dadosCampeonato` (`String`, em `Dados.hs`).
  A lista permite testar as Camadas 1 e 2 sem depender da leitura, e o texto
  é a entrada da Camada 3. Um teste
  (`lerCampeonato dadosCampeonato == Right campeonatoTeste`) garante que os
  dois descrevem as mesmas partidas.

### Campeonato de teste

8 times, 7 rodadas e 4 jogos por rodada, sem nenhum time jogando duas vezes
na mesma rodada. Ele cobre os casos exigidos:

| Requisito                    | Onde aparece                                                        |
|------------------------------|---------------------------------------------------------------------|
| Empate em 0 x 0              | Coritiba 0 x 0 Athletico (R1), Cianorte 0 x 0 Cascavel (R3)         |
| Vitória por 3+ gols          | Paraná 3 x 0 Londrina (R1), Maringá 0 x 3 Coritiba (R3)             |
| Empate em pontos no final    | Athletico e Cianorte: 12 pontos e 3 vitórias; o saldo (+4 x +3) decide |
| Tabela intermediária diferente | após a rodada 3, Cianorte é 2º e Athletico 3º; no final, Athletico é 2º |

Os testes da Camada 1 (`tests/Testes.hs`) conferem esses requisitos
automaticamente, além de `resultadoPara`, `participou` e `times`.

### Limitações conhecidas

- **`Time = String` não impede erros de digitação:** `"coritiba"` e
  `"Coritiba"` viram dois times diferentes. Um tipo próprio (por exemplo, uma
  enumeração dos times) evitaria isso, mas prenderia o programa a um
  campeonato fixo.
- **Os tipos não impedem partidas inválidas:** `Partida` aceita gols
  negativos, rodada 0 ou um time jogando contra si mesmo. Essas regras são
  verificadas na leitura (Camada 3, construtores de `Erro`), e não no tipo.
- **O campeonato de teste não é um turno completo:** com 8 times e 7 rodadas
  daria para todos se enfrentarem uma vez, mas 5 confrontos se repetem
  (por exemplo, Coritiba x Operário) e outros não acontecem. Isso não afeta
  nenhum requisito, mas a tabela não representa um turno "justo".
- **O campeonato de teste está escrito duas vezes** (lista e texto). Se
  alguém alterar só um dos dois, o teste da Camada 3 acusa a diferença.

## Camada 2: Classificação com Funções de Ordem Superior

### Decisões

- **Nenhuma recursão explícita.** Toda a camada usa funções de ordem
  superior, cada uma escolhida pelo que faz com a lista:
  - `filter`: as partidas de um time (`filter (participou t)`) e as partidas
    até uma rodada (`filter ((<= n) . rodada)`);
  - `map`: uma linha por time (`map (linhaDoTime partidas)`) e os gols de cada
    partida em `mediaGols`;
  - `foldl`: acumular a linha de um time em `linhaDoTime`;
  - `(.)`: `foldl atualizar inicial . filter (participou t)`,
    `(<= n) . rodada` e `Down . pontosLinha`.
- **`linhaDoTime` usa `foldl`.** A linha é um acumulador que começa zerado
  (`Linha t 0 0 0 0 0 0`) e é atualizado partida a partida, da esquerda para
  a direita, na ordem em que as partidas aparecem. Como a soma não depende da
  ordem, `foldr` daria o mesmo resultado; `foldl` foi escolhido porque o
  acumulador é a linha e o elemento é a partida, exatamente nessa ordem dos
  argumentos (`atualizar :: Linha -> Partida -> Linha`). Antes da dobra, o
  `filter (participou t)` descarta as partidas de outros times.
- **`linhaDoTime` reaproveita `resultadoPara` da Camada 1.** O `case` sobre
  `Maybe Resultado` trata o `Nothing`, que não acontece depois do `filter`,
  sem precisar de um padrão incompleto.
- **Pontos, saldo e aproveitamento são calculados, não guardados.** Como a
  `Linha` só tem contagens, `pontosLinha` (3 por vitória, 1 por empate),
  `saldo` (gols pró menos gols contra) e `aproveitamento` são funções sobre
  ela, e a tabela nunca fica inconsistente.
- **`aproveitamento` usa `fromIntegral` e `/`.** Pontos e jogos são `Int`, e
  `div` truncaria o resultado (17 de 21 pontos daria 0). `fromIntegral`
  converte os dois para `Double` antes da divisão. Um time sem jogos tem
  aproveitamento 0, tratado por uma guarda antes da divisão, para não dividir
  por zero.
- **A ordenação é uma única função de comparação.** `classificacao` usa
  `sortBy` com os critérios combinados por `<>` (`Ordering` é um `Monoid`): o
  segundo critério só é consultado quando o primeiro dá `EQ`, e assim por
  diante. `Down` inverte a ordem dos critérios em que maior é melhor.
  Encadear vários `sortBy` não funcionaria, porque cada ordenação desfaria a
  anterior.
- **Critérios de desempate:** pontos, vitórias, saldo de gols e gols pró, os
  quatro primeiros critérios do Campeonato Brasileiro. O último critério, a
  ordem alfabética do nome, não é uma regra esportiva: ele só garante que a
  tabela sai sempre na mesma ordem quando dois times empatam em tudo.
- **`maiorGoleada` e `mediaGols` devolvem `Maybe`.** Um campeonato sem
  partidas não tem maior goleada nem média. Em vez de deixar `maximumBy` ou a
  divisão por zero falharem, a lista vazia é tratada num caso próprio que
  devolve `Nothing`. `maximumBy` só é chamado no segundo caso, quando a lista
  com certeza não está vazia, então a função é total.
- **`diferencaGols` e `totalGols` são funções auxiliares separadas**, para que
  `maiorGoleada` e `mediaGols` fiquem em uma linha e possam ser testadas
  isoladamente.

### Como os testes conferem os desempates

- No campeonato de teste, **Athletico e Cianorte** terminam com 12 pontos e 3
  vitórias, e o **saldo** decide (+4 contra +3). Após a rodada 3, Coritiba e
  Cianorte têm 7 pontos e 2 vitórias, e o saldo também decide (+4 contra +3).
- Como o campeonato de teste não tem empate que chegue a vitórias ou a gols
  pró, os testes usam dois campeonatos pequenos, um para cada critério:
  - `desempateVitorias`: A (1 vitória, saldo −2) fica à frente de B
    (0 vitórias, saldo 0). Se o saldo viesse antes das vitórias, B ficaria
    na frente.
  - `desempateGolsPro`: A, X, B e Y têm 1 ponto, 0 vitórias e saldo 0. A e X
    fizeram 2 gols, B e Y nenhum. Entre A e X, que empatam em tudo, decide o
    nome.

### Limitações conhecidas

- **Não há confronto direto, cartões nem sorteio**, que são os critérios
  seguintes do Brasileirão. O confronto direto exigiria olhar as partidas
  entre os times empatados, o que não cabe numa comparação entre duas `Linha`.
- **`linhaDoTime` percorre todas as partidas para cada time**, porque
  `classificacao` chama `linhaDoTime` uma vez por time. O custo é
  proporcional a times × partidas, o que não pesa num campeonato real (20
  times e 380 jogos). Uma única dobra que atualizasse todas as linhas de uma
  vez seria mais eficiente, porém mais difícil de ler.
- **`foldl` é preguiçoso** e acumula operações pendentes antes de calcular.
  Com poucas partidas por time isso não importa; para listas muito grandes,
  `foldl'` (de `Data.List`) seria a escolha.
- **Em `maiorGoleada`, um empate na diferença de gols é resolvido pela
  última partida da lista** (comportamento de `maximumBy`). No campeonato de
  teste há duas vitórias por 3 gols, e a função devolve uma delas sem um
  critério esportivo para a escolha. Por isso o teste aceita qualquer uma das
  duas.
- **`pontos` e `pontosLinha` repetem a regra 3/1/0.** `pontosLinha` multiplica
  as vitórias por 3 em vez de chamar `pontos Vitoria`; se a pontuação mudasse,
  seria preciso alterar os dois lugares.

## Camada 3: Leitura, Validação e Saída

### Decisões

- **Núcleo puro e IO só no `main`.** `Leitura.hs` não faz IO: recebe uma
  `String` e devolve `Either Erro [Partida]`, `[Erro]` ou a tabela como
  `String`. Em `Main.hs`, o texto impresso também é montado por funções puras
  (`relatorio`, `relatorioErros`), e o `main` só decide o que imprimir. Isso
  permite testar toda a leitura sem entrada pelo teclado.
- **Os dados ficam no código (`Dados.hs`)**, como `String` montada com
  `unlines`, em vez de vir de `getLine`. Assim o programa roda também onde não
  há entrada padrão.
- **`Erro` tem dois construtores além dos cinco exigidos:**
  - `RodadaInvalida`: rodada menor que 1, porque `ateRodada` e a tabela
    intermediária supõem rodadas a partir de 1;
  - `TimeVazio`: nome de time em branco, que de outra forma viraria um time
    chamado `""` na tabela.
- **Cada construtor carrega onde está o problema e o que estava errado**
  (`NumeroInvalido 3 "dois"`, `PlacarNegativo 5 (-1)`). `mensagemErro`
  converte o erro num texto para o usuário, separado do tipo, para que os
  testes comparem valores de `Erro` e não frases.
- **O número da linha é o do texto original**, contando comentários e linhas
  em branco. `linhasUteis` numera as linhas com `zip [1 ..]` antes de
  descartar as irrelevantes, e assim a mensagem aponta a linha que o usuário
  vê no arquivo.
- **`TimeRepetidoNaRodada` carrega a rodada, o time e todas as linhas** em que
  ele aparece, e não só uma. As escalações são ordenadas e agrupadas por
  (rodada, time) com `sortOn` e `groupBy`; só os grupos com dois ou mais
  elementos viram erro.
- **`separar` usa `foldr`** com um acumulador (campo atual, campos já
  fechados). É total, preserva campos vazios (`"a;;b"` dá três campos, e o
  campo vazio vira `NumeroInvalido` ou `TimeVazio`) e não precisa de `head`.
- **`lerPartida` é um bloco `do` na mônada `Either`.** Cada passo (cinco
  campos, rodada, mandante, placares, visitante, times diferentes) pode
  falhar, e o primeiro `Left` interrompe o resto, sem `case` aninhados.
  `garantir` transforma uma condição num passo que falha com o erro dado.
- **Conversões com `readMaybe`, nunca `read`.** `lerNumero` usa `maybe` para
  transformar o `Maybe Int` de `readMaybe` num `Either Erro Int` que carrega o
  número da linha. Esse é o uso de `Maybe` exigido, junto com o `<$>` de
  `lerNumerada` e o `listToMaybe` de `lerCampeonato`.
- **`lerCampeonato` usa `traverse`**, que aplica `lerNumerada` a todas as
  linhas e para no primeiro erro. Só se todas forem válidas é que verifica as
  repetições por rodada.
- **`todosOsErros` não para no primeiro erro:** usa `map` em vez de
  `traverse`, separa os erros (`lefts`) das partidas válidas (`rights`) e
  acrescenta as repetições encontradas entre as válidas. Um teste garante que
  `todosOsErros` é vazio exatamente quando `lerCampeonato` devolve `Right`.
- **Texto vazio ou só com comentários é um campeonato válido e vazio**
  (`Right []`), e não um erro. As Camadas 1 e 2 tratam a lista vazia
  (`times [] = []`, `maiorGoleada [] = Nothing`), e `tabelaFormatada []`
  imprime um aviso em vez de uma tabela sem linhas.
- **`tabelaFormatada` calcula a largura da coluna de times** pelo maior nome,
  com `foldr`, e alinha os números à direita. Além das colunas exigidas, mostra
  gols pró, gols contra e aproveitamento, este com uma casa decimal, sem
  `printf`.

### Limitações conhecidas

- **Repetições só são procuradas entre linhas válidas.** Se uma linha tem erro
  de placar e também escala um time repetido, só o erro de placar aparece em
  `todosOsErros`; a repetição surge depois que a linha for corrigida.
- **`lerCampeonato` devolve só a primeira repetição**, mesmo que haja várias.
  É o comportamento pedido ("parar no primeiro erro"); `todosOsErros` lista
  todas.
- **`readMaybe` aceita alguns formatos inesperados**, como `"(2)"`, que vira
  2, porque segue a sintaxe de Haskell. Já `"+2"` é rejeitado como
  `NumeroInvalido`.
- **Nomes de time diferenciam maiúsculas e acentos:** `"Parana"` e `"Paraná"`
  são times diferentes, e a leitura não tem como saber que é um erro de
  digitação. Também não é possível ter `;` no nome de um time.
- **Não há verificação de consistência entre rodadas**: um campeonato em que
  um time joga 5 vezes e outro 2 é aceito. O enunciado só pede que nenhum time
  jogue duas vezes na mesma rodada.
- **O alinhamento da tabela conta caracteres**, não a largura na tela. Nomes
  com acentos decompostos (letra + acento combinante) ou com emojis ficariam
  desalinhados.

