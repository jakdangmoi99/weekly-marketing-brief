#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
set -euo pipefail

BRIEFING_SRC="$HOME/Documents/Claude/Projects/조비스/마케팅_브리핑/마케팅_브리핑_아카이브.html"
REPO_DIR="$HOME/weekly-marketing-brief"
BUILD_TS=$(date '+%Y-%m-%d %H:%M KST')

if [ ! -f "$BRIEFING_SRC" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 브리핑 파일 없음: $BRIEFING_SRC" >&2
  exit 1
fi

cp "$BRIEFING_SRC" "$REPO_DIR/index.html"

python3 - "$REPO_DIR/index.html" "$BUILD_TS" <<'PYEOF'
import sys, re
path, build_ts = sys.argv[1], sys.argv[2]
with open(path, 'r') as f:
    html = f.read()

head_inject = '''<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<script>
(function(){
  var BUILD = document.documentElement.getAttribute('data-build-ts') || '';
  function check(){
    try{
      fetch(location.pathname + '?_c=' + Date.now(), {cache:'no-store'})
        .then(function(r){ return r.text(); })
        .then(function(t){
          var m = t.match(/data-build-ts="([^"]+)"/);
          if (m && m[1] && m[1] !== BUILD){
            location.replace(location.pathname + '?t=' + Date.now() + location.hash);
          }
        }).catch(function(){});
    }catch(e){}
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', check);
  } else { check(); }
  window.addEventListener('pageshow', function(e){
    if (e.persisted) location.replace(location.pathname + '?t=' + Date.now() + location.hash);
  });
  document.addEventListener('visibilitychange', function(){
    if (!document.hidden) check();
  });
})();
</script>'''

style_inject = '''
#__topbar{position:fixed;top:0;left:0;right:0;z-index:99999;background:#0f172a;color:#cbd5e1;font-size:11px;text-align:center;padding:6px 8px;font-family:-apple-system,'Apple SD Gothic Neo',sans-serif;letter-spacing:.3px;line-height:18px;transition:background .15s,color .15s}
#__topbar.pulling{background:#1e40af;color:#fff}
#__topbar.refreshing{background:#2563eb;color:#fff}
body{padding-top:30px !important}
'''

body_inject = '<div id="__topbar">\U0001F4C5 마지막 업데이트: ' + build_ts + '''</div>
<script>
(function(){
  var bar = document.getElementById('__topbar');
  if (!bar) return;
  var origText = bar.textContent;
  var startY = 0, pulling = false, ready = false;
  function reset(){ bar.className=''; bar.textContent = origText; }
  document.addEventListener('touchstart', function(e){
    if (window.scrollY <= 0){ startY = e.touches[0].clientY; pulling = true; ready = false; }
  }, {passive:true});
  document.addEventListener('touchmove', function(e){
    if (!pulling) return;
    var dy = e.touches[0].clientY - startY;
    if (dy <= 0){ pulling = false; ready = false; reset(); return; }
    if (dy > 80){
      bar.className='pulling';
      bar.textContent = '↻ 놓으면 새로고침';
      ready = true;
    } else {
      bar.className='';
      bar.textContent = '⬇ 더 당기세요 (' + Math.round(dy) + 'px)';
      ready = false;
    }
  }, {passive:true});
  document.addEventListener('touchend', function(){
    if (!pulling) return;
    pulling = false;
    if (ready){
      bar.className='refreshing';
      bar.textContent='새로고침 중...';
      location.replace(location.pathname + '?t=' + Date.now() + location.hash);
    } else { reset(); }
  });
})();
</script>'''

if re.search(r'<html\b', html):
    html = re.sub(r'<html\b([^>]*)>', lambda m: '<html' + m.group(1) + ' data-build-ts="' + build_ts + '">', html, count=1)
else:
    html = '<html data-build-ts="' + build_ts + '">\n' + html

if re.search(r'<head\b[^>]*>', html):
    html = re.sub(r'(<head\b[^>]*>)', r'\1\n' + head_inject, html, count=1)
else:
    html = head_inject + html

if '</style>' in html:
    html = html.replace('</style>', style_inject + '\n</style>', 1)
else:
    html = re.sub(r'(</head>)', '<style>' + style_inject + '</style>\n\\1', html, count=1)

html = re.sub(r'(<body\b[^>]*>)', r'\1\n' + body_inject, html, count=1)

with open(path, 'w') as f:
    f.write(html)
PYEOF

cd "$REPO_DIR"
git add index.html

if git diff --cached --quiet; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 변경 없음, 스킵"
  exit 0
fi

git commit -m "weekly-brief $(date '+%Y-%m-%d')"

if ! git push origin main; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') ❌ push 실패 (commit은 로컬에 남아 있음, credential 확인 필요)" >&2
  exit 2
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') ✅ push 완료 (빌드 $BUILD_TS)"
