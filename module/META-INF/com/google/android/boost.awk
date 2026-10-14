# Sets absolute values in perfboostsconfig.xml (idempotent, independent of current values).
function attr(b, name,   s) {
  if (match(b, "[ \t\n]" name "=\"[^\"]*\"")) {
    s = substr(b, RSTART, RLENGTH); sub(/^[^"]*"/, "", s); sub(/"$/, "", s); return s
  }
  return ""
}
function settimeout(b, t) {
  if (b !~ /Timeout="[0-9]+"/) { bad++; return b }
  sub(/Timeout="[0-9]+"/, "Timeout=\"" t "\"", b); return b
}
function setres(b, op, v,   pre, rest) {
  if (!match(b, op ",[ \t\n]*")) { bad++; return b }
  pre = substr(b, 1, RSTART + RLENGTH - 1)
  rest = substr(b, RSTART + RLENGTH)
  if (rest !~ /^[0-9A-Fa-fxX]+/) { bad++; return b }
  sub(/^[0-9A-Fa-fxX]+/, v, rest)
  return pre rest
}
function handle(b,   id, ty, tg) {
  id = attr(b, "Id"); ty = attr(b, "Type"); tg = attr(b, "Target")
  if (id == "0x00001081" && ty == "1" && tg == "khaje") {
    b = settimeout(b, B1T); b = setres(b, "0x40800000", B1L); b = setres(b, "0x40800100", B1B); n++
  } else if (id == "0x00001081" && ty == "6" && tg == "khaje") {
    b = settimeout(b, B6T); n++
  } else if (id == "0x00001081" && (ty == "3" || ty == "4") && tg == "bengal,khaje") {
    b = settimeout(b, B34T); n++
  } else if (id == "0x00001082" && (ty == "1" || ty == "2") && tg == "khaje") {
    b = settimeout(b, RT); b = setres(b, "0x40800000", RL); b = setres(b, "0x40800100", RB); n++
  }
  return b
}
{
  if (!inb && $0 ~ /<Config([ \t]|$)/) { inb = 1; buf = $0 }
  else if (inb) { buf = buf "\n" $0 }
  else { print; next }
  if (buf ~ /\/>/) { printf "%s\n", handle(buf); inb = 0; buf = "" }
}
END {
  if (inb || n != 6 || bad) { print "boost.awk: expected 6 edits, got " n ", bad=" bad+0 > "/dev/stderr"; exit 3 }
}
