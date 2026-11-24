-- =============================================================
-- Testes com resultado esperado
--
-- Compilar a partir da raiz do projeto:
--   ghc -Wall -isrc -outputdir build/testes -o build/testes/testes tests/Testes.hs
--
-- Use um -outputdir diferente do usado para src/Main.hs: os dois
-- arquivos são "module Main" e um sobrescreveria o Main.o do outro.
-- =============================================================
module Main (main) where

import Data.List (isPrefixOf, nub, sort)
import System.IO (hSetEncoding, stdout, utf8)

import Classificacao
import Dados
import Leitura
import Tipos

testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise          = putStrLn ("FALHOU  " ++ nome ++ ": " ++ show obtido)

-- -------------------------------------------------------------
-- Camada 1: Tipos e Dados do Campeonato
-- -------------------------------------------------------------

vitoriaMandante, vitoriaVisitante, empateSemGols :: Partida
vitoriaMandante  = Partida 1 "Coritiba" 2 1 "Athletico"
vitoriaVisitante = Partida 1 "Coritiba" 0 3 "Athletico"
empateSemGols    = Partida 1 "Coritiba" 0 0 "Athletico"

semRepeticao :: Eq a => [a] -> Bool
semRepeticao xs = length xs == length (nub xs)

rodadasDoTeste :: [Int]
rodadasDoTeste = nub (map rodada campeonatoTeste)

timesDaRodada :: Int -> [Time]
timesDaRodada r =
  concatMap (\p -> [mandante p, visitante p])
            (filter ((== r) . rodada) campeonatoTeste)

testesTipos :: IO ()
testesTipos = do
  -- resultadoPara
  testar "resultadoPara: mandante que venceu"
    (resultadoPara "Coritiba" vitoriaMandante)  (Just Vitoria)
  testar "resultadoPara: visitante que perdeu"
    (resultadoPara "Athletico" vitoriaMandante) (Just Derrota)
  testar "resultadoPara: time que não jogou dá Nothing"
    (resultadoPara "Paraná" vitoriaMandante)    Nothing

  testar "resultadoPara: visitante que venceu"
    (resultadoPara "Athletico" vitoriaVisitante) (Just Vitoria)
  testar "resultadoPara: mandante que perdeu"
    (resultadoPara "Coritiba" vitoriaVisitante)  (Just Derrota)
  testar "resultadoPara: empate para o mandante"
    (resultadoPara "Coritiba" empateSemGols)     (Just Empate)
  testar "resultadoPara: empate para o visitante"
    (resultadoPara "Athletico" empateSemGols)    (Just Empate)

  -- participou
  testar "participou: mandante"       (participou "Coritiba"  vitoriaMandante) True
  testar "participou: visitante"      (participou "Athletico" vitoriaMandante) True
  testar "participou: time que não jogou" (participou "Paraná" vitoriaMandante) False

  -- times
  testar "times: campeonato de teste"
    (times campeonatoTeste)
    [ "Athletico", "Cascavel", "Cianorte", "Coritiba"
    , "Londrina", "Maringá", "Operário", "Paraná" ]
  testar "times: sem repetição"       (semRepeticao (times campeonatoTeste)) True
  testar "times: em ordem alfabética" (times campeonatoTeste == sort (times campeonatoTeste)) True
  testar "times: campeonato vazio"    (times []) []

-- requisitos do campeonato de teste
testesCampeonatoTeste :: IO ()
testesCampeonatoTeste = do
  testar "campeonato: pelo menos 6 times"
    (length (times campeonatoTeste) >= 6) True
  testar "campeonato: pelo menos 5 rodadas"
    (length rodadasDoTeste >= 5) True
  testar "campeonato: nenhum time joga duas vezes na mesma rodada"
    (all (semRepeticao . timesDaRodada) rodadasDoTeste) True
  testar "campeonato: tem empate em 0 x 0"
    (any (\p -> golsMandante p == 0 && golsVisitante p == 0) campeonatoTeste) True
  testar "campeonato: tem vitória por 3 ou mais gols"
    (any (\p -> abs (golsMandante p - golsVisitante p) >= 3) campeonatoTeste) True
  testar "campeonato: tem times empatados em pontos no final"
    (semRepeticao (map pontosLinha (classificacao campeonatoTeste))) False

-- -------------------------------------------------------------
-- Camada 2: Classificação com Funções de Ordem Superior
-- -------------------------------------------------------------

