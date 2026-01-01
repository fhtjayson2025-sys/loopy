---
description: "Cancel active Loopy loop"
allowed-tools: ["Bash"]
---

# Cancel Loopy

```!
if [[ -f .claude/loopy-loop.local.md ]]; then
  ITERATION=$(grep '^iteration:' .claude/loopy-loop.local.md | sed 's/iteration: *//')
  echo "FOUND_LOOP=true"
  echo "ITERATION=$ITERATION"
else
  echo "FOUND_LOOP=false"
fi
```

Check the output above:

1. **If FOUND_LOOP=false**:
   - Say "No active Loopy loop found."

2. **If FOUND_LOOP=true**:
   - Use Bash: `rm .claude/loopy-loop.local.md`
   - Report: "Cancelled Loopy loop (was at iteration N)" where N is the ITERATION value from above.
