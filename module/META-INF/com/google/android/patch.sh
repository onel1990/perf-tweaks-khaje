#!/system/bin/sh
# usage: patch.sh <normal|game|battery> <store|boost> <input.xml> <output.xml>
D=${0%/*}
case "$1" in
  normal)  BG=32 AGE=600000 LIM=15 THR=40 FLING=true  B1T=2000 B1L=1766 B1B=1516 B6T=2000 B34T=8000  RT=600 RL=0xFFF RB=0xFFF ;;
  game)    BG=24 AGE=300000 LIM=15 THR=30 FLING=true  B1T=2500 B1L=1766 B1B=1516 B6T=3500 B34T=15000 RT=800 RL=0xFFF RB=0xFFF ;;
  battery) BG=20 AGE=180000 LIM=10 THR=30 FLING=false B1T=1000 B1L=1344 B1B=1190 B6T=2000 B34T=3000  RT=300 RL=1344  RB=1190  ;;
  *) echo "unknown profile: $1" >&2; exit 2 ;;
esac
case "$2" in
  store) awk -v BG=$BG -v AGE=$AGE -v LIM=$LIM -v THR=$THR -v FLING=$FLING -f "$D/store.awk" "$3" > "$4" ;;
  boost) awk -v B1T=$B1T -v B1L=$B1L -v B1B=$B1B -v B6T=$B6T -v B34T=$B34T -v RT=$RT -v RL=$RL -v RB=$RB -f "$D/boost.awk" "$3" > "$4" ;;
  *) echo "unknown target: $2" >&2; exit 2 ;;
esac
