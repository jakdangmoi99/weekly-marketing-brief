#!/bin/bash
BRIEFING_SRC="$HOME/Documents/Claude/Projects/조비스/마케팅_브리핑/마케팅_브리핑_아카이브.html"
REPO_DIR="$HOME/weekly-marketing-brief"

if [ ! -f "$BRIEFING_SRC" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 브리핑 파일 없음: $BRIEFING_SRC" >&2
  exit 1
fi

cp "$BRIEFING_SRC" "$REPO_DIR/index.html"

python3 - "$REPO_DIR/index.html" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path, 'r') as f:
    html = f.read()

meta = '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n<meta http-equiv="Pragma" content="no-cache">\n<meta http-equiv="Expires" content="0">\n<meta name="apple-mobile-web-app-capable" content="yes">\n<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">'

css = '''.ptr-indicator{text-align:center;height:0;overflow:hidden;transition:height .2s;font-size:14px;color:#94a3b8;line-height:50px}
.ptr-indicator.pulling{height:50px}
.ptr-indicator.refreshing{height:50px;color:#3b82f6}'''

ptr_script = '''<div class="ptr-indicator" id="ptr">⬇ 당겨서 새로고침</div>
<script>
(function(){
  var startY=0,pulling=false,el=document.getElementById('ptr');
  document.addEventListener('touchstart',function(e){
    if(window.scrollY===0){startY=e.touches[0].clientY;pulling=true;}
  },{passive:true});
  document.addEventListener('touchmove',function(e){
    if(!pulling)return;
    var dy=e.touches[0].clientY-startY;
    if(dy>0&&dy<150){el.style.height=Math.min(dy*0.5,50)+'px';}
    if(dy>80){el.className='ptr-indicator pulling';el.textContent='↻ 놓으면 새로고침';}
    else{el.className='ptr-indicator';el.textContent='⬇ 당겨서 새로고침';}
  },{passive:true});
  document.addEventListener('touchend',function(){
    if(!pulling)return;
    pulling=false;
    if(el.classList.contains('pulling')){
      el.className='ptr-indicator refreshing';
      el.textContent='새로고침 중...';
      window.location.href=window.location.pathname+'?t='+Date.now();
    }else{el.style.height='0';}
  });
})();
</script>'''

html = html.replace('<meta charset="UTF-8">', '<meta charset="UTF-8">\n' + meta, 1)
html = html.replace('</style>', css + '\n</style>', 1)
html = html.replace('<body>', '<body>\n' + ptr_script, 1)

with open(path, 'w') as f:
    f.write(html)
PYEOF

cd "$REPO_DIR"
git add index.html
git diff --cached --quiet && { echo "$(date '+%Y-%m-%d %H:%M:%S') 변경 없음, 스킵"; exit 0; }
git commit -m "weekly-brief $(date '+%Y-%m-%d')"
git push origin main
echo "$(date '+%Y-%m-%d %H:%M:%S') push 완료"
