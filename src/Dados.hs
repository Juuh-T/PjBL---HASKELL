-- =============================================================
-- Dados do campeonato, como String
--
-- O playground não tem entrada pelo teclado, então os dados ficam
-- no próprio código. dadosCampeonato descreve as mesmas partidas
-- de campeonatoTeste (Tipos.hs), o que permite testar a leitura
-- comparando as duas.
-- =============================================================
module Dados
  ( dadosCampeonato
  , dadosComErros
  ) where

-- | Campeonato válido: 8 times, 7 rodadas.
dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , ""
  , "# Rodada 1"
  , "1;Coritiba;0;0;Athletico"
  , "1;Paraná;3;0;Londrina"
  , "1;Maringá;1;2;Operário"
  , "1;Cianorte;2;1;Cascavel"
  , ""
  , "# Rodada 2"
  , "2;Athletico;2;0;Paraná"
  , "2;Londrina;1;1;Maringá"
  , "2;Operário;0;1;Coritiba"
  , "2;Cascavel;1;3;Cianorte"
  , ""
  , "# Rodada 3"
  , "3;Paraná;2;2;Operário"
  , "3;Maringá;0;3;Coritiba"
  , "3;Athletico;1;1;Londrina"
  , "3;Cianorte;0;0;Cascavel"
  , ""
  , "# Rodada 4"
  , "4;Londrina;0;2;Coritiba"
  , "4;Operário;1;0;Athletico"
  , "4;Paraná;1;1;Maringá"
  , "4;Cascavel;2;2;Cianorte"
  , ""
  , "# Rodada 5"
  , "5;Coritiba;1;1;Paraná"
  , "5;Athletico;2;1;Maringá"
  , "5;Londrina;0;1;Operário"
  , "5;Cianorte;1;0;Cascavel"
  , ""
  , "# Rodada 6"
  , "6;Maringá;2;0;Cascavel"
  , "6;Operário;1;1;Cianorte"
  , "6;Paraná;0;2;Coritiba"
  , "6;Athletico;3;1;Londrina"
  , ""
  , "# Rodada 7"
  , "7;Cascavel;0;1;Paraná"
  , "7;Londrina;2;1;Cianorte"
  , "7;Maringá;1;1;Athletico"
  , "7;Coritiba;2;1;Operário"
  ]

-- | Entrada com erros de digitação, usada na demonstração do main.
-- Cada linha inválida provoca um construtor diferente de Erro; as
-- linhas 2 e 9 são válidas, mas escalam o Coritiba duas vezes na
-- rodada 1.
dadosComErros :: String
dadosComErros = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , "1;Coritiba;2;1;Athletico"
  , "1;Paraná;dois;0;Londrina"
  , "1;Maringá;1;2"
  , "1;Cianorte;-1;0;Cascavel"
  , "1;Operário;1;1;Operário"
  , "0;Londrina;1;0;Maringá"
  , "1; ;1;0;Maringá"
  , "1;Coritiba;0;0;Cascavel"
  ]
