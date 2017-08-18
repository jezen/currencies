module Data.Currency.Pretty where

import Text.Printf
import Data.Currency.Currencies
import Data.Monoid ((<>))

-- | Pretty print a monetary amount using 'defaultConfig'
humanReadable :: (Currency c) => Amount c -> String
humanReadable = humanReadableWith defaultConfig

-- | Pretty print a monetary amount with a custom configuration
humanReadableWith :: (Currency c) => PrettyConfig -> Amount c -> String
humanReadableWith cnf (Amount currency amount) =
    prefixCode currency $ toDecimalString currency amount

prefixCode :: (Currency c) => c -> String -> String
prefixCode currency val = (isoCode currency) <> " " <> val

toDecimalString :: (Currency c) => c  -> Double -> String
toDecimalString currency amount = printf format amount
    where format = "%." <> (show $ decimalDigits currency) <> "f"


defaultConfig :: PrettyConfig
defaultConfig = PrettyConfig
    { showFractions = True
    , separateFourDigitAmounts = False
    , useCurrencySymbol = False
    , suffixIsoCode = False
    , largeAmountSeparator = ','
    , decimalSeparator = '.'
    }

data PrettyConfig = PrettyConfig
    { showFractions :: Bool
    , separateFourDigitAmounts :: Bool
    , useCurrencySymbol :: Bool
    , suffixIsoCode :: Bool
    , largeAmountSeparator :: Char
    , decimalSeparator :: Char
    } deriving (Show)
