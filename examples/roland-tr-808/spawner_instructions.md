# to use the spawner

1. customize the model
```
export ANTHROPIC_BASE_URL="https://llm.proxy"
export ANTHROPIC_AUTH_TOKEN="some-api-key"
```

2. start `claude` (inside vscode)
3. run `/project:spawn`

After the tasks are started, it is important to actually observe the virtual terminals since they will likely wait for the operator to answer questions
```
tmux attach -t visual-interface
```

With the tmux open in different terminals, it's possible to see when tasks are completed. In the main terminal (the spawner), you can write:
```
what is the status of the tasks?
```
and the main session will check what is happening in the tasks, and carry on from there.