-- =============================================================
-- Main: demonstração das três camadas
--
-- main é a única função com IO. Todo o texto impresso é montado
-- por funções puras (relatorio, relatorioErros), e main só decide
-- o que imprimir.
-- =============================================================
module Main (main) where

import Data.List (intercalate)
import System.IO (hSetEncoding, stdout, utf8)

import Classificacao
import Dados
import Leitura
import Tipos

-- | Rodada usada para mostrar a tabela no meio do campeonato.
rodadaIntermediaria :: Int
rodadaIntermediaria = 3

titulo :: String -> String
titulo t = "\n=== " ++ t ++ " ===\n"

descreverPartida :: Partida -> String
descreverPartida p =
  "Rodada " ++ show (rodada p) ++ ": " ++ mandante p ++ " "
    ++ show (golsMandante p) ++ " x " ++ show (golsVisitante p) ++ " " ++ visitante p

-- | Média com duas casas decimais, sem printf.
duasCasas :: Double -> String
duasCasas x = show inteiro ++ "." ++ centesimos
  where
    (inteiro, resto) = (round (x * 100) :: Int) `divMod` 100
    centesimos = (if resto < 10 then "0" else "") ++ show resto

-- | Camada 1: quem disputa o campeonato.
secaoTimes :: [Partida] -> String
secaoTimes partidas =
  titulo "Camada 1: times"
    ++ show (length (times partidas)) ++ " times, " ++ show (length partidas)
    ++ " partidas, " ++ show (length rodadas) ++ " rodadas\n"
    ++ intercalate ", " (times partidas) ++ "\n"
  where
    rodadas = foldr (\r rs -> if r `elem` rs then rs else r : rs) [] (map rodada partidas)

-- | Camada 2: tabelas e estatísticas.
secaoClassificacao :: [Partida] -> String
secaoClassificacao partidas =
  titulo "Classificação final"
    ++ tabelaFormatada (classificacao partidas)
    ++ titulo ("Classificação após a rodada " ++ show rodadaIntermediaria)
    ++ tabelaFormatada (classificacao (ateRodada rodadaIntermediaria partidas))
    ++ titulo "Estatísticas"
    ++ "Maior goleada:   " ++ maybe "nenhuma partida" descreverPartida (maiorGoleada partidas) ++ "\n"
    ++ "Média de gols:   " ++ maybe "nenhuma partida" duasCasas (mediaGols partidas) ++ "\n"

-- | Relatório completo de um campeonato lido com sucesso.
relatorio :: [Partida] -> String
relatorio partidas = secaoTimes partidas ++ secaoClassificacao partidas

-- | Camada 3: o que acontece com uma entrada cheia de erros.
relatorioErros :: String -> String
relatorioErros texto =
  titulo "Camada 3: entrada com erros"
    ++ "lerCampeonato para no primeiro erro:\n  "
    ++ either mensagemErro (const "nenhum erro") (lerCampeonato texto) ++ "\n"
    ++ "todosOsErros lista todos:\n"
    ++ concatMap (\e -> "  - " ++ mensagemErro e ++ "\n") (todosOsErros texto)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStr (either (("Erro ao ler o campeonato: " ++) . (++ "\n") . mensagemErro)
                 relatorio
                 (lerCampeonato dadosCampeonato))
  putStr (relatorioErros dadosComErros)
