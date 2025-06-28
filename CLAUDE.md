
# Context

Start by reading @PROJECT_CLEAN.md to understand what the project is about.
Then read @TASKS.md to understand what has to be done, and what was done.

# Coding Practices

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
* When doing `git add`, list the files to be added by name. Do not use `git add .` since they could include junk in the repository.
* If temporary folders, cache folders or any file or directory are added and shouldn't be included in a commit, add them to `.gitignore`

## When coding with nodejs

### Bash commands
- npm run build: Build the project
- npm run typecheck: Run the typechecker

### Code Style
- Use ES modules (import/export) syntax, not CommonJS (require)
- Destructure imports when possible (eg. import { foo } from 'bar')
- Write elegant and small functions. Minimize the code size as much as possible.

### Workflow
- Be sure to typecheck when you’re done making a series of code changes


# Summary instructions

When you are compacting your memory, use the following strategy:
* Keep the user's messages
* keep all of your messages to the users (especially hypothesis and conclusions)
* for tool execution, code written, etc. include in a one line that it was done, but do not include the content.
* At the end, if knowing the content of a file or the output of a tool execution is critical to continue, take a note to read or execute the tool again once.
* If the context window isn't going to be sufficiently reduced using that strategy, focus on high value messages and ignore rambling.
* Be sure to keep the goal of the project well detailed in the context.
* If some details should be remembered but keeping them in the context window would take too much space, save them into the @MEMORY.md file.