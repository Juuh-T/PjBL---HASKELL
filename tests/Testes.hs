-- =============================================================
-- Testes com resultado esperado
--
-- Compilar a partir da raiz do projeto:
--   ghc -Wall -isrc -outputdir build -o build/testes tests/Testes.hs
-- =============================================================
module Main (main) where

import Data.List (isPrefixOf)
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
  putStrLn "--- Camada 3: separar, aparar, linhasUteis ---"
  testesSeparar
  putStrLn "\n--- Camada 3: lerPartida (um teste por construtor de Erro) ---"
  testesLerPartida
  putStrLn "\n--- Camada 3: lerCampeonato ---"
  testesLerCampeonato
  putStrLn "\n--- Camada 3: todosOsErros ---"
  testesTodosOsErros
  putStrLn "\n--- Camada 3: saída ---"
  testesSaida
