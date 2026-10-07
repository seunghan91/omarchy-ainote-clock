# ainote 시계 (Omarchy)

Omarchy 상단 바 가운데 시계를 애플식 한국어 표기로 바꾸고,
달력 패널에서 ainote 할일을 보고·완료하고·추가하는 셸 플러그인.

```
10월 7일(수) 오후 1:56
```

- 기본 시계 `omarchy.clock` 자리를 그대로 대체한다(`omarchy.clonedFrom`). 단축키(Super+Ctrl+Alt+D)·IPC 도 따라온다.
- 달력: 한국어 요일, 일요일 빨강·토요일 파랑, 날짜별 할일 점(밀린 할일은 빨간 점).
- 할일: 오늘을 고르면 `전체 · 오늘 · 밀린` 필터, 밀린 할일은 접고 펼친다. 체크로 완료, 입력칸에 쓰고 Enter 로 추가.
- 로그인: 패널의 「ainote 로그인」 → 브라우저에서 코드 승인(ainote 기기 인증). 할일 API 토큰과 MCP 키를 함께 받는다.

## 설치

```bash
git clone https://github.com/seunghan91/omarchy-ainote-clock.git
cd omarchy-ainote-clock
./install.sh                     # 기본 시계를 대체
./install.sh --uninstall         # 기본 시계로 복귀
./install.sh --uninstall --purge # + 로그아웃·자격 증명 삭제
```

화면이 잠긴 상태에서는 설치하지 않는다(잠금 화면도 셸이다).

## 설정

패널 아래 「설정」에서 고르거나 터미널에서 바꾼다.

| 키 | 값 | 기본 |
|---|---|---|
| `taskIndicator` | `none` · `split`(할일 N · 밀림 N) · `total`(합계) | `none` |
| `panelLayout` | `vertical` · `horizontal` | `vertical` |
| `weekStart` | `sunday` · `monday` | `sunday` |

```bash
omarchy bar set io.github.seunghan91.ainote-clock taskIndicator split
```

## 구조

| 파일 | 역할 |
|---|---|
| `bin/ainote-clock` | 자격 증명과 HTTP 를 다루는 유일한 프로세스(bash·curl·jq). 한 줄 JSON 출력 |
| `TaskStore.qml` | helper 호출, 월별 캐시, 5분 갱신 |
| `BarWidget.qml` · `Panel.qml` · `KoDate.js` | 바 라벨, 달력·할일·설정 화면, 한국어 날짜 |
| `install.sh` | 설치·원복(가운데 고정 `bar.centerAnchor` 포함) |

자격 증명은 `~/.config/ainote-clock/credentials.json`(0600)에만 있다. 토큰은 프로세스 인자·로그·shell.json 에 남지 않는다.
에이전트는 같은 로그인으로 MCP 를 쓸 수 있다.

```bash
echo '{"action":"tasks","due_today":true}' | bin/ainote-clock mcp-call tasks_read
```

## 테스트

```bash
TZ=Asia/Seoul bash tests/helper/run.sh   # helper, 로컬 가짜 서버(실서버 응답 형식 반영)
node tests/kodate.test.mjs               # 날짜 표기
bash tests/normalize.test.sh             # 마감일 날짜 분류
```

## 크레딧

달력 패널 구조는 Omarchy 기본 시계(`shell/plugins/panels/clock`, MIT)를 바탕으로 했다.