-- | Tabela final do campeonato de teste, conferida à mão
-- (campos: time, jogos, vitórias, empates, derrotas, GP, GC).
classificacaoFinalEsperada :: [Linha]
classificacaoFinalEsperada =
  [ Linha "Coritiba"  7 5 2 0 11  2   -- 17 pts, SG +9
  , Linha "Athletico" 7 3 3 1  9  5   -- 12 pts, 3 V, SG +4
  , Linha "Cianorte"  7 3 3 1 10  7   -- 12 pts, 3 V, SG +3
  , Linha "Operário"  7 3 2 2  8  7   -- 11 pts
  , Linha "Paraná"    7 2 3 2  8  8   --  9 pts
  , Linha "Maringá"   7 1 3 3  7 10   --  6 pts
  , Linha "Londrina"  7 1 2 4  5 12   --  5 pts
  , Linha "Cascavel"  7 0 2 5  4 11   --  2 pts
  ]

-- | Tabela após a rodada 3, conferida à mão.
classificacaoRodada3Esperada :: [Linha]
classificacaoRodada3Esperada =
  [ Linha "Coritiba"  3 2 1 0 4 0   -- 7 pts, 2 V, SG +4
  , Linha "Cianorte"  3 2 1 0 5 2   -- 7 pts, 2 V, SG +3
  , Linha "Athletico" 3 1 2 0 3 1   -- 5 pts
  , Linha "Paraná"    3 1 1 1 5 4   -- 4 pts, 1 V, SG +1
  , Linha "Operário"  3 1 1 1 4 4   -- 4 pts, 1 V, SG  0
  , Linha "Londrina"  3 0 2 1 2 5   -- 2 pts
  , Linha "Cascavel"  3 0 1 2 2 5   -- 1 pt,  SG -3
  , Linha "Maringá"   3 0 1 2 2 6   -- 1 pt,  SG -4
  ]

-- | A e B terminam com 3 pontos. A tem 1 vitória e saldo -2;
-- B tem 0 vitórias e saldo 0. Se o saldo viesse antes, B ficaria
-- à frente: A só passa porque vitórias é o 2º critério.
desempateVitorias :: [Partida]
desempateVitorias =
  [ Partida 1 "A" 1 0 "X"
  , Partida 1 "B" 0 0 "Y"
  , Partida 2 "Y" 3 0 "A"
  , Partida 2 "B" 0 0 "X"
  , Partida 3 "B" 0 0 "Z"
  ]

-- | A e B: 1 ponto, 0 vitórias, saldo 0; A fez 2 gols e B nenhum,
-- então gols pró decide. A e X empatam em tudo, inclusive gols pró,
-- e a ordem alfabética do nome desempata.
desempateGolsPro :: [Partida]
desempateGolsPro =
  [ Partida 1 "X" 2 2 "A"
  , Partida 1 "B" 0 0 "Y"
  ]

