# Context

Start by reading @PROJECT_CLEAN.md to understand what the project is about.
Then read @TASKS.md to understand what has to be done, and what was done.
Read @SPECS.md to understand how the application should be organized.
Read @TASK-USER-STORY.md to understand how the app will be used.

# Coding Practices

## Foundation-First Development Requirements

By foundation-first, I mean to simulate how a normal developer would build an app: start by the foundation parts first, then build on top of this. For example: decision logic code for a workflow relying on user messages shouldn't be started before being able to confirm that we can receive user messages.

Before implementing any task, ensure:
1. **Layer Dependencies**: Lower layers must be completed and tested first
2. **Integration Tests**: Each layer must have working integration tests
3. **User Journey Validation**: Core workflows must be tested end-to-end
4. **Minimal Dependencies**: Each component should have minimal external dependencies

### Development Order Enforcement:
1. Database + Basic CRUD (test with direct calls)
2. HTTP endpoints (test with curl/Postman)
3. Basic user registration/login (test end-to-end)
4. Core workflows one at a time (test each completely)
5. Advanced features only after foundation is solid

### Task Completion Criteria:
- Code written
- Unit tests passing
- Integration tests passing
- **Foundation validation checklist still passes after changes**
- **Manual end-to-end test demonstrating the feature works**
- **Feature can be tested in isolation** (no dependencies on unimplemented features)
- Documentation updated

### Foundation Test Execution Rules:

**CRITICAL**: Foundation tests in `./foundation-tests/` are designed as sequential database migrations. Tests scripts must be executed sequentially, but a single test must be executable over and over again if necessary:

✅ **CORRECT**: `./foundation-test.sh` or `./foundation-test.sh --quiet` or `./foundation-test.sh --force`
✅ **CORRECT**: after executing precedent tests, `./foundation-tests/015_proxy_response_generation_foundation.sh` for example, from main branch

A clean-up script should be created in ./foundation-tests/ and be called `9999_cleanup.sh`. This script will be executed by to stop any services starting the tests.

Individual tests must start by importing `test-utils/common.sh`, `test-utils/service-manager.sh` (should be modified to match the architecture of the project).
Each test must start by listining which components are necessary for the test to work, by including something like:
```
# Ensure required services are running
source "$(dirname "$0")/../test-utils/service-manager.sh"
if ! ensure_foundation_dependencies "database" "http_server"; then
    exit 1
fi
```
Ensure that test scripts are following a consistent format.

**When debugging test failures**: Use `./foundation-test.sh --quiet` to see only failing tests, then examine the specific test code.

### Validation Philosophy:
- **Fail Fast**: If a foundational layer doesn't work, stop and fix it before proceeding
- **Test Everything**: Every function should be testable individually. If a prerequisite is necessary (from a previous test), it should test to confirm that it was executed, or ask the previous test to be executed to performe the necessary actions.
- **Real-World Testing**: Use realistic test data and scenarios, not just happy paths
- **Integration Confidence**: Each layer must work with the layers below it
- **Regression Prevention**: New changes must not break existing functionality

## TDD Practices

* Follow Test Driven Development (TDD) practices. 
    * Write tests based on expected input/output pairs.
    * When writing tests, split the tasks in smaller parts instead of trying to write them all all at once.
    * Run the tests and confirm they fail.
    * Commit the tests when all the tests are written.
    * Write code that passes the tests.
    * Ensure that the code isn't overfitting or cheating the tests.
    * Prefer running single tests, and not the whole test suite, for performance
* Keep files small. 
* Keep the functions small and elegant. Keep in mind the goals of the project when writing code.
* Use types variables.


## About Git
* When doing `git add`, list the files to be added by name.
* If temporary folders, cache folders or any file or directory are added and shouldn't be included in a commit, add them to `.gitignore`


## When coding with nodejs

### Bash commands
- use package.json to configure repeatable commands

### Code Style
- Use ES modules (import/export) syntax, not CommonJS (require)
- Destructure imports when possible (eg. import { foo } from 'bar')
- Write elegant and small functions. Minimize the code size as much as possible.

### Deep dive
- When you are running in a tmux session, you are allowed to use sub processes (`claude -p "prompt") to launch instances of claude code that will analyze or fix a specific issue. Be clear in your explanations of the problem and instructions to fix it.


# Summary instructions

When you are compacting your memory, use the following strategy:
* Keep the user's messages
* keep all of your messages to the users (especially hypothesis and conclusions)
* for tool execution, code written, etc. include in a one line that it was done, but do not include the content.
* At the end, if knowing the content of a file or the output of a tool execution is critical to continue, take a note to read or execute the tool again once.
* If the context window isn't going to be sufficiently reduced using that strategy, focus on high value messages and ignore rambling.
* Be sure to keep the goal of the project well detailed in the context.