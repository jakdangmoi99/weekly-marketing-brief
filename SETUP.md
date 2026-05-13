# Weekly Marketing Brief — GitHub Pages 자동 배포

## 구조
- **repo**: jakdangmoi99/weekly-marketing-brief (public)
- **Pages URL**: https://jakdangmoi99.github.io/weekly-marketing-brief/
- **소스 HTML**: `~/Documents/Claude/Projects/조비스/마케팅_브리핑/마케팅_브리핑_아카이브.html`
- **배포 스크립트**: `~/push_weekly_brief.sh`
- **로그**: `~/push_weekly_brief.log`

## 동작 흐름
1. 매주 월요일 09:00~09:10 — 조비스가 마케팅 브리핑 아카이브 HTML 생성/업데이트
2. 매주 월요일 09:15 — crontab이 `push_weekly_brief.sh` 실행
3. 스크립트가 하는 일:
   - 아카이브 HTML → `index.html`로 복사
   - 캐시 무효화 meta 태그 삽입
   - Pull-to-refresh 기능 삽입 (아이폰 홈화면용)
   - git commit & push → GitHub Pages 자동 배포

## crontab
```
15 9 * * 1 /bin/bash /Users/cho-mini/push_weekly_brief.sh >> /Users/cho-mini/push_weekly_brief.log 2>&1
```

## 모바일 사용
아이폰 Safari에서 Pages URL 접속 → 공유 → 홈 화면에 추가
→ 앱처럼 열리고, 당겨서 새로고침 가능

## 세팅 이력
- 2026-05-13: 초기 세팅 완료 (repo 생성, Pages 활성화, 스크립트 작성, crontab 등록, 첫 push 테스트 성공)
