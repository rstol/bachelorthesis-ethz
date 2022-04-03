with builtins;
{ namePaths ? [],  tagPath ? ./. }: {
  nameHash = hashString "md5" (foldl' (x: y: x + (hashFile "md5" y)) "" (sort lessThan namePaths));
  tagHash = hashFile "md5" tagPath;
}