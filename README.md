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