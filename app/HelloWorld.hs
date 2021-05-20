{-# LANGUAGE FlexibleContexts #-}
module Main where

import Prelude hiding (readFile, writeFile)
import System.Exit (exitFailure, exitSuccess)
import System.Environment (getArgs)
import Data.List (isSuffixOf)
import Data.ByteString (readFile, writeFile, ByteString)
import Control.Monad.State hiding (void)
import Control.Monad.RWS hiding (void)

import LLVM.AST as IR
import LLVM.AST.Global as IR
import LLVM.Internal.Context as LLVM
import LLVM.Internal.Module as LLVM
import LLVM.IRBuilder.Monad as LLVM
import LLVM.IRBuilder.Module as LLVM
import LLVM.IRBuilder.Instruction as LLVM

type HaskellPassInput = [String]
type HaskellPassState = [(String, Int)]
type HaskellPassOutput = [String]
type HaskellPass a = IR.Module -> IRBuilderT (RWST HaskellPassInput HaskellPassOutput HaskellPassState ModuleBuilder) a

runHaskellPass :: (HaskellPass a) -> HaskellPassInput -> IR.Module -> IO (IR.Module, a)
runHaskellPass pass input mod = do
  let haskellPassState = []
  let irBuilderState = LLVM.emptyIRBuilder
  let modBuilderState = LLVM.emptyModuleBuilder
  let (((result, _), output), defs) = LLVM.runModuleBuilder modBuilderState $ do
                              (\x -> evalRWST x input haskellPassState) $
                                runIRBuilderT irBuilderState $ pass mod
  mapM_ putStrLn output
  return (mod { IR.moduleDefinitions = defs }, result)

helloWorldPass :: HaskellPass ()
helloWorldPass mod = do
  let defs = IR.moduleDefinitions mod
  mapM_ visit defs
  return ()
  where
    visit (IR.GlobalDefinition f@(Function {})) = do
      tell ["Hello from: " ++ (show $ IR.name f)]
      tell ["  number of arguments: " ++ (show $ length $ fst $ IR.parameters f)]
      return ()
    visit _ = return ()

main :: IO ()
main = do
  args <- getArgs
  if (length args) == 1
  then do
    let file = head args
    if isSuffixOf ".bc" file
    then do
      mod <- LLVM.withContext (\ctx -> do
               LLVM.withModuleFromBitcode ctx (LLVM.File file) LLVM.moduleAST)
      (mod', _) <- runHaskellPass helloWorldPass [] mod
      bitcode <- LLVM.withContext $ (\ctx -> do
                   LLVM.withModuleFromAST ctx mod LLVM.moduleBitcode)
      writeFile file bitcode
      exitSuccess

    else if isSuffixOf ".ll" file
    then do
      fcts <- readFile file
      mod <- LLVM.withContext (\ctx -> do
               LLVM.withModuleFromLLVMAssembly ctx fcts LLVM.moduleAST)
      (mod', _) <- runHaskellPass helloWorldPass [] mod
      assembly <- LLVM.withContext $ (\ctx -> do
                    LLVM.withModuleFromAST ctx mod LLVM.moduleLLVMAssembly)
      writeFile file assembly
      exitSuccess

    else do
      putStrLn ("Invalid file extension (need either .bc or .ll): " ++ file)
      exitFailure

  else do
    putStrLn $ "usage: HelloWorld FILE.{bc,ll}"
    exitFailure
