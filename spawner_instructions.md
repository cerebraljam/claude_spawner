# to use the spawner

This takes for granted that you followed the preparation steps in `README.md`, and you now have a `PROJECT_CLEAN.md`, `SPECS.md` and `TASKS.md` file.

**IMPORTANT**: commit `PROJECT_CLEAN.md`, `SPECS.md` and `TASKS.md` to the main branch. Every file that should follow along should also be committed to the main branch. 
**WHY**: `git worktree` is used to create isolated parallel environments. All development is done from a clean `main` branch.


## SETUP
1. Configure your Claude proxy environment variables, if applicable.

Create a `.env.claude` file in the main project directory (already in `.gitignore`):

```bash
# .env.claude file - NOT committed to git
ANTHROPIC_BASE_URL=https://llm.proxy
ANTHROPIC_AUTH_TOKEN=your-anthropic-api-key
```

The `spawn.sh` script will automatically load variables from the `.env.claude` file and pass them to all spawned agent sessions.


2. Start Visual Studio Code (to better keep track of changes).
3. Load your environment variables: `source .env.claude`
4. start `claude`

## START TO WORK ON THE PROJECT

5. run `/spawn`

After the tasks are started, it is important to actually observe the virtual terminals since they will likely wait for the operator to answer questions. The first time a new claude session is started, claude might start by asking to confirm something. In a different terminal, run:
```
tmux attach -t [session name]
```

With the tmux open in different terminals, it's possible to see when tasks are completed. In the main terminal (the spawner), you can write:
```
what is the status of the tasks?
```
and the main session will check what is happening in the tasks, and carry on from there.

## Loop

* Ask claude "what is the status of the sessions?". it will go through the terminals and take action if needed
* if some of the tasks are completed, it's a good opportunity to `/clear` the session, then start `/spawn` again.
* Claude will then pick any remaining tasks and work on them.

## When all the tasks are completed
* `/clear` the claude session one more time
* start `/spawn`. Claude will see that all the tasks are completed and will clean up the project. Some manual prompting might be necessary, especially if you see Claude trying to copy the files manually. Worktrees are used, they should be merged back, not copied.
