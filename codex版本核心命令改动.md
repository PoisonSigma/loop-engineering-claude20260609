Codex 版已生成。四个核心改动：

|                    Claude |                            Codex                             |
| ------------------------: | :----------------------------------------------------------: |
|         `claude -p "..."` |                      `codex exec "..."`                      |
|    `--allowedTools "..."` | `--sandbox workspace-write`（无逐工具白名单，靠 sandbox 模式 + `.rules`） |
|          `--max-turns 15` |       外层 `timeout 10m`（Codex 无步数/预算上限标志）        |
| `.claude/skills/SKILL.md` |                `AGENTS.md`（项目根，自动读）                 |

`loop.sh` 直接照抄即可跑。文件开头有完整命令对照表，对你笔记里每条命令都一一对应。
