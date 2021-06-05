module Reach.Eval.ImportSource
  ( HostGit(..)
  , ImportSource(..)
  , importSource
  , lockModuleAbsPath
  , lockModuleAbsPathGitLocalDep
  ) where

import Text.Parsec
import Control.Exception hiding (try)
import Control.Monad.Extra     
import Control.Monad.Reader
import Crypto.Hash
import Data.Aeson hiding ((<?>), encode)
import Data.ByteArray          
import Data.ByteArray.Encoding 
import Data.List (intercalate, find)              
import Data.Maybe
import Data.Text.Encoding      
import Data.Yaml               
import GHC.Generics            
import System.Directory        
import System.Directory.Extra  
import System.Exit            
import System.FilePath        
import System.Process         
import Text.Printf            
import System.PosixCompat.Files
import Reach.AST.Base       
import Reach.Util        
import qualified Data.ByteString as B
import qualified Data.Map.Strict as M
import qualified Data.Text       as T

data Env = Env
  { srcloc      :: SrcLoc
  , installPkgs :: Bool
  , dirDotReach :: FilePath
  }

type App        = ReaderT Env IO
type HostGitRef = String
type GitUri     = String

toBase16 :: ByteArrayAccess b => b -> T.Text
toBase16 a = decodeUtf8
  . convertToBase Base16
  $ (convert a :: B.ByteString)

fromBase16 :: ByteArray b => T.Text -> Either T.Text b
fromBase16 = either (Left . T.pack) Right
  . convertFromBase Base16
  . encodeUtf8

newtype SHA = SHA (Digest SHA256)
  deriving (Eq, Show, Ord)

instance ToJSON SHA where
  toJSON (SHA d) = toJSON $ toBase16 d

instance FromJSON SHA where
  parseJSON = withText "SHA" $ \a -> maybe
    (fail $ "Invalid SHA: " <> show a)
    (pure . SHA)
    (digestFromByteString =<< either (const Nothing) Just (fromBase16 @B.ByteString a))

instance ToJSONKey   SHA
instance FromJSONKey SHA

data HostGit = HostGit
  { host :: String
  , acct :: String
  , repo :: String
  , ref  :: String
  , dir  :: [FilePath]
  , file :: FilePath
  } deriving (Eq, Show, Generic, ToJSON, FromJSON)

data ImportSource
  = ImportLocal     FilePath
  | ImportRemoteGit HostGit
  deriving (Eq, Show)

-- | Represents an entry indexed by 'SHA' in 'LockFile' capturing details by
-- which a directly-imported package module may be fetched.
--
-- This type tracks parsed but unevaluated @git@ imports in its 'host' field.
--
-- __The /unevaluated/ distinction here is important:__ e.g. if the user asks
-- to import a module from the package's @master@ branch, in which case we need
-- to perform some additional steps to fix the import to a specific @git SHA@.
-- This is why the 'refsha' field exists.
--
-- Transitive dependencies which are local to the direct import in 'host' and
-- which belong to the same 'refsha' are discovered and added the 'ldeps'
-- field.
data LockModule = LockModule
  { hg   :: HostGit            -- ^ Raw result of parsing import statement
  , refsha :: HostGitRef         -- ^ Git SHA to which @host@ refers at time of locking
  , uri    :: GitUri             -- ^ A @git clone@-able URI
  , ldeps  :: M.Map FilePath SHA -- ^ Repo-local deps discovered during @gatherDeps_*@ phase
  } deriving (Eq, Show, Generic, ToJSON, FromJSON)

data LockFile = LockFile
  { version :: Int
  , modules :: M.Map SHA LockModule
  } deriving (Eq, Show, Generic, ToJSON, FromJSON)

lockFileEmpty :: LockFile
lockFileEmpty =  LockFile
  { version = 1
  , modules = mempty
  }

data PkgError
  = PkgGitCloneFailed         String
  | PkgGitCheckoutFailed      String
  | PkgGitFetchFailed         String
  | PkgGitRevParseFailed      String
  | PkgLockModuleDoesNotExist FilePath
  | PkgLockModuleShaMismatch  FilePath
  | PkgLockModuleUnknown      HostGit
  | PkgLockModifyUnauthorized
  deriving (Eq, ErrorMessageForJson, ErrorSuggestions, Exception)

