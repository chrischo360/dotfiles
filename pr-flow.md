I only really want this command to be /pr. It should just be global and use the right command or a default if the repo doesnt have specific instructions.

/pr command 
Q: What would you like to do?

-> pr-create

    -> pr-check (minimal formatting + lints) (pr-lint)

    -> git commits (part of pr-create but should be its own command)
        -> check that branch is correct (should have a ph-___)

    -> Build the branch (Ideally just change effected lib but use cached main etc) (pr-build)

    -> Create PR title + description (pr-template)

    -> Push changes + Create PR (pr-push)

        -> Update template with the output from pr-template

            -> Monitor Changes (pr-watch? )
                
                -> If buildkite/github dependencies are failing, NOTIFY -> Then take a look at what is going wrong and create a plan to fix it. And give the user that plan

                    -> could be: pr-check (format, build, codegen, etc) (Not necessary)