testesClassificacao :: IO ()
testesClassificacao = do
  let coritiba  = linhaDoTime campeonatoTeste "Coritiba"
      athletico = linhaDoTime campeonatoTeste "Athletico"
      cianorte  = linhaDoTime campeonatoTeste "Cianorte"
      semJogos  = linhaDoTime campeonatoTeste "Flamengo"

  -- pontos, linhaDoTime, pontosLinha, saldo, aproveitamento
  testar "pontos: vitória, empate, derrota"
    (map pontos [Vitoria, Empate, Derrota]) [3, 1, 0]
  testar "linhaDoTime: Coritiba"
    coritiba (Linha "Coritiba" 7 5 2 0 11 2)
  testar "linhaDoTime: time que não jogou tem linha zerada"
    semJogos (Linha "Flamengo" 0 0 0 0 0 0)
  testar "linhaDoTime: campeonato vazio"
    (linhaDoTime [] "Coritiba") (Linha "Coritiba" 0 0 0 0 0 0)
  testar "pontosLinha: Coritiba"         (pontosLinha coritiba) 17
  testar "saldo: Coritiba"               (saldo coritiba) 9
  testar "saldo: negativo (Cascavel)"
    (saldo (linhaDoTime campeonatoTeste "Cascavel")) (-7)
  testar "aproveitamento: Coritiba (17 de 21 pontos = 81,0%)"
    (round (aproveitamento coritiba * 10) :: Int) 810
  testar "aproveitamento: 100% com só vitórias"
    (aproveitamento (linhaDoTime [Partida 1 "A" 1 0 "B"] "A")) 100
  testar "aproveitamento: time que não jogou dá 0 (sem divisão por zero)"
    (aproveitamento semJogos) 0

  -- classificacao
  testar "classificacao: tabela final conferida à mão"
    (classificacao campeonatoTeste) classificacaoFinalEsperada
  testar "classificacao: campeonato vazio"
    (classificacao []) []

  -- desempate no campeonato de teste: Athletico x Cianorte
  testar "desempate: Athletico e Cianorte com 12 pontos"
    (pontosLinha athletico, pontosLinha cianorte) (12, 12)
  testar "desempate: Athletico e Cianorte com 3 vitórias"
    (vitorias athletico, vitorias cianorte) (3, 3)
  testar "desempate: saldo diferente (+4 x +3)"
    (saldo athletico, saldo cianorte) (4, 3)
  testar "desempate: o SALDO decide, Athletico 2º e Cianorte 3º"
    (map time (take 2 (drop 1 (classificacao campeonatoTeste))))
    ["Athletico", "Cianorte"]

  -- desempates isolados, um critério por vez
  testar "desempate: VITÓRIAS vêm antes do saldo (A à frente de B)"
    (map time (classificacao desempateVitorias)) ["Y", "A", "B", "Z", "X"]
  testar "desempate: B tem saldo melhor que A, mas fica atrás"
    (map saldo (filter ((`elem` ["A", "B"]) . time) (classificacao desempateVitorias)))
    [-2, 0]
  testar "desempate: GOLS PRÓ e depois ordem alfabética"
    (map time (classificacao desempateGolsPro)) ["A", "X", "B", "Y"]

  -- ateRodada
  testar "ateRodada 3: 12 partidas"
    (length (ateRodada 3 campeonatoTeste)) 12
  testar "ateRodada 3: nenhuma partida depois da rodada 3"
    (all ((<= 3) . rodada) (ateRodada 3 campeonatoTeste)) True
  testar "ateRodada 0: nenhuma partida"
    (ateRodada 0 campeonatoTeste) []
  testar "ateRodada 7: o campeonato inteiro"
    (ateRodada 7 campeonatoTeste) campeonatoTeste
  testar "classificacao (ateRodada 3): conferida à mão"
    (classificacao (ateRodada 3 campeonatoTeste)) classificacaoRodada3Esperada
  testar "classificacao (ateRodada 3): diferente da final"
    (classificacao (ateRodada 3 campeonatoTeste) /= classificacao campeonatoTeste) True
  testar "classificacao (ateRodada 3): Cianorte 2º (no final é 3º)"
    (map time (take 3 (classificacao (ateRodada 3 campeonatoTeste))))
    ["Coritiba", "Cianorte", "Athletico"]

  -- estatísticas
  testar "maiorGoleada []: Nothing"  (maiorGoleada []) Nothing
  testar "mediaGols []: Nothing"     (mediaGols [])    Nothing
  testar "maiorGoleada: diferença de 3 gols"
    (fmap diferencaGols (maiorGoleada campeonatoTeste)) (Just 3)
  testar "maiorGoleada: é uma das duas goleadas por 3 gols"
    (maybe False (`elem` [ Partida 1 "Paraná"  3 0 "Londrina"
                         , Partida 3 "Maringá" 0 3 "Coritiba" ])
                 (maiorGoleada campeonatoTeste))
    True
  testar "maiorGoleada: uma partida só"
    (maiorGoleada [vitoriaMandante]) (Just vitoriaMandante)
  testar "mediaGols: 62 gols em 28 partidas"
    (mediaGols campeonatoTeste) (Just (62 / 28))
  testar "mediaGols: 3 gols em 2 partidas = 1.5"
    (mediaGols [vitoriaMandante, empateSemGols]) (Just 1.5)

-- -------------------------------------------------------------
-- Camada 3: Leitura, Validação e Saída
-- -------------------------------------------------------------

-- | Texto com 7 linhas inválidas (uma por construtor de Erro) e
-- duas válidas que escalam o Coritiba duas vezes na rodada 1.
-- Os números de linha contam o comentário da linha 1.
errosEsperados :: [Erro]
errosEsperados =
  [ NumeroInvalido 3 "dois"
  , CamposInvalidos 4 4
  , PlacarNegativo 5 (-1)
  , MesmoTime 6 "Operário"
  , RodadaInvalida 7 0
  , TimeVazio 8
  , TimeRepetidoNaRodada 1 "Coritiba" [2, 9]
  ]

