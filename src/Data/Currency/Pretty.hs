-- | Pretty print monetary amounts like:
--
-- * /$ 34.50/
--
-- * /USD 3,456.29/
--
-- * /€ 32 433 938.23/
--
-- Using default printing settings
--
-- >>> prettyPrint (Amount USD 2342.2)
-- "USD 2,342.20"
-- >>> prettyPrint (Amount EUR 45827.346)
-- "EUR 45,827.35"
--
-- Using custom printing settings
--
-- >>> prettyPrintWith (defaultConfig { useCurrencySymbol = True }) (Amount USD 2342.2)
-- "$ 2,342.20"
-- >>> prettyPrintWith (defaultConfig { useCurrencySymbol = True }) (Amount EUR 2342.2)
-- "€ 2,342.20"
-- >>> prettyPrintWith (defaultConfig { showDecimals = False }) (Amount USD 25.50)
-- "USD 25"
--
-- For more printing settings see 'PrettyConfig'

module Data.Currency.Pretty
    ( -- * Pretty printing
      prettyPrint
    , prettyPrintWith

      -- * Configuration
    , PrettyConfig(..)
    , defaultConfig

    , module Data.Currency.Amounts
    ) where

import Data.Currency.Amounts
import Data.Monoid           ((<>))
import Text.Printf

-- | Pretty print a monetary amount using 'defaultConfig'
prettyPrint :: (Currency c) => Amount c -> String
prettyPrint = prettyPrintWith defaultConfig

-- | Pretty print a monetary amount with a custom 'PrettyConfig' configuration
prettyPrintWith :: (Currency c) => PrettyConfig -> Amount c -> String
prettyPrintWith cnf (Amount currency amount) =
    prefixSymbol currency cnf
    $ prefixCode currency cnf
    $ changeDecimalSep cnf
    $ largeAmountSeparate cnf
    $ toDecimalString currency cnf amount

prefixSymbol :: (Currency c) => c -> PrettyConfig -> String -> String
prefixSymbol currency cnf val
    | useCurrencySymbol cnf = symbol currency <> " " <> val
    | otherwise = val

prefixCode :: (Currency c) => c -> PrettyConfig -> String -> String
prefixCode currency cnf val
    | useCurrencySymbol cnf = val
    | suffixIsoCode cnf = val <> " " <> isoCode currency
    | otherwise = isoCode currency <> " " <> val

changeDecimalSep :: PrettyConfig -> String -> String
changeDecimalSep cnf = replaceFst '.' (decimalSeparator cnf)
    where
        replaceFst :: Char -> Char -> String -> String
        replaceFst _ _ [] = []
        replaceFst c c' (s:ss)
            | s == c = c' : ss
            | otherwise = s : replaceFst c c' ss

largeAmountSeparate :: PrettyConfig -> String -> String
largeAmountSeparate cnf amount
    | compactFourDigitAmounts cnf = if length integer <= 4
        then sign mSign unsignedAmount
        else separatedAmount
    | otherwise = separatedAmount
    where
        (mSign, unsignedAmount) = unSign amount
        (integer, decimal) = span (/= '.') unsignedAmount
        separated = reverse $ intersperseN 3 (largeAmountSeparator cnf) $ reverse integer
        separatedAmount = sign mSign $ separated ++ decimal

toDecimalString :: (Currency c) => c -> PrettyConfig -> Double -> String
toDecimalString currency cnf amount
    | showDecimals cnf = printf format amount
    | otherwise = takeWhile (/= '.') $ printf "%.1f" amount
    where format = "%." <> show (decimalDigits currency) <> "f"

intersperseN :: Eq a => Int -> a -> [a] -> [a]
intersperseN n s ss
    | null remainder = ss
    | otherwise = (chunk ++ [s]) ++ intersperseN n s remainder
    where (chunk, remainder) = splitAt n ss

sign :: Maybe Char -> String -> String
sign (Just s) a = s : a
sign Nothing a  = a

unSign :: String -> (Maybe Char, String)
unSign ('-':s) = (Just '-', s)
unSign ('+':s) = (Just '+', s)
unSign s       = (Nothing, s)


data PrettyConfig = PrettyConfig
    { showDecimals            :: Bool
    -- | Print four digits amounts as
    -- /USD 1000,00/ instead of /USD 1,000.00/
    , compactFourDigitAmounts :: Bool
    -- | Replace the currency ISO code with its symbol to produce
    -- /$ 23.50/ instead of /USD 23.50/
    , useCurrencySymbol       :: Bool
    -- | Use the currency ISO code as suffix to produce
    -- /23.50 USD/ instead of /USD 23.50/
    , suffixIsoCode           :: Bool
    , largeAmountSeparator    :: Char
    , decimalSeparator        :: Char
    } deriving (Show)


-- | Default 'PrettyConfig' used in 'prettyPrint'
--
-- * Show decimals
--
-- * Compact four digit amounts
--
-- * Use ISO code
--
-- * Separate large amounts with comma
--
-- * Separate decimals with dot
defaultConfig :: PrettyConfig
defaultConfig = PrettyConfig
    { showDecimals = True
    , compactFourDigitAmounts = True
    , useCurrencySymbol = False
    , suffixIsoCode = False
    , largeAmountSeparator = ','
    , decimalSeparator = '.'
    }