instance Show PkgError where
  show = \case
    PkgGitCloneFailed         s -> "`git clone` failed: "          <> s
    PkgGitCheckoutFailed      s -> "`git checkout` failed: "       <> s
    PkgGitFetchFailed         s -> "`git fetch` failed: "          <> s
    PkgGitRevParseFailed      s -> "`git rev-parse` failed: "      <> s
    PkgLockModuleDoesNotExist f -> "Lock module \""                <> f <> "\" does not exist"
    PkgLockModuleShaMismatch  f -> "Lock module SHA mismatch on: " <> f
    PkgLockModuleUnknown      h -> "Lock module unknown: "         <> show h
    PkgLockModifyUnauthorized   -> "Did you mean to run with `--install-pkgs`?"

expect_ :: (Show e, ErrorMessageForJson e, ErrorSuggestions e) => e -> App a
expect_ e = asks srcloc >>= flip expect_thrown e

orFail :: (b -> App a) -> (ExitCode, a, b) -> App a
orFail err = \case
  (ExitSuccess  , a, _) -> pure a
  (ExitFailure _, _, b) -> err b

orFail_ :: (b -> App a) -> (ExitCode, a, b) -> App ()
orFail_ err r = orFail err r >> pure ()

runGit :: FilePath -> String -> App (ExitCode, String, String)
runGit cwd c = liftIO
  $ readCreateProcessWithExitCode ((shell ("git " <> c)){ cwd = Just cwd }) ""

fileExists :: FilePath -> App Bool
fileExists = liftIO . doesFileExist

fileRead :: FilePath -> App B.ByteString
fileRead = liftIO . B.readFile

fileUpsert :: FilePath -> B.ByteString -> App ()
fileUpsert f  = liftIO . B.writeFile f

mkdirP :: FilePath -> App ()
mkdirP = liftIO . createDirectoryIfMissing True

gitClone' :: FilePath -> String -> FilePath -> App ()
gitClone' b u d = runGit b (printf "clone %s %s" u d)
  >>= orFail_ (expect_ . PkgGitCloneFailed)

gitCheckout :: FilePath -> String -> App ()
gitCheckout b r = check fetch >> pure () where
  check e = runGit b ("checkout " <> r) >>= orFail e
  fetch _ = runGit b "fetch"
    >>= orFail_ (expect_ . PkgGitFetchFailed)
    >>    check (expect_ . PkgGitCheckoutFailed)

-- | Allow `sudo`-less directory traversal/deletion for Docker users but
-- disable execute bit on individual files
applyPerms :: App ()
applyPerms = do
  dr <- asks dirDotReach
  ds <- liftIO $ listDirectoriesRecursive dr
  fs <- liftIO $ listFilesRecursive       dr
  liftIO $ setFileMode dr accessModes
  liftIO $ mapM_ (flip setFileMode accessModes) ds
  liftIO $ mapM_ (flip setFileMode stdFileMode) fs

dirGitClones :: App FilePath
dirGitClones = (</> "warehouse" </> "git") <$> asks dirDotReach

dirLockModules :: App FilePath
dirLockModules = (</> "sha256") <$> asks dirDotReach

pathLockFile :: App FilePath
pathLockFile = (</> "lock.yaml") <$> asks dirDotReach

withDotReach :: ((LockFile, FilePath) -> App a) -> App a
withDotReach m = do
  warehouse    <- dirGitClones
  lockMods     <- dirLockModules
  lockf        <- pathLockFile
  gitignore    <- (</> ".gitignore")    <$> asks dirDotReach
  dockerignore <- (</> ".dockerignore") <$> asks dirDotReach

  mkdirP warehouse
  mkdirP lockMods

  unlessM (fileExists gitignore)
    $ fileUpsert gitignore $ B.intercalate "\n"
      [ "warehouse/"
      ]

  unlessM (fileExists dockerignore)
    $ fileUpsert dockerignore $ B.intercalate "\n"
      [ "warehouse/"
      ]

  lock <- ifM (fileExists lockf) lockFileRead (pure lockFileEmpty)
  res  <- m (lock, lockf)

  applyPerms
  pure res