testesSeparar :: IO ()
testesSeparar = do
  testar "separar: campos simples"      (separar ';' "1;A;2;0;B") ["1", "A", "2", "0", "B"]
  testar "separar: campo vazio no meio" (separar ';' "a;;b")      ["a", "", "b"]
  testar "separar: separador no fim"    (separar ';' "a;")        ["a", ""]
  testar "separar: texto vazio"         (separar ';' "")          [""]
  testar "separar: sem separador"       (separar ';' "abc")       ["abc"]
  testar "aparar: espaços e \\r"         (aparar "  Coritiba \r")   "Coritiba"
  testar "linhasUteis: ignora # e branco, mantém numeração"
    (linhasUteis "# cabeçalho\n\n1;A;1;0;B\n   \n# fim\n2;B;0;0;A\n")
    [(3, "1;A;1;0;B"), (6, "2;B;0;0;A")]

testesLerPartida :: IO ()
testesLerPartida = do
  testar "lerPartida: linha válida"
    (lerPartida 1 "1;Coritiba;2;1;Athletico")
    (Right (Partida 1 "Coritiba" 2 1 "Athletico"))
  testar "lerPartida: espaços em volta dos campos"
    (lerPartida 1 " 1 ; Coritiba ; 2 ; 1 ; Athletico \r")
    (Right (Partida 1 "Coritiba" 2 1 "Athletico"))

  -- um teste para cada construtor de Erro
  testar "Erro CamposInvalidos: faltando campo"
    (lerPartida 4 "1;Coritiba;2;1")             (Left (CamposInvalidos 4 4))
  testar "Erro CamposInvalidos: campo a mais"
    (lerPartida 4 "1;Coritiba;2;1;Athletico;x") (Left (CamposInvalidos 4 6))
  testar "Erro CamposInvalidos: separador errado (vírgula)"
    (lerPartida 4 "1,Coritiba,2,1,Athletico")   (Left (CamposInvalidos 4 1))
  testar "Erro NumeroInvalido: placar \"dois\""
    (lerPartida 3 "1;Coritiba;dois;1;Athletico") (Left (NumeroInvalido 3 "dois"))
  testar "Erro NumeroInvalido: placar \"2a\""
    (lerPartida 3 "1;Coritiba;2a;1;Athletico")   (Left (NumeroInvalido 3 "2a"))
  testar "Erro NumeroInvalido: placar vazio"
    (lerPartida 3 "1;Coritiba;;1;Athletico")     (Left (NumeroInvalido 3 ""))
  testar "Erro NumeroInvalido: rodada \"um\""
    (lerPartida 3 "um;Coritiba;2;1;Athletico")   (Left (NumeroInvalido 3 "um"))
  testar "Erro PlacarNegativo"
    (lerPartida 5 "1;Coritiba;2;-3;Athletico")   (Left (PlacarNegativo 5 (-3)))
  testar "Erro RodadaInvalida"
    (lerPartida 7 "0;Coritiba;2;1;Athletico")    (Left (RodadaInvalida 7 0))
  testar "Erro TimeVazio"
    (lerPartida 8 "1;Coritiba;2;1;   ")          (Left (TimeVazio 8))
  testar "Erro MesmoTime"
    (lerPartida 6 "1;Coritiba;1;1;Coritiba")     (Left (MesmoTime 6 "Coritiba"))
  testar "Erro TimeRepetidoNaRodada"
    (lerCampeonato "1;Coritiba;1;0;Athletico\n1;Paraná;2;2;Coritiba\n")
    (Left (TimeRepetidoNaRodada 1 "Coritiba" [1, 2]))

  testar "lerPartida: primeiro erro interrompe o do"
    (lerPartida 2 "x;Coritiba;dois;-1;Coritiba") (Left (NumeroInvalido 2 "x"))

