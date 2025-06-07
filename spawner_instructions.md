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