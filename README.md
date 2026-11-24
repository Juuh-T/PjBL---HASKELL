# PjBL2: Tabela de Classificação de Campeonato em Haskell

Calcula a tabela de classificação de um campeonato de futebol a partir dos
resultados das partidas, lidos de um texto no formato
`rodada;mandante;gols mandante;gols visitante;visitante`, com validação da
entrada pelas mônadas `Maybe` e `Either`.

## Integrantes

- Ana Luisa Juliatto
- Caio Kloppel
- Eduardo Dellarosa Locatelli
- Julia Tartari Cavalcante

## Ambiente

O projeto foi desenvolvido e testado com o **GHC local, instalado via GHCup**.
Ele usa só a biblioteca `base` (`Data.List`, `Data.Char`, `Data.Maybe`,
`Data.Either`, `Data.Ord`, `Text.Read` e `System.IO`), então não precisa de
cabal nem de stack.

## Estrutura

```
.
├── src/
│   ├── Tipos.hs           Camada 1: tipos (Time, Resultado, Partida, Linha),
│   │                      consultas básicas e o campeonato de teste
│   ├── Classificacao.hs   Camada 2: pontos, linha de cada time, tabela
│   │                      ordenada e estatísticas (só ordem superior)
│   ├── Leitura.hs         Camada 3: tipo Erro, leitura e validação do texto,
│   │                      relatório de erros e tabela formatada
│   ├── Dados.hs           o campeonato como String (válido e com erros)
│   └── Main.hs            demonstração das três camadas
├── tests/
│   └── Testes.hs          testes com resultado esperado
├── docs/
│   └── decisoes.md        decisões de modelagem e limitações conhecidas
└── README.md
```

## Como compilar e executar

Todos os comandos são executados na raiz do projeto.

### Programa principal

```bash
ghc -Wall -isrc -outputdir build/main -o build/main/pjbl src/Main.hs
./build/main/pjbl
```

No Windows, o executável é `build\main\pjbl.exe`.

Para rodar sem gerar executável:

```bash
runghc -isrc src/Main.hs
```

O `main` mostra, em sequência:

1. os times, o número de partidas e o número de rodadas (Camada 1);
2. a classificação final, a classificação após a rodada 3 e as estatísticas,
   com a maior goleada e a média de gols (Camada 2);
3. o tratamento de uma entrada com erros: o primeiro erro, devolvido por
   `lerCampeonato`, e a lista completa, devolvida por `todosOsErros`
   (Camada 3).

### Testes

```bash
ghc -Wall -isrc -outputdir build/testes -o build/testes/testes tests/Testes.hs
./build/testes/testes
```

Ou, sem gerar executável:

```bash
runghc -isrc tests/Testes.hs
```

Cada teste imprime `OK` ou `FALHOU`, seguido do valor obtido. Os testes
cobrem as três camadas:

- **Camada 1:** `resultadoPara` (mandante, visitante e time que não jogou),
  `participou`, `times` e os requisitos mínimos do campeonato de teste.
- **Camada 2:** `pontos`, `linhaDoTime`, `saldo`, `aproveitamento`, a
  classificação final e a da rodada 3 conferidas à mão, um teste para cada
  critério de desempate, `ateRodada`, `maiorGoleada` e `mediaGols`
  (inclusive com lista vazia).
- **Camada 3:** `separar`, um teste para cada construtor de `Erro`,
  `lerCampeonato` (entrada válida, texto vazio, quebras de linha do Windows),
  `todosOsErros` com 7 linhas inválidas e `tabelaFormatada`.

> **Atenção:** use pastas de saída diferentes (`build/main` e
> `build/testes`), como nos comandos acima. `src/Main.hs` e
> `tests/Testes.hs` são os dois `module Main`, e com a mesma pasta o
> `Main.o` de um sobrescreve o do outro.

## Formato da entrada

```
# rodada;mandante;gols mandante;gols visitante;visitante
1;Coritiba;2;2;Athletico
1;Paraná;0;0;Operário
```

Linhas em branco e linhas que começam com `#` são ignoradas. Espaços em volta
dos campos e o `\r` de arquivos do Windows são removidos. Os dados ficam em
`src/Dados.hs` (`dadosCampeonato`) para que o programa também funcione onde
não há entrada pelo teclado.

## Critérios de classificação

1. pontos (vitória 3, empate 1, derrota 0)
2. número de vitórias
3. saldo de gols
4. gols pró
5. ordem alfabética do nome (só para a tabela sair sempre na mesma ordem)

As decisões de modelagem e as limitações conhecidas estão em
[`docs/decisoes.md`](docs/decisoes.md).
