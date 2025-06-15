# One Claude to Spawn Them All

After seeing [this video from @AICodeKing on youtube](https://www.youtube.com/watch?v=bWKHPelgNgs), I was wondering how well it would work for real.

The issue that I had with using Claude Code (or cline, or cursor, or github copilot, or gemini code assist), is that the context window was getting filled too quickly with all the output, and when it was time to compact the window, Caude had already forgotten what it was supposed to do.

That video was already demonstrating something I wanted to work on, so I gave it a try.

The advantages:
* The spawner (coordinator) agent have less output to handle, so keeping track of what was the goal is easier
* Sub tasks are targeted, isolated into a git worktree, and limited in scope, which allow that sub agent to focus on just one objective.
* Once a task is completed, it can be merged back in the main branch, then the spawner can continue with remaining tasks

The disadvantages:
* Claude, especially tmux sessions need to be monitored because they can get stuck.
* The spawner isn't (always) going to monitor these terminal to know if they are done. that being said, I did see it do "sleep 30 && tmux capture-pane`, so it is able to wait and continue if it feels like it.

After rounding some corners, I could get a full project running while just babysitting Claude while it was doing the job.

# How to use:

* See `spawner_instructions.md` for instruction
* See `.claude/commands/spawn.md` for the prompt

# Examples

* See `examples/` for a full examples of completed projects using this workflow



