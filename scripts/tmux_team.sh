#!/bin/bash
# 락인 포커스 팀 시각화 세션
# 각 window = 한 팀원의 역할. 실제 작업은 Claude Code의 Agent 도구가 병렬 실행.
# 이 세션은 진행상황을 한눈에 보기 위한 용도.

SESSION="lockin-focus"
ROOT="/Users/kjmoon/Lockin Focus"

tmux kill-session -t "$SESSION" 2>/dev/null

tmux new-session -d -s "$SESSION" -n "leader" -c "$ROOT"
tmux send-keys -t "$SESSION:leader" "clear; echo '[팀리더 / Architect / Team Lead]'; echo '역할: UX/UI 총괄 · 통합 · 최종 판단 · process.md · Git 커밋'; echo; echo '--- 최근 프로세스 로그 ---'; tail -n 40 process.md" C-m

tmux new-window -t "$SESSION" -n "ux" -c "$ROOT"
tmux send-keys -t "$SESSION:ux" "clear; echo '[UX 설계자]'; echo '산출물: docs/02_UX_Design.md'; echo; ls -la docs/ 2>/dev/null" C-m

tmux new-window -t "$SESSION" -n "architect" -c "$ROOT"
tmux send-keys -t "$SESSION:architect" "clear; echo '[Architect]'; echo '산출물: docs/03_Architecture.md'; echo; ls -la docs/ 2>/dev/null" C-m

tmux new-window -t "$SESSION" -n "coder" -c "$ROOT"
tmux send-keys -t "$SESSION:coder" "clear; echo '[Teammate 1 - Coder]'; echo '역할: Swift/SwiftUI 구현. 컨벤션 준수.'; echo '작업 시작 조건: Architect 설계 요약 완료'" C-m

tmux new-window -t "$SESSION" -n "debugger" -c "$ROOT"
tmux send-keys -t "$SESSION:debugger" "clear; echo '[Teammate 2 - Debugger]'; echo '역할: 코드 점검 · 버그 리포트 · 수정 제안'" C-m

tmux new-window -t "$SESSION" -n "test-review" -c "$ROOT"
tmux send-keys -t "$SESSION:test-review" "clear; echo '[Teammate 3 - Test Engineer + Reviewer]'; echo '역할: 테스트 작성 + 최종 리뷰 (R2/R3 루프)'" C-m

tmux new-window -t "$SESSION" -n "perf-doc" -c "$ROOT"
tmux send-keys -t "$SESSION:perf-doc" "clear; echo '[Teammate 4 - Performance + Doc Writer]'; echo '역할: 성능·최적화 + 최종 문서화'" C-m

tmux new-window -t "$SESSION" -n "tasklist" -c "$ROOT"
tmux send-keys -t "$SESSION:tasklist" "clear; cat Tasklist.md" C-m

tmux select-window -t "$SESSION:leader"

echo "세션 생성 완료."
echo "접속:   tmux attach -t $SESSION"
echo "윈도우: leader / ux / architect / coder / debugger / test-review / perf-doc / tasklist"
echo "윈도우 이동: Ctrl-b 숫자(0~7) 또는 Ctrl-b n/p"
echo "나가기 (세션 유지): Ctrl-b d"
