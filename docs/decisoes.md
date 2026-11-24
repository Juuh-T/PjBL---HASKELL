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

<!-- responsável pela Camada 2 completa aqui (ex.: foldl ou foldr, critérios de desempate) -->

## Camada 3: Leitura, Validação e Saída

<!-- responsável pela Camada 3 completa aqui -->
