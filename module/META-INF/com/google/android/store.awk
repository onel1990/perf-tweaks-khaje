# Sets absolute values in perfconfigstore.xml (idempotent, independent of current values).
function setval(s, v) { sub(/Value="[^"]*"/, "Value=\"" v "\"", s); return s }
{
  if ($0 ~ /Name="ro\.vendor\.qti\.sys\.fw\.bg_apps_limit"/ && $0 !~ /Target=|Variant=/) { $0 = setval($0, BG); n++ }
  else if ($0 ~ /Name="ro\.vendor\.qti\.sys\.fw\.bservice_age"/ && $0 !~ /Target=|Variant=/) { $0 = setval($0, AGE); n++ }
  else if ($0 ~ /Name="ro\.vendor\.qti\.sys\.fw\.bservice_limit"/ && $0 !~ /Target=|Variant=/) { $0 = setval($0, LIM); n++ }
  else if ($0 ~ /Name="ro\.lmk\.thrashing_threshold"/ && $0 ~ /Target="khaje"/) { $0 = setval($0, THR); n++ }
  else if ($0 ~ /Name="vendor\.perf\.gestureflingboost\.enable"/) { $0 = setval($0, FLING); n++ }
  print
}
END {
  if (n != 5) { print "store.awk: expected 5 edits, got " n > "/dev/stderr"; exit 3 }
}
