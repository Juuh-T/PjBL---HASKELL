-- =============================================================
-- Camada 3: Leitura, Validação e Saída
--
-- Converte o texto do campeonato em [Partida], validando cada
-- linha com as mônadas Maybe e Either, e formata a tabela para
-- impressão. Todo o módulo é puro: nenhuma função aqui faz IO.
-- =============================================================
module Leitura
  ( Erro (..)
  , separar
  , aparar
  , linhasUteis
  , lerPartida
  , lerCampeonato
  , todosOsErros
  , mensagemErro
  , tabelaFormatada
  ) where

import Data.Char (isSpace)
import Data.Either (lefts, rights)
import Data.List (dropWhileEnd, groupBy, intercalate, isPrefixOf, sortOn)
import Data.Maybe (listToMaybe)
import Text.Read (readMaybe)

import Classificacao (aproveitamento, pontosLinha, saldo)
import Tipos

-- -------------------------------------------------------------
-- Erros
-- -------------------------------------------------------------

-- | Problemas possíveis na entrada. O primeiro campo de cada
-- construtor indica onde o problema está: o número da linha no
-- texto original (contando comentários e linhas em branco) ou,
-- no caso de TimeRepetidoNaRodada, a rodada.
data Erro
  = CamposInvalidos Int Int
    -- ^ linha, quantidade de campos encontrada (esperado: 5)
  | NumeroInvalido Int String
    -- ^ linha, texto que não é um número inteiro
  | PlacarNegativo Int Int
    -- ^ linha, placar lido
  | RodadaInvalida Int Int
    -- ^ linha, rodada lida (precisa ser >= 1)
  | TimeVazio Int
    -- ^ linha com nome de time em branco
  | MesmoTime Int Time
    -- ^ linha, time escalado contra si mesmo
  | TimeRepetidoNaRodada Int Time [Int]
    -- ^ rodada, time, linhas em que ele aparece
  deriving (Show, Eq)

-- | Mensagem legível para o usuário final.
mensagemErro :: Erro -> String
mensagemErro (CamposInvalidos n k) =
  "Linha " ++ show n ++ ": esperados 5 campos separados por ';', encontrados " ++ show k
mensagemErro (NumeroInvalido n txt) =
  "Linha " ++ show n ++ ": \"" ++ txt ++ "\" não é um número inteiro válido"
mensagemErro (PlacarNegativo n g) =
  "Linha " ++ show n ++ ": placar negativo (" ++ show g ++ ")"
mensagemErro (RodadaInvalida n r) =
  "Linha " ++ show n ++ ": rodada " ++ show r ++ " inválida (deve ser maior ou igual a 1)"
mensagemErro (TimeVazio n) =
  "Linha " ++ show n ++ ": nome de time em branco"
mensagemErro (MesmoTime n t) =
  "Linha " ++ show n ++ ": " ++ t ++ " não pode jogar contra si mesmo"
mensagemErro (TimeRepetidoNaRodada r t ns) =
  "Rodada " ++ show r ++ ": " ++ t ++ " joga mais de uma vez (linhas "
    ++ intercalate ", " (map show ns) ++ ")"

-- -------------------------------------------------------------
-- Texto -> campos
-- -------------------------------------------------------------

-- | Quebra o texto em cada ocorrência do separador, preservando
-- campos vazios ("a;;b" tem três campos). Feito com foldr sobre
-- um acumulador (campo atual, campos já fechados), por isso é
-- total: nunca precisa de head nem de casamento incompleto.
separar :: Char -> String -> [String]
separar sep = uncurry (:) . foldr passo ("", [])
  where
    passo c (atual, campos)
      | c == sep  = ("", atual : campos)
      | otherwise = (c : atual, campos)

-- | Remove espaços (e o '\r' de arquivos do Windows) das pontas.
aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace

