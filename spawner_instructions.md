# to use the spawner

1. Replace the content of `PROJECT.md` file with a description of your project
2. Describe the tasks to work on in `tasks.md`.

**IMPORTANT**: commit `PROJECT.md` and `tasks.md` to the main branch. `git worktree` is used to create isolated parallel environments. All development is done from a clean `main` branch.

3. Configure your secrets and environment variables

**IMPORTANT**: Never commit API keys or secrets to git. Use one of these approaches:

**Option A: Environment Variables (Recommended)**
```bash
export ANTHROPIC_BASE_URL="https://llm.proxy"
export ANTHROPIC_AUTH_TOKEN="your-anthropic-api-key"
export SLACK_BOT_TOKEN="xoxb-your-slack-bot-token"
export SLACK_SIGNING_SECRET="your-slack-signing-secret"
export DATABASE_URL="postgresql://user:pass@localhost:5432/dbname"
export OPENAI_API_KEY="your-openai-key"  # if using OpenAI as LLM backend
```

**Option B: .env File (Recommended)**
Create a `.env` file in the main project directory (already in .gitignore):
```bash
# .env file - NOT committed to git
ANTHROPIC_BASE_URL=https://llm.proxy
ANTHROPIC_AUTH_TOKEN=your-anthropic-api-key
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_SIGNING_SECRET=your-slack-signing-secret
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
OPENAI_API_KEY=your-openai-key
```

The spawn.sh script will automatically load variables from the .env file and pass them to all spawned agent sessions.

4. start Visual Studio Code (to better keep track of changes)
5. start `claude`
6. run `/project:spawn`

After the tasks are started, it is important to actually observe the virtual terminals since they will likely wait for the operator to answer questions. The first time a new claude session is started, claude might start by asking to confirm something. In a different terminal, run:
```
tmux attach -t [session name]
```

With the tmux open in different terminals, it's possible to see when tasks are completed. In the main terminal (the spawner), you can write:
```
what is the status of the tasks?
```
and the main session will check what is happening in the tasks, and carry on from there.



# Basic workflow

## Start
1. write what this project is about in the `PROJECT.md` file.
2. Write a high level list of tasks that should be done in `tasks.md` (or ask claude to do it).
3. Commit `PROJECT.md` and `tasks.md` to the `main` branch.
4. Launch `claude` inside Visual Studio Code
5. start `/project:spawn` in claude code

Note: when terminals are started, check them since they might/will be stuck from time to time.

## Loop
* Ask claude "what is the status of the sessions?". it will go through the terminals and take action if needed
* if some of the tasks are completed, it's a good opportunity to `/clear` the session, then start `/project:spawn` again.
* Claude will then pick any remaining tasks and work on them.

## When all the tasks are completed
* `/clear` the claude session one more time
* start `/project:spawn`. Claude will see that all the tasks are completed and will clean up the project. Some manual prompting might be necessary, especially if you see Claude trying to copy the files manually. Worktrees are used, they should be merged back, not copied.
