module Camada1 where

import Data.List (nub, sort)

type Time = String

data Resultado = Vitoria | Empate | Derrota
  deriving (Show, Eq)

data Partida = Partida
  { rodada        :: Int
  , mandante      :: Time
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time
  } deriving (Show, Eq)

data Linha = Linha
  { time       :: Time
  , jogos      :: Int
  , vitorias   :: Int
  , empates    :: Int
  , derrotas   :: Int
  , golsPro    :: Int
  , golsContra :: Int
  } deriving (Show, Eq)

participou :: Time -> Partida -> Bool
participou t (Partida _ mand _ _ vis) = t == mand || t == vis

resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t (Partida _ mand gm gv vis)
  | t == mand = Just $ case compare gm gv of
      GT -> Vitoria
      EQ -> Empate
      LT -> Derrota
  | t == vis = Just $ case compare gv gm of
      GT -> Vitoria
      EQ -> Empate
      LT -> Derrota
  | otherwise = Nothing

times :: [Partida] -> [Time]
times partidas = sort . nub $ [t | p <- partidas, t <- [mandante p, visitante p]]
campeonatoTeste :: [Partida]
campeonatoTeste =
  [ -- Rodada 1
    Partida 1 "Coritiba"   0 0 "Athletico"
  , Partida 1 "Paraná"     3 0 "Londrina"   
  , Partida 1 "Maringá"    1 2 "Operário"
  , Partida 1 "Cianorte"   2 1 "Cascavel"

  -- Rodada 2
  , Partida 2 "Athletico"  2 0 "Paraná"
  , Partida 2 "Londrina"   1 1 "Maringá"
  , Partida 2 "Operário"   0 1 "Coritiba"
  , Partida 2 "Cascavel"   1 3 "Cianorte"

  -- Rodada 3
  , Partida 3 "Paraná"     2 2 "Operário"
  , Partida 3 "Maringá"    0 3 "Coritiba"
  , Partida 3 "Athletico"  1 1 "Londrina"
  , Partida 3 "Cianorte"   0 0 "Cascavel"

  -- Rodada 4
  , Partida 4 "Londrina"   0 2 "Coritiba"
  , Partida 4 "Operário"   1 0 "Athletico"
  , Partida 4 "Paraná"     1 1 "Maringá"
  , Partida 4 "Cascavel"   2 2 "Cianorte"

  -- Rodada 5
  , Partida 5 "Coritiba"   1 1 "Paraná"
  , Partida 5 "Athletico"  2 1 "Maringá"
  , Partida 5 "Londrina"   0 1 "Operário"
  , Partida 5 "Cianorte"   1 0 "Cascavel"

  -- Rodada 6
  , Partida 6 "Maringá"    2 0 "Cascavel"
  , Partida 6 "Operário"   1 1 "Cianorte"
  , Partida 6 "Paraná"     0 2 "Coritiba"
  , Partida 6 "Athletico"  3 1 "Londrina"

  -- Rodada 7
  , Partida 7 "Cascavel"   0 1 "Paraná"
  , Partida 7 "Londrina"   2 1 "Cianorte"
  , Partida 7 "Maringá"    1 1 "Athletico"
  , Partida 7 "Coritiba"   2 1 "Operário"
  ]
      
      
      
      
      
