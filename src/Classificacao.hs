module Camada2 where

import Camada1
import Data.List (sortBy)
import Data.Ord (comparing, Down (..))

--Pontos de cada resultado
pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

--Pontos acumulados de um time
pontosLinha :: Linha -> Int
pontosLinha l = 3 * vitorias l + empates l

--Saldo gols
saldo :: Linha -> Int
saldo l = golsPro l - golsContra l

--Aproveitamento em porcentagem
aproveitamento :: Linha -> Double
aproveitamento l
  | jogos l == 0 = 0
  | otherwise =
      fromIntegral (pontosLinha l) /
      fromIntegral (3 * jogos l) * 100

--Calcula a linha completa de um time
linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime partidas t =
  (foldl atualizar inicial . filter (participou t)) partidas
  where
    inicial = Linha t 0 0 0 0 0 0

    atualizar l p =
      case resultadoPara t p of
        Nothing -> l
        Just resultado ->
          let (gp, gc) =
                if mandante p == t
                  then (golsMandante p, golsVisitante p)
                  else (golsVisitante p, golsMandante p)

              v = if resultado == Vitoria then 1 else 0
              e = if resultado == Empate  then 1 else 0
              d = if resultado == Derrota then 1 else 0

          in l
            { jogos      = jogos l + 1
            , vitorias   = vitorias l + v
            , empates    = empates l + e
            , derrotas   = derrotas l + d
            , golsPro    = golsPro l + gp
            , golsContra = golsContra l + gc
            }

--Tabela ordenada
classificacao :: [Partida] -> [Linha]
classificacao partidas =
  sortBy criterios (map (linhaDoTime partidas) (times partidas))
  where
    criterios =
         comparing (Down . pontosLinha)
      <> comparing (Down . vitorias)
      <> comparing (Down . saldo)
      <> comparing (Down . golsPro)
      <> comparing time
