<pre>
Script to migrate FOSWIKI text into MediaWiki text

Change top variables to location of FOSWIKI flat files and directory used for output.

Must change these variables:
FOSWIKI_SOURCE
FOSWIKI_TEXT
FOSWIKI_IMAGES
WORKING_DIR


Migrates:
Headings
Bullets
verbatim tags
img tags and copies images
TOC wiki text
http(s) links
Numbered bullets
TODO: Tables

Search and Replace Psuedo code:
 "---+++" -> "==== \1 ===="
 "---++ " -> "=== * ==="
 "---+ " -> "== * =="
 "         * " -> "****"
 "      * " -> "***"
 "   * " -> "** "
 "&lt;verbatim&gt;" -> "&lt;pre&gt;"
 "&lt;/verbatim&gt;" -> "&lt;/pre&gt;"
 "&lt;img alt='*' height='*2' src='*3' title='*4' width='*5'" -> "[[File:\1|\4]]"
 "^http[^']*" -> "[[\1]]"
 "%TOC%" -> "__TOC__"
 "%TWISTY{mode="div" showlink="[^']*" hidelink="Hide"}%" -> " \
		&lt;span class="mw-customtoggle-myDivision">\1&lt;/span&gt;
		&lt;div class="mw-collapsible mw-collapsed" id="mw-customcollapsible-myDivision"&gt;"
 "%ENDTWISTY%" -> "&lt;/div&gt;"
 "^[1-9])" -> "#"
</pre>