-- | Linhas que descrevem partidas, numeradas pela posição no texto
-- original. Linhas em branco e comentários (#) são descartados,
-- mas a numeração não é refeita, para que o erro aponte a linha
-- que o usuário vê no arquivo.
linhasUteis :: String -> [(Int, String)]
linhasUteis = filter (relevante . aparar . snd) . zip [1 ..] . lines
  where
    relevante l = not (null l) && not ("#" `isPrefixOf` l)

-- -------------------------------------------------------------
-- Leitura de uma partida (mônada Either)
-- -------------------------------------------------------------

-- | Falha com o erro dado quando a condição não vale.
garantir :: Bool -> Erro -> Either Erro ()
garantir True _     = Right ()
garantir False erro = Left erro

-- | Converte um campo em Int com readMaybe; o Maybe vira Either
-- com 'maybe', carregando o número da linha no erro.
lerNumero :: Int -> String -> Either Erro Int
lerNumero n txt = maybe (Left (NumeroInvalido n txt)) Right (readMaybe txt)

lerPlacar :: Int -> String -> Either Erro Int
lerPlacar n txt = do
  g <- lerNumero n txt
  garantir (g >= 0) (PlacarNegativo n g)
  pure g

lerRodada :: Int -> String -> Either Erro Int
lerRodada n txt = do
  r <- lerNumero n txt
  garantir (r >= 1) (RodadaInvalida n r)
  pure r

lerTime :: Int -> String -> Either Erro Time
lerTime n t = do
  garantir (not (null t)) (TimeVazio n)
  pure t

-- | Exatamente cinco campos: rodada;mandante;gm;gv;visitante.
cincoCampos :: Int -> [String] -> Either Erro (String, String, String, String, String)
cincoCampos _ [r, m, gm, gv, v] = Right (r, m, gm, gv, v)
cincoCampos n campos            = Left (CamposInvalidos n (length campos))

-- | Converte uma linha (com seu número) em partida. Cada passo do
-- bloco do pode falhar; o primeiro Left interrompe o restante.
lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha = do
  (r, m, gm, gv, v) <- cincoCampos n (map aparar (separar ';' linha))
  rod   <- lerRodada n r
  mand  <- lerTime n m
  golsM <- lerPlacar n gm
  golsV <- lerPlacar n gv
  vis   <- lerTime n v
  garantir (mand /= vis) (MesmoTime n mand)
  pure (Partida rod mand golsM golsV vis)

-- | lerPartida guardando o número da linha junto da partida, que
-- é necessário para apontar as linhas de um time repetido.
lerNumerada :: (Int, String) -> Either Erro (Int, Partida)
lerNumerada (n, linha) = (,) n <$> lerPartida n linha

-- -------------------------------------------------------------
-- Validação do campeonato inteiro
-- -------------------------------------------------------------

-- | Um erro para cada (rodada, time) que aparece em mais de uma
-- partida. Agrupa as escalações por (rodada, time); o padrão
-- (_ : _ : _) na compreensão só aceita grupos com 2+ elementos.
repeticoes :: [(Int, Partida)] -> [Erro]
repeticoes lidas =
  [ TimeRepetidoNaRodada r t (map snd grupo)
  | grupo@(((r, t), _) : _ : _) <- grupos ]
  where
    escalacoes =
      [ ((rodada p, t), n) | (n, p) <- lidas, t <- [mandante p, visitante p] ]
    grupos = groupBy (\a b -> fst a == fst b) (sortOn fst escalacoes)

-- | Lê o texto inteiro. traverse para no primeiro erro de linha;
-- se todas forem válidas, verifica as escalações por rodada.
lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto = do
  lidas <- traverse lerNumerada (linhasUteis texto)
  maybe (Right (map snd lidas)) Left (listToMaybe (repeticoes lidas))

-- | Todos os erros do texto, não só o primeiro: os erros de cada
-- linha, seguidos das repetições encontradas entre as linhas
-- válidas. Vazio se e somente se lerCampeonato devolve Right.
todosOsErros :: String -> [Erro]
todosOsErros texto = lefts resultados ++ repeticoes (rights resultados)
  where
    resultados = map lerNumerada (linhasUteis texto)

-- -------------------------------------------------------------
-- Saída
-- -------------------------------------------------------------

alinharDireita :: Int -> String -> String
alinharDireita w s = replicate (w - length s) ' ' ++ s

alinharEsquerda :: Int -> String -> String
alinharEsquerda w s = s ++ replicate (w - length s) ' '

-- | Saldo com sinal explícito: +3, 0, -2.
comSinal :: Int -> String
comSinal x
  | x > 0     = '+' : show x
  | otherwise = show x

-- | Percentual com uma casa decimal, sem depender de printf.
umaCasa :: Double -> String
umaCasa x = show inteiro ++ "." ++ show decimo
  where
    (inteiro, decimo) = (round (x * 10) :: Int) `divMod` 10

-- | Tabela pronta para impressão: posição, time, pontos, jogos,
-- vitórias, empates, derrotas, gols pró, gols contra, saldo e
-- aproveitamento. Uma lista vazia gera um aviso em vez de uma
-- tabela sem linhas.
tabelaFormatada :: [Linha] -> String
tabelaFormatada [] = "(tabela vazia: nenhuma partida registrada)\n"
tabelaFormatada linhas =
  unlines (cabecalho : regua : zipWith formatar [1 :: Int ..] linhas)
  where
    largura = foldr (max . length . time) (length "Time") linhas
    numeros = ["P", "J", "V", "E", "D", "GP", "GC", "SG"]

    cabecalho =
      alinharDireita 4 "Pos" ++ "  " ++ alinharEsquerda largura "Time"
        ++ concatMap (alinharDireita 5) numeros ++ alinharDireita 8 "%"
    regua = replicate (length cabecalho) '-'

    formatar pos l =
      alinharDireita 3 (show pos) ++ ".  " ++ alinharEsquerda largura (time l)
        ++ concatMap (alinharDireita 5)
             [ show (pontosLinha l), show (jogos l), show (vitorias l)
             , show (empates l), show (derrotas l), show (golsPro l)
             , show (golsContra l), comSinal (saldo l) ]
        ++ alinharDireita 8 (umaCasa (aproveitamento l))
