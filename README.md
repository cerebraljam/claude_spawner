# One Claude to Spawn Them All

After seeing [this video from @AICodeKing on youtube](https://www.youtube.com/watch?v=bWKHPelgNgs), I was wondering how well it would work for real.

The issue that I had with using Claude Code (or cline, or cursor, or github copilot, or gemini code assist), is that the context window was getting filled too quickly with all the output, and when it was time to compact the window, Caude had already forgotten what it was supposed to do.

That video was already demonstrating something I wanted to work on, so I gave it a try.

The advantages:
* The spawner (coordinator) agent have less output to handle, so keeping track of what was the goal is easier
* Sub tasks are targeted, isolated into a git worktree, and limited in scope, which allow that sub agent to focus on just one objective.
* Once a task is completed, it can be merged back in the main branch, then the spawner can continue with remaining tasks

The disadvantages:
* Claude, especially tmux sessions need to be monitored because they can get stuck. There are some weird behaviours where claude code ask to authenticate again, or forgot about granted permissions, etc.
* The spawner isn't (always) going to monitor these terminal to know if they are done. that being said, I did see it do "sleep 30 && tmux capture-pane`, so it is able to wait and continue if it feels like it.

After rounding some corners, I could get a full project running while just babysitting Claude while it was doing the job.

This version is more complex than the original idea. I wanted to try it to build bigger projects than simple apps that could likely be one-shotted by Gemini and it's 1M token context window.

# How to use:

## Define your project
* In `PROJECT.md`, describe your project. These can be notes explaining what the project is about.
* Run `/review_project`. this will execute the `.claude/commands/review_project.md` prompt. This prompt will look at `PROJECT.md` and try to create a `PROJECT_CLEAN.md` file that includes a mermaid diagram of the flow of the application.
* Claude will mention if there is anything that requires more details. Take these questions, paste them at the end of `PROJECT.md` and answer them.
* Repeat, until all questions are answered.

## Define the specs:
* Run `/create_specs`. This will execute the `./claude/commands/create_specs.md` prompt. This will create a `SPECS.md` that lists all the functions needed for that app. It will also create mermaid diagrams of the data flow and function calling. 
* Claude will mention if there is anything that is missing or unclear. Take these missing points, paste them at the end of `PROJECT.md` and answer them. Go back to running `/review_project`.
* Repeat, until all questions are answered.

## Generate Tasks
* Run `/create_tasks`. This will execute the `./claude/commands/create_tasks.md` prompt.
* Review `TASKS.md` to ensure they look alright

## Start creating the app
* Read `README-instructions.md` first for instructions on how to configure and manage the spawned agents.
* Run `/spawn-coder`. This will execute the `./claude/commands/spawn-coder.md` prompt.
* Babysit the tmux sessions and the code creation. For that, you can use `bash attach.sh` in a different terminal. and it will attach automatically when a new session is spawned.