gitClone :: HostGit -> App ()
gitClone h = withDotReach $ \_ -> do
  dirClones <- dirGitClones
  let dest = dirClones </> gitCloneDirOf h

  unlessM (liftIO $ doesDirectoryExist dest) $ gitClone' dirClones (gitUriOf h) dest

lockFileRead :: App LockFile
lockFileRead = pathLockFile >>= decodeFileThrow

lockFileUpsert :: LockFile -> App ()
lockFileUpsert a = withDotReach $ \(_, lockf) ->
  fileUpsert lockf $ B.intercalate "\n"
    [ "# Lockfile automatically generated by Reach. Don't edit!"
    , "# This file is meant to be included in source control.\n"
    , encode a
    ]

byGitRefSha :: HostGit -> FilePath -> App (HostGitRef, B.ByteString)
byGitRefSha h fp = withDotReach $ \_ -> do
  case ref h of
    "master" -> f "master" `orTry` f "main"
    ref      -> f ref
 where
  gitRevParse b r = runGit b ("rev-parse " <> r)
    >>= orFail (throw . PkgGitRevParseFailed)
  f ref = do
    dirClone <- (</> gitCloneDirOf h) <$> dirGitClones
    ref'     <- gitRevParse dirClone ref

    gitCheckout dirClone ref'

    whenM (not <$> fileExists fp)
      $ expect_ $ PkgLockModuleDoesNotExist fp

    reach <- fileRead fp
    pure (ref', reach)
  orTry a b = do
    env <- ask
    liftIO $ runReaderT a env `catch` (\case
      PkgGitRevParseFailed _ -> runReaderT b env
      rethrown               -> runReaderT (expect_ rethrown) env)

lockModuleFix :: HostGit -> App (FilePath, LockModule)
lockModuleFix h = withDotReach $ \(lock, _) -> do
  gitClone h
  dirClone      <- (</> gitCloneDirOf h)   <$> dirGitClones
  (rsha, reach) <- byGitRefSha h (dirClone </> gitFilePathOf h)
  lmods         <- dirLockModules
  let hsh = hashWith SHA256 reach
  let dest = lmods </> (T.unpack $ toBase16 hsh)
  let lmod = LockModule { hg     = h
                        , refsha = rsha
                        , uri    = gitUriOf h
                        , ldeps  = mempty
                        }
  whenM (fileExists dest)
    $ whenM (fileRead dest >>= pure . (hsh /=) . hashWith SHA256)
      $ expect_ $ PkgLockModuleShaMismatch dest
  fileUpsert dest reach
  lockFileUpsert
    $ lock { modules = M.insert (SHA hsh) lmod (modules lock) }
  pure (dest, lmod)

(@!!) :: LockFile -> HostGit -> Maybe (SHA, LockModule)
(@!!) l h = find ((== h) . hg . snd) (M.toList $ modules l)
infixl 9 @!!

failIfMissingOrMismatched :: FilePath -> SHA -> App ()
failIfMissingOrMismatched f (SHA s) = do
  whenM (not <$> fileExists f)
    $ expect_ $ PkgLockModuleDoesNotExist f
  whenM (((/= s) . hashWith SHA256) <$> fileRead f)
    $ expect_ $ PkgLockModuleShaMismatch f
  pure ()

lockModuleAbsPath :: SrcLoc -> Bool -> FilePath -> HostGit -> IO FilePath
lockModuleAbsPath srcloc installPkgs dirDotReach h =
  flip runReaderT (Env {..}) $ withDotReach $ \(lock, _) -> do
    case lock @!! h of
      Just (SHA k, _) -> do
        modPath <- (</> (T.unpack $ toBase16 k)) <$> dirLockModules
        failIfMissingOrMismatched modPath (SHA k)
        pure modPath
      Nothing -> if installPkgs
        then lockModuleFix h >>= pure . fst
        else expect_ PkgLockModifyUnauthorized

lockModuleAbsPathGitLocalDep :: SrcLoc -> Bool -> FilePath -> HostGit -> FilePath -> IO FilePath
lockModuleAbsPathGitLocalDep srcloc installPkgs dirDotReach h ldep =
  flip runReaderT (Env {..}) $ withDotReach $ \(lock, _) -> do
  let relPath = gitDirPathOf h </> ldep
  let correct shaParent lm = if not installPkgs
        then expect_ PkgLockModifyUnauthorized
        else do
          let refsha' = refsha lm
          dirClones <- dirGitClones
          gitCheckout (dirClones </> gitCloneDirOf h) refsha'
          reach <- fileRead $ dirClones </> gitCloneDirOf h </> relPath
          lmods <- dirLockModules
          let hsh = hashWith SHA256 reach
              dest = lmods </> (T.unpack $ toBase16 hsh)
              lmod = lm { ldeps = M.insert relPath (SHA hsh) (ldeps lm) }
          whenM (fileExists dest)
            $ whenM (fileRead dest >>= pure . (hsh /=) . hashWith SHA256)
              $ expect_ $ PkgLockModuleShaMismatch dest
          fileUpsert dest reach
          lockFileUpsert
            $ lock { modules = M.insert shaParent lmod (modules lock) }
          pure dest
  case lock @!! h of
    Nothing -> expect_ $ PkgLockModuleUnknown h
    Just (shaParent, lm) -> case M.lookup relPath (ldeps lm) of
      Nothing      -> correct shaParent lm
      Just (SHA s) -> do
        dest <- (</> (T.unpack $ toBase16 s)) <$> dirLockModules
        failIfMissingOrMismatched dest (SHA s)
        pure dest

hostGit :: Parsec String () HostGit
hostGit = do
  HostGit <$> server
          <*> ("host account" `terminatedBy` (char '/'))
          <*> ("repo"         `terminatedBy` endRepo)
          <*> ref
          <*> (many dir)
          <*> (filename <|> pure "index.rsh")
 where
  allowed t = alphaNum <|> oneOf "-_."
    <?> "valid git " <> t <> " character (alphanumeric, -, _, .)"
  f `terminatedBy` x = do
    h <- allowed f
    t <- manyTill (allowed f) x
    pure $ h:t
  tlac  a = try (lookAhead $ char a) *> pure ()
  endRepo = eof <|> tlac '#' <|> tlac ':'
  endRef  = eof <|> char ':'  *> pure ()
  server = fromMaybe "github.com" <$>
    optionMaybe (try $ "server" `terminatedBy` (char ':'))
  ref =     try ((char '#') *> "ref" `terminatedBy` endRef)
    <|> optional (char '#') *> pure "master"     <* endRef
  dir = try $ manyTill (allowed "directory") (char '/')
  filename = do
    n <- "file" `terminatedBy` (try . lookAhead $ string ".rsh" <* eof)
    pure $ n <> ".rsh"

remoteGit :: Parsec FilePath () ImportSource
remoteGit = do
  _ <- string "@"
  h <- hostGit
  pure $ ImportRemoteGit h

localPath :: Parsec FilePath () ImportSource
localPath = do
  p <- manyTill anyChar eof
  if isValid p then pure $ ImportLocal p
               else fail $ "Invalid local path: " <> p

data Err_Parse_InvalidImportSource
  = Err_Parse_InvalidImportSource FilePath ParseError
  deriving (Eq, ErrorMessageForJson, ErrorSuggestions)

instance Show Err_Parse_InvalidImportSource where
  show (Err_Parse_InvalidImportSource fp e) =
    "Invalid import: " <> fp <> "\n" <> show e

importSource :: SrcLoc -> FilePath -> IO ImportSource
importSource srcloc fp = either
  (expect_thrown srcloc . Err_Parse_InvalidImportSource fp)
  pure
  (runParser (remoteGit <|> localPath) () "" fp)

gitUriOf :: HostGit -> GitUri
gitUriOf (HostGit {..}) =
  printf "https://%s/%s/%s.git" host acct repo

gitCloneDirOf :: HostGit -> String
gitCloneDirOf (HostGit {..}) =
  printf "@%s:%s:%s" host acct repo

gitDirPathOf :: HostGit -> FilePath
gitDirPathOf (HostGit {..}) =
  intercalate (pathSeparator : "") dir

gitFilePathOf :: HostGit -> FilePath
gitFilePathOf h@(HostGit {..}) =
  gitDirPathOf h </> file
