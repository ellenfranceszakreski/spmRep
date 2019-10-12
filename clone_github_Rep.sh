#!/bin/sh
# ./clone_github_Rep.sh <RepositoryName> clone github files to CIC directory Github (on analysis path)
# get code from github repository
# e.g. ./clone_github_Rep.sh spmRep

AnalysisDir=/data/scratch/zakell/fmri_oct2019 # make sure this is correct (name should not have any spaces)

if [ "$#" -ne 1 ]; then
  echo "error:Incorrect number of inputs"
  echo "usage:./clone_github_Rep.sh <RepositoryName>"
  exit 1
fi
RepositoryName=$1
echo "Cloning from $RepositoryName"

# make Scripts directory if one does not already exist
test ! -d $AnalysisDir/Scripts && mkdir $AnalysisDir/Scripts
GithubDir=$AnalysisDir/$RepositoryName"_Github"

# remake Github directory
test -d $GithubDir && rm -r $GithubDir
mkdir $GithubDir

# clone github files
git clone https://github.com/ellenfranceszakreski/$RepositoryName --depth 1 --branch=master $GithubDir

# make scripts executable and easy to delete (github sets access of files clones to read only)
chmod -R 777 "$GithubDir"

# show new files
echo "New files:"
ls -l $GithubDir

# print instructions for moving to Scripts directory
printf "\n\nTransfer done. When ready, enter commands below:\n"
printf "cd %s\n" "$AnalysisDir"
printf "mv -v %s/* Scripts\n\n" $RepositoryName"_Github"
unset GithubDir AnalysisDir
exit 0
### DONE
