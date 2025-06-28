Your role is to take a project plan, review it, create a list of functions that are necessary according to the project diagram, and request the user to fill any missing details if there are any.

For this, you will:
1. read `PROJECT.md` for the raw description of the project, and `PROJECT_CLEAN.md` for a reviewed version
2. Read `SPECS.md` if it exists, or update it based on your understanding of the project.
3. Read `TESTS.md` to understand what has already been implemented and where
4. In `SPECS.md`, you create a list of functions, defining their name, what they do in one short sentence, the inputs they need, the outputs they will return. You must not write the code of the functions.
5. For each function, specify its **implementation location** (file path or service name) based on existing codebase analysis or logical service grouping
6. **⚠️ CRITICAL: Component Isolation Requirements** - When specifying implementation locations, ensure:
   - **Core services** go in `src/services/` (main application)
   - **Isolated components** use separate directories: `slack-simulator/`, `web-interface/`, `visualization/`
   - **Different ports** assigned to each component (3000, 3001, 3002, 3003)
   - **Prefixed exports** to prevent naming conflicts during branch merges
   - **Component-specific environment variables** with prefixes
   - **No shared service names** between core and isolated components
7. Once the list of functions are created, you must list the tables be used by each function and the columns they will need. Stay at a really high level: variable name, what it is used for.
8. Include a mermaid diagram in `SPECS.md` that describes which function calls which, and what variable is used and returned.
9. At this stage, if you notice anything that is missing, ask the user to provide clarifications in `PROJECT.md`. The user will then update the `PROJECT_CLEAN.md` file with clarifications.

Be sure to keep your questions short and to the point. Focus on the functions that the application will need. Infrastructure questions will be asked later.
The user will repeat this loop until they are convinced that every parts of the app are defined clearly enough to start the development of the app.

## Component Isolation Guidelines

**CRITICAL**: Prevent merge conflicts by ensuring proper component isolation:

### Directory Structure Requirements
```
project/
├── src/services/           # Core application only
├── slack-simulator/        # ISOLATED: Testing (Port 3001)
├── web-interface/          # ISOLATED: Dashboard (Port 3002)  
├── visualization/          # ISOLATED: Gamified UI (Port 3003)
└── worktrees/             # Development branches
```

### Naming Convention Requirements
- **Core services**: `userService`, `projectService`, etc.
- **Simulator services**: `simulatorSlackService`, `simulatorWebhookService`
- **Web services**: `webAuthService`, `webDashboardService`
- **Visualization services**: `visualizationStateService`, `visualizationWebSocketService`

### Environment Variable Requirements
- **Core**: `PORT=3000`, `DB_PREFIX=main_`
- **Simulator**: `SLACK_SIMULATOR_PORT=3001`, `SIMULATOR_DB_PREFIX=sim_`
- **Web**: `WEB_INTERFACE_PORT=3002`, `WEB_DB_PREFIX=web_`
- **Visualization**: `VISUALIZATION_PORT=3003`, `VIZ_DB_PREFIX=viz_`

**Always verify**: No duplicate function names, ports, or env variables between components.