testesLerCampeonato :: IO ()
testesLerCampeonato = do
  testar "lerCampeonato: entrada válida devolve Right"
    (lerCampeonato dadosCampeonato) (Right campeonatoTeste)
  testar "lerCampeonato: texto vazio é um campeonato vazio"
    (lerCampeonato "") (Right [])
  testar "lerCampeonato: só comentários é um campeonato vazio"
    (lerCampeonato "# nada\n\n# ainda nada\n") (Right [])
  testar "lerCampeonato: aceita quebras de linha do Windows"
    (lerCampeonato "1;A;1;0;B\r\n2;B;0;0;A\r\n")
    (Right [Partida 1 "A" 1 0 "B", Partida 2 "B" 0 0 "A"])
  testar "lerCampeonato: mesmo time em rodadas diferentes é válido"
    (lerCampeonato "1;A;1;0;B\n2;A;0;0;B\n")
    (Right [Partida 1 "A" 1 0 "B", Partida 2 "A" 0 0 "B"])
  testar "lerCampeonato: para no primeiro erro"
    (lerCampeonato dadosComErros) (Left (NumeroInvalido 3 "dois"))

testesTodosOsErros :: IO ()
testesTodosOsErros = do
  testar "todosOsErros: 7 erros, todos listados"
    (todosOsErros dadosComErros) errosEsperados
  testar "todosOsErros: entrada válida não tem erros"
    (todosOsErros dadosCampeonato) []
  testar "todosOsErros: texto vazio não tem erros"
    (todosOsErros "") []
  testar "todosOsErros: time repetido três vezes na mesma rodada"
    (todosOsErros "1;A;1;0;B\n1;A;0;0;C\n1;D;2;2;A\n")
    [TimeRepetidoNaRodada 1 "A" [1, 2, 3]]
  testar "todosOsErros vazio <=> lerCampeonato devolve Right"
    (map (null . todosOsErros) [dadosCampeonato, dadosComErros, ""])
    (map (either (const False) (const True) . lerCampeonato)
         [dadosCampeonato, dadosComErros, ""])

testesSaida :: IO ()
testesSaida = do
  testar "mensagemErro: indica a linha"
    (mensagemErro (NumeroInvalido 3 "dois"))
    "Linha 3: \"dois\" não é um número inteiro válido"
  testar "mensagemErro: indica rodada e linhas da repetição"
    (mensagemErro (TimeRepetidoNaRodada 1 "Coritiba" [2, 9]))
    "Rodada 1: Coritiba joga mais de uma vez (linhas 2, 9)"
  testar "tabelaFormatada: tabela vazia"
    (tabelaFormatada []) "(tabela vazia: nenhuma partida registrada)\n"

  let tabela = lines (tabelaFormatada (classificacao campeonatoTeste))
  testar "tabelaFormatada: cabeçalho + régua + 8 times"
    (length tabela) 10
  testar "tabelaFormatada: cabeçalho"
    (take 1 tabela) [" Pos  Time         P    J    V    E    D   GP   GC   SG       %"]
  testar "tabelaFormatada: líder na primeira linha"
    (take 1 (drop 2 tabela))
    ["  1.  Coritiba    17    7    5    2    0   11    2   +9    81.0"]
  testar "tabelaFormatada: saldo negativo e zero"
    (map (take 14) (drop 6 tabela))
    ["  5.  Paraná  ", "  6.  Maringá ", "  7.  Londrina", "  8.  Cascavel"]
  testar "tabelaFormatada: todas as linhas com a mesma largura"
    (all ((== length (concat (take 1 tabela))) . length) tabela) True
  testar "tabelaFormatada: posições em ordem"
    (map (takeWhile (/= '.') . dropWhile (== ' ')) (drop 2 tabela))
    (map show [1 .. 8 :: Int])
  testar "tabelaFormatada: nenhum time fora da tabela"
    (all (\t -> any ((t `isPrefixOf`) . drop 6) tabela) (times campeonatoTeste)) True

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "--- Camada 1: tipos e consultas básicas ---"
  testesTipos
  putStrLn "\n--- Camada 1: campeonato de teste ---"
  testesCampeonatoTeste
  putStrLn "\n--- Camada 2: classificação e estatísticas ---"
  testesClassificacao
  putStrLn "\n--- Camada 3: separar, aparar, linhasUteis ---"
  testesSeparar
  putStrLn "\n--- Camada 3: lerPartida (um teste por construtor de Erro) ---"
  testesLerPartida
  putStrLn "\n--- Camada 3: lerCampeonato ---"
  testesLerCampeonato
  putStrLn "\n--- Camada 3: todosOsErros ---"
  testesTodosOsErros
  putStrLn "\n--- Camada 3: saída ---"
  testesSaida
