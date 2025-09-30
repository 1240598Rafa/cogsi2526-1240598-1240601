Clone of Petclinic to CA1 : 

1 - git clone https://github.com/spring-petclinic/spring-framework-petclinic.git
2 - Remove .git folder
3 - Commit to Main : 
- "git add ."
- "git commit -m "Add Petclinic to CA1"
- "git push"

Tag Versions : 
git tag 1.1.0
git push origin 1.1.0
git tag v1.2.0
git tag ca1-part1 452b615
git push origin ca1-part


Git Log (git log --pretty=format:"%h | %ae | %ad | %s" --date=short) -> sha | Contributors | Date | Commit message
452b615 | xavier.ricarte@gmail.com | 2025-09-27 | Revert "Commit to revert"
8120c17 | xavier.ricarte@gmail.com | 2025-09-27 | Commit to revert
02514e9 | xavier.ricarte@gmail.com | 2025-09-27 | Added license column : updated -> Class | Schema | JSP
4e878e6 | xavier.ricarte@gmail.com | 2025-09-27 | Add Petclinic to CA1
726e870 | 1240598@isep.ipp.pt | 2025-09-18 | Organizar projeto em /CA0
3e36e80 | 1240598@isep.ipp.pt | 2025-09-18 | Organizar projeto em /CA0 conforme enunciado
fb5d4f1 | 1240598@isep.ipp.pt | 2025-09-18 | CA0: Adicionar Campo NIF ao Owner
5ac41b8 | 1240598@isep.ipp.pt | 2025-09-18 | Initial commit

Git Revert : 
git revert 452b615(sha)
git push

Default Branch (git remote show origin | Select-String 'HEAD branch') :
    HEAD branch: main

Last Commit (git log -1 --date=iso --pretty=format:'%H %cd')
452b6158dc7cdb934e1d8f81b2bf729b2963cc85 2025-09-27 21:44:32 +0100

## Part 2 - Branches Workflow

# New branch:
git checkout -b email-field

New email field added to the Vet Class

# Commit of the new feature:
git commit -m "Add email field to Vet"

# Merge feature with main branch:
git checkout main
git merge email-field
git push origin main

# New tag for this version:
git tag v1.3.0
git push origin v1.3.0

# Conflit test:
git checkout -b email-field
#Change file

git checkout -b main

#Change file in different way

#Try to commit each branch and merge after:
git checkout main
git merge main
git merge email-field

error: Merging is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.

This demonstrates how Git forces developers to manually reconcile differences.

# Branch Tracking:
(Which local branch is configured to track which remote branch?)
git branch -vv
  email-field aa67be6 Add email field to Vet
* main        aa67be6 [origin/main] Add email field to Vet

The main branch tracks the remote branch origin/main, while the email-field branch tracks the branch origin/email-field

# Final Tag:
git tag ca1-part2
git push origin ca1-part2

tags were created following a semantic versioning style (major.minor.revision) to clearly mark project states.

## Alternative Solutions:
# Analysis
Aside from Git, there are alternative version control systems for managing source code evolution. 
The next closest alternatives are Subversion (SVN), Mercurial (Hg), and Fossil. 
These tools all have history-tracking functionality, version management, and team collaboration support among developers.

# Comparing to Git:
Git is a distributed version control system where every clone contains the whole history. 
This gives it great power for branching and merging but also makes it harder to learn. 
It's now the industry standard, with wide adoption, excellent scalability, and close integration with services like GitHub, GitLab, and Bitbucket.

Subversion (SVN) is a centralized system, and thus all history is maintained on a single server. 
It is easier to learn and operate, yet branching and merging are more sluggish. 
SVN might still be used on this project by hosting a central repository where students check out code, make changes, and commit back to the server.

Mercurial (Hg) is also widely available, like Git, but with simplicity of commands as the priority. 
It could be used as a near drop-in substitute for Git since it supports commits, branching, and merging. 
However, these days it has much less adoption and integration compared to Git, so it is less attractive to use in the longer term.

Fossil is another distributed tool that stands out by being a single executable that also has a built-in wiki, bug tracker, and web interface. 
It is very lightweight and portable, as the entire repository is stored in a single SQLite database file. 
In this project, Fossil can be used by initializing a .fossil repository, opening it locally, and making commits to track the history of the PetClinic application. 
Branches can be created to isolate features, reintegrated into the trunk once more, and examined directly through Fossil's built-in web interface.


# Why Fossil as Alternative

Fossil was chosen for implementation because it is lightweight, portable, and provides an all-in-one solution (VCS, wiki, issue tracking, and web interface) 
in a single binary, making it the simplest alternative to set up and demonstrate within the scope of this assignment. Git remains the most suitable tool for larger 
collaborative projects due to its popularity and ecosystem.

cd c:\fossil\CA1-fossil\
fossil init petclinic-ca1.fossil
project-id: 7936b031d0c39a558ad8dbef238093d049f0262a
server-id:  02c68bd90d763a06e2330c5a936748f44dac91ea
admin-user: rafa (initial remote-access password is "*****")
mkdir work
cd work
fossil open ..\petclinic-ca1.fossil
project-name: <unnamed>
repository:   C:/fossil/CA1-fossil/petclinic-ca1.fossil
local-root:   C:/fossil/CA1-fossil/work/
config-db:    C:/Users/rafa/AppData/Local/_fossil
project-code: 7936b031d0c39a558ad8dbef238093d049f0262a
checkout:     3cb5e1dcd20ef0b8b702198ce2a519ca5aac3aa3 2025-09-29 20:36:50 UTC
tags:         trunk
comment:      initial empty check-in (user: rafa)
check-ins:    1
Copy-Item -Recurse C:\Users\rafa\Desktop\ISEP\COGSI\cogsi2526-1240598-1240601\CA1\*
fossil add .
fossil commit -m "Initial Import of Petclinc"
fossil branch new email-field
fossil commit -m "Add email field to Vet"
fossil update trunk
-------------------------------------------------------------------------------
checkout:     80a90bb338642b896f3b47154897a1b9eb307938 2025-09-29 20:38:18 UTC
tags:         trunk
comment:      Initial Import of Petclinc (user: rafa)
changes:      None. Already up-to-date.
fossil merge email-field
fossil commit -m "Merge branch email-field"

fossil timeline
=== 2025-09-29 ===
20:38:18 [80a90bb338] *CURRENT* Initial Import of Petclinc (user: rafa tags: trunk)
20:36:50 [3cb5e1dcd2] initial empty check-in (user: rafa tags: trunk)
+++ no more data (2) +++

Fossil successfully managed the same workflow: project import, branching, merging, and history visualization.

## Self-Evaluation

Rafael Ferreira(1240598): 50%
Xavier Ricarte(1240601): 50%