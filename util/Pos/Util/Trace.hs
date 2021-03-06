
module Pos.Util.Trace
    ( Trace (..)
    , trace
    , traceWith
    , noTrace
    -- TODO put wlog tracing into its own module.
    , wlogTrace
    , Wlog.Severity (..)
    ) where

import           Universum hiding (trace)
import           Data.Functor.Contravariant (Contravariant (..), Op (..))
import           Formatting (sformat, string, stext, (%))
import qualified System.Wlog as Wlog

-- | Abstracts logging.
newtype Trace m s = Trace
    { runTrace :: Op (m ()) s
    }

instance Contravariant (Trace m) where
    contramap f = Trace . contramap f . runTrace

trace :: Trace m s -> s -> m ()
trace = getOp . runTrace

-- | Alias to 'trace' so that you don't clash with 'Debug.trace' in case it's
-- imported (Universum exports it).
traceWith :: Trace m s -> s -> m ()
traceWith = trace

-- | A 'Trace' that ignores everything. NB this actually turns off logging: it
-- doesn't force the logged messages.
noTrace :: Applicative m => Trace m a
noTrace = Trace $ Op $ const (pure ())

-- | A 'Trace' that uses log-warper.
wlogTrace :: Wlog.LoggerName -> String -> Trace IO (Wlog.Severity, Text)
wlogTrace loggerName selfName = Trace $ Op $ \(severity, txt) ->
  let txtWithName = sformat (string%": "%stext) selfName txt
  in  Wlog.usingLoggerName loggerName $ Wlog.logMessage severity txtWithName
