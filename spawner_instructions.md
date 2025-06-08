# to use the spawner

1. customize the model (if necessary)
```
export ANTHROPIC_BASE_URL="https://llm.proxy"
export ANTHROPIC_AUTH_TOKEN="some-api-key"
```

2. start `claude` (inside vscode)
3. run `/project:spawn`

After the tasks are started, it is important to actually observe the virtual terminals since they will likely wait for the operator to answer questions. The first time a new claude session is started, claude will wait for
```
tmux attach -t visual-interface
```

With the tmux open in different terminals, it's possible to see when tasks are completed. In the main terminal (the spawner), you can write:
```
what is the status of the tasks?
```
and the main session will check what is happening in the tasks, and carry on from there.


# Basic workflow

Start
* write what this project is about in the README.md file
* Write a high level list of tasks that should be done.
* Launch claude
* start /project:spawn
// when terminals are started, check them since they might/will be stuck on the intial screen

Loop
* Ask claude "what is the status of the sessions?". it will go through the terminals and take action if needed
* if some of the tasks are completed, it's a good opportunity to `/clear` the session, then start `/project:spawn` again.
* Claude will then pick any remaining tasks and work on them.

When all the tasks are completed
* `/clear` the claude session one more time
* start `/project:spawn`. Claude will see that all the tasks are completed and will clean up the project. Some manual prompting might be necessary, especially if you see Claude trying to copy the files manually. Worktrees are used, they should be merged back, not copied.
