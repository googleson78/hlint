
module Grep(runGrep) where

import Hint.All
import Apply
import Config.Type
import HSE.All
import Control.Monad
import Data.List
import Util
import Idea

import qualified HsSyn as GHC
import qualified BasicTypes as GHC
import Language.Haskell.GhclibParserEx.GHC.Hs.ExtendInstances
import SrcLoc as GHC hiding (mkSrcSpan)

runGrep :: String -> ParseFlags -> [FilePath] -> IO ()
runGrep patt flags files = do
    exp <- case parseExp patt of
        ParseOk x -> return x
        ParseFailed sl msg ->
            exitMessage $ (if "Parse error" `isPrefixOf` msg then msg else "Parse error in pattern: " ++ msg) ++ "\n" ++
                          patt ++ "\n" ++
                          replicate (srcColumn sl - 1) ' ' ++ "^"
    let unit = GHC.noLoc $ GHC.ExplicitTuple GHC.noExt [] GHC.Boxed
    let rule = hintRules [HintRule Suggestion "grep" exp (Tuple an Boxed []) Nothing []
                         -- Todo : Replace these with "proper" GHC expressions.
                          (extendInstances mempty) (extendInstances unit) (extendInstances unit) Nothing]
    forM_ files $ \file -> do
        res <- parseModuleEx flags file Nothing
        case res of
            Left (ParseError sl msg ctxt) ->
                print $ rawIdeaN Error (if "Parse error" `isPrefixOf` msg then msg else "Parse error: " ++ msg) sl ctxt Nothing []
            Right m ->
                forM_ (applyHints [] rule [m]) $ \i ->
                    print i{ideaHint="", ideaTo=Nothing}
