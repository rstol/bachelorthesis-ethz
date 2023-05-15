with builtins;
files:
  if isList files
  then hashString "md5" (foldl' (x: y: x + (hashFile "md5" y)) "" (sort lessThan files))
  else hashFile "md5" files