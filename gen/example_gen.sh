#!/bin/sh
clear

# variable for the Directory of Bash Script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# input for whitepaper folder location if not already specified on command line

if [ -z "$1" ]
	then
	echo "Drag the document folder here:"
	read docfolder
else
	docfolder=$1
fi
echo "Docfolder is "$docfolder

filename=${PWD##*/}

if [ -d "$docfolder/Input" ]
	then

	if [ -d "$docfolder/Output" ]
		then
			rm -r $docfolder/Output
	fi

	if [ -d "$docfolder/temp" ]
		then
			rm -r $docfolder/temp;
	fi

	echo "Creating Document"
mkdir -p $docfolder/Output;

mkdir -p $docfolder/Output/MD;
mkdir -p $docfolder/Output/MD/img;

mkdir -p $docfolder/Output/PDF;
mkdir -p $docfolder/Output/PDF/img;

# mkdir -p $docfolder/Output/HTML;
# mkdir -p $docfolder/Output/HTML/img;
mkdir -p $docfolder/temp;

# cp $DIR/template/img/Footer.jpg $docfolder/Output/PDF/img/Footer.jpg
# cp $DIR/template/img/mongodblogo.svg $docfolder/Output/PDF/img/mongodblogo.svg
cp $DIR/template/img/logo.png $docfolder/Output/PDF/img/logo.png

# cp $DIR/template/img/Footer.jpg $docfolder/Output/HTML/img/Footer.jpg
# cp $DIR/template/img/mongodblogo.svg $docfolder/Output/HTML/img/mongodblogo.svg
# cp $DIR/template/img/logo.png $docfolder/Output/HTML/img/logo.png

# cp $DIR/template/img/Footer.jpg $docfolder/Output/MD/img/Footer.jpg
# cp $DIR/template/img/mongodblogo.svg $docfolder/Output/MD/img/mongodblogo.svg
cp $DIR/template/img/logo.png $docfolder/Output/MD/img/logo.png

#get the title out of content.md
TITLE=$(head -n 1 $docfolder/Input/content.md)
#bash substring replacement syntax
TITLE=${TITLE#\# }
TITLE=${TITLE#\#}
echo $TITLE

#get the subtitle out of content.md
SUBTITLE=$(cat $docfolder/Input/content.md | sed -n '2p')
#bash substring replacement syntax
SUBTITLE=${SUBTITLE#\## }
SUBTITLE=${SUBTITLE#\##}
echo $SUBTITLE

#get the titledate out of content.md
TITLEDATE=$(cat $docfolder/Input/content.md | sed -n '3p')
#bash substring replacement syntax
TITLEDATE=${TITLEDATE#\### }
TITLEDATE=${TITLEDATE#\###}
echo $TITLEDATE

#remove three lines from the top of the content.md file 
#(the title, subtitle, date)
sed '1,3d' $docfolder/Input/content.md >> $docfolder/temp/content.md

docname="$(basename $docfolder)"

for i in $docfolder/temp/*.md; do perl $DIR/template/Markdown.pl --html4tags $i >> ${i%.*}.html; done;

# find $docfolder/Input/img -name \*.jpg -exec cp {} $docfolder/Output/HTML/img \;
find $docfolder/Input/img -name \*.jpg -exec cp {} $docfolder/Output/PDF/img \;
find $docfolder/Input/img -name \*.jpg -exec cp {} $docfolder/Output/MD/img \;

# find $docfolder/Input/img -name \*.png -exec cp {} $docfolder/Output/HTML/img \;
find $docfolder/Input/img -name \*.png -exec cp {} $docfolder/Output/PDF/img \;
find $docfolder/Input/img -name \*.png -exec cp {} $docfolder/Output/MD/img \;

##
## make a toc if one doesn't exist. this works by first testing for the file.
## if the file isn't there, it runs grep to extract <h1>,<h2>,<h3> elements from the main content, but only if they begin a line (so it doesn't catch elements like that that are within other ones)
## then it uses sed with a regex to add a <span> to end of those elements before the closing tag so we can add numbers later
## then it puts that stuff in a separate toc file
##

if [ ! -f "$docfolder/Input/toc.md" ]
then
	grep -e '^<h[123].*>' $docfolder/temp/content.html | sed 's/<\/h[123]>/<span><\/span>& /g' >> $docfolder/Input/toc.md
fi

##
## plain markdown setup
##

cat $docfolder/Input/content.md >> $docfolder/Output/MD/${docname}_MD.md
cat $docfolder/Input/appendix.md >> $docfolder/Output/MD/${docname}_MD.md 2> /dev/null

##
## screen and print setup
##

for fmt in cmyk rgb; do
        
#preface
cat $DIR/template/doc/example_${fmt}_front.html >> $docfolder/Output/PDF/$fmt.html
cat $DIR/template/doc/example_common_front.html >> $docfolder/Output/PDF/$fmt.html

#cover
echo "<div id=\"cover\">" >> $docfolder/Output/PDF/$fmt.html
echo "<h1>$TITLE</h1>" >> $docfolder/Output/PDF/$fmt.html
echo "<h2>$SUBTITLE</h2>" >> $docfolder/Output/PDF/$fmt.html
echo "<h3>$TITLEDATE</h3>" >> $docfolder/Output/PDF/$fmt.html
echo "<div id=\"frontlogo\"></div>" >> $docfolder/Output/PDF/$fmt.html
echo "</div>" >> $docfolder/Output/PDF/$fmt.html

#toc
echo "<div id=\"toc\">" >> $docfolder/Output/PDF/$fmt.html
echo "<h1>Table of Contents</h1>" >> $docfolder/Output/PDF/$fmt.html
cat $docfolder/Input/toc.md >> $docfolder/Output/PDF/$fmt.html 2> /dev/null
echo "</div>" >> $docfolder/Output/PDF/$fmt.html

#content
echo "<div id=\"content\">" >> $docfolder/Output/PDF/$fmt.html
cat $docfolder/temp/content.html >> $docfolder/Output/PDF/$fmt.html
echo "</div>" >> $docfolder/Output/PDF/$fmt.html

#footer
cat $DIR/template/doc/example_end.html >> $docfolder/Output/PDF/$fmt.html

#appendix
if [ -f "$docfolder/Input/appendix.md" ]
then
	cat $docfolder/Input/appendix.md >> $docfolder/Output/PDF/$fmt.html
fi

#close doc
echo "</body></html>" >> $docfolder/Output/PDF/$fmt.html

#prince
#replace with path to your PrinceXML binary
/Volumes/Media/Dropbox/docgen/prince/prince $docfolder/Output/PDF/$fmt.html -o $docfolder/Output/PDF/${docname}_${fmt}.pdf -v

done

echo "Done!"

fi