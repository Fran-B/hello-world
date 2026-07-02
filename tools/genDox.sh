#!/bin/bash
#
# Script to generate a what seems like Doxygen or Javadoc documentation
#
STS=0
destDir=$1
curPkg=""
pkgDir=""
pkgFile=""
pkgIndent="          "
indexIndent="        "
curIndent="${indexIndent}"

index="${destDir}/index.html"
#fileId=0
#declare -a files


################
## Checks a result status for error
function checkSts
{
    if [ 0 != $1 ]
    then
        STS=$1
    fi
}

################
## Starts an html file
## requires: file, title
function startHtml
{
    local destFile="$1"
    local title="$2"

cat<<EOF >"${destFile}"
<html>
  <head>
    <style>
      div {
          margin-left: +2em;
          margin-top: -1em;
        }
    </style>
    <title>${title}</title>
  </head>
  <body>
EOF
}

################
## Ends an html file
## requires: file, title
function endHtml
{
    local destFile="$1"

cat<<EOF >>"${destFile}"
  </body>
</html>
EOF
}

################
## Appends lines to an html file
## requires: file, content
#function addToFile
#{
#    local destFile="$1"
#    shift
#
#
#}

################
## Starts the index file
function startIndex
{
    startHtml "${index}" "Documentation Index"

cat<<EOF >>"${index}"
    <h1>Overview</h1>
    <div>
      <p>
        This serves as the top-level index to the documentation tree.
        It only contains an index of available documentation pages.
      </p>
      <h2>Page Index</h2>
      <div>
EOF
indent="${indexIndent}"
}

################
## Ends the index file
function endIndex
{
cat<<EOF >>"${index}"
      </div>
    </div>
EOF
    endHtml "${index}"
}

################
## Adds a page reference to the index file
## arg-1 is path relative to index to use as href
## arg-2 is optional page identifier; default is arg-1
function addPageToIndexFile
{
    local pageFile="$1"
    local page="$2"
    local href="${pageFile}"
    if [ "" == "${page}" ]
    then
        page="${pageFile}"
    fi
    echo "${curIndent}<br/><a href=\"${href}\">${page}<a>">>"${index}"
}

################
## Adds a page reference to the current package file
## arg-1 is path relative to package to use as local href
## arg-2 is optional page identifier; default is arg-1
function addPageToPackage
{
    local pageFile="$1"
    local page="$2"
    local href="${pageFile}"

    if [ "" == "${page}" ]
    then
        page="${pageFile}"
    fi
    if [ "" == "${curPkg}" ]
    then
        echo "No current package to add '${page}' into."
        checkSts 9
    else
        addPageToIndexFile "${curPkg}/${pageFile}" "${page}"
        echo "${pkgIndent}<br/><a href=\"${href}\">${page}<a>">>"${pkgFile}"
    fi
}

################
## Adds an Overview heading and paragraph to an HTML file
## arg-1 Path to file to add overview into
## arg-2 Text to add as the overview
function addHtmlOverview
{
    local filePath="$1"
    local overview="$2"

cat<<EOF >>"${filePath}"
    <h1>Overview</h1>
    <div>
      <p>
EOF
    echo "        ${overview}" >>"${filePath}"
cat<<EOF >>"${filePath}"
      </p>
    </div>
EOF
}

################
## Starts a package
function startPackage
{
    local pkg="$1"
    local overview="$2"
    local fileName="${pkg}.html"

    curPkg="${pkg}"
    pkgDir="${destDir}/${pkg}"
    pkgFile="${pkgDir}/${fileName}"

    mkdir -p "${pkgDir}"
    checkSts $?

    addPageToIndexFile "${curPkg}/${fileName}" "${curPkg}"
    echo "${curIndent}<div>">>"${index}"
    curIndent="${curIndent}  "

    startHtml "${pkgFile}" "Package ${pkg}"
    addHtmlOverview "${pkgFile}" "${overview}"
cat<<EOF >>"${pkgFile}"
    <h1>Page Index</h>
    <div>
EOF
}

################
## Ends current package
function endPackage
{
    # close pkg entry in index
    curIndent="${indexIndent}"
    echo "${curIndent}</div>">>"${index}"

    # finish pkgFile
cat<<EOF >>"${pkgFile}"
    </div>
EOF
    endHtml "${pkgFile}"
}

################
## Adds a new file to the current package
## arg-1 Root name of page
## arg-2 Overview for file/page
## arg-3 Optional identifier for file/page in index; default is arg-1.yml
function addPkgFile
{
    local pageName="$1"
    local fileTitle="${curPkg}-${pageName}"
    local overview="$2"
    local fileId="$3"
    local fileName="${pageName}.html"
    local filePath="${pkgDir}/${fileName}.html"

    if [ "" == "${fileId}" ]
    then
        fileId="${pageName}.yml"
    fi

    addPageToPackage "${fileName}" "${fileId}"
    startHtml "${filePath}" "${fileTitle}"
    addHtmlOverview "${filePath}" "${overview}"
    endHtml "${filePath}"
}

################
## Adds a new '.yml' file to the current package
## arg-1 is name of .yml file without extension
## arg-2 is file/page overview
function addPkgYmlFile
{
    local pageName="$1"
    local overview="$2"

    addPkgFile "${pageName}" "${overview}" "${pageName}.yml" 
}

################
## Adds a new 'entry' file to the current package
## arg-1 is root name of file/page
## arg-2 is file/page overview
function addPkgEntry
{
    local pageName="$1"
    local overview="$2"

    addPkgFile "${pageName}" "${overview}" "${pageName}"
}

################
## Adds pages for workflows package
function addWorkflowsPackage
{
    startPackage workflows "This is where all repo workflows are stored."
    addPkgYmlFile build "Workflow example for building repo release content."
    addPkgYmlFile pubPagesExample "Workflow template example for publishing build documentation pages."
    endPackage
}

################
## Adds pages for actions package
function addActionsPackage
{
    local pkgOverview=$(cat<<EOF
This is where reusable action content is stored.
        Each reusable action goes into a directory that is the name of the action.
        That directory then contains an 'action.yml' file containing the actionable content.
EOF
)
    startPackage actions "${pkgOverview}"
    addPkgEntry java_setup_action "Action example for common Java JDK setup."
    endPackage
}

################
## Adds a page in the same directory as the index
function addLocalPage
{
    local pageName="$1"
    local description="$2"
    local fileName="${pageName}.html"
    local filePath="${destDir}/${fileName}"

    addPageToIndexFile "${fileName}" "${pageName}"
    startHtml "${filePath}" "Local page ${pageName}"
    addHtmlOverview  "${filePath}" "${description}"
    endHtml "${filePath}"
}

################################################################
## Main script logic
if [ "" == "${destDir}" ]
then
    echo "Error: Destination directory required as argument."
    STS=1
fi
if [ 0 == $STS ]
then
    startIndex
    addLocalPage sibling_page "Page local to sibling to prove it is also accessable."
    addWorkflowsPackage
    addActionsPackage
    endIndex
fi

if [ 0 == $STS ]
then
    echo "Success"
else
    echo "Failed"
fi
exit $STS
