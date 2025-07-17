Your role is to take the `SPECS.md` file, and create a list of tasks that coder agents will need to complete using **Foundation-First Development** principles.

## Foundation-First Task Creation Requirements

**CRITICAL**: All tasks must follow foundation-first development order to prevent "big bang" failures:

### Layer Dependencies Order:
1. **Database + Basic CRUD** (test with direct calls)
2. **HTTP endpoints** (test with curl/Postman)  
3. **Integration layers** (test with simulators)
4. **Basic user workflows** (test end-to-end)
5. **Core business logic** (test each feature completely)
6. **Advanced features** (only after foundation is solid)

### Task Structure Requirements:
- **One task per foundation layer** - cannot skip layers
- **Each task must be testable in isolation** - no dependencies on unimplemented features
- **Include explicit test criteria** for each task
- **Foundation validation required** between layers
- **Manual end-to-end testing** must be possible for each task

## Task Creation Process

To achieve this goal:
1. Read the `PROJECT.md`, `PROJECT_CLEAN.md` and `SPECS.md` files.
2. **Identify foundation layers** from the specs - what's the absolute minimum that must work first?
3. **Order tasks by dependency layers** - lower layers must be completed before higher layers
4. Create tasks that follow the `SPECS.md` file but **enforce foundation-first order**
5. If infrastructure needs to be configured, create a `INFRA.md` file with clear step-by-step instructions. This can include installing frameworks, docker, databases, etc.
6. Create the `TASKS.md` file. If it exists, update it. DO NOT number the lines for each task.

### Task Writing Rules:
- **Each task = one foundation layer or isolated feature**
- **Include test criteria**: "Task complete when X can be tested via Y method"
- **No forward dependencies**: Task cannot rely on features not yet implemented
- **Real-world testable**: Each task must be demonstrable with actual usage

* I Repeat: **DO NOT number the lines for each task.**

### Foundation Test Integration:
- **Update `foundation-test.sh`** as new layers are added
- Each task should specify: "Update foundation-test.sh to validate this layer"
- **Foundation must pass** before moving to next layer
- Tasks that fail foundation validation cannot be marked complete

### Example Foundation-First Task Structure:
```
**Layer 1: Database Foundation**
Create database connection and basic CRUD operations - Task complete when direct database queries work via Node.js script

**Foundation Test Update**  
Update foundation-test.sh to test database connection and basic operations - Foundation test must pass before proceeding

**Layer 2: HTTP Foundation**
Create basic HTTP server with health endpoint - Task complete when curl requests to /health return 200

**Foundation Test Update**
Update foundation-test.sh to test HTTP server startup and health endpoint - Foundation test must pass before proceeding

[Continue with remaining layers...]
```

A task spawner will read this `TASKS.md` file and launch coding agents to complete each of them independently. The task spawner will be aware of the content of `SPECS.md` and their own task.