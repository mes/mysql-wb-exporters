mysql-wb-exporters
==================

<a href="http://dev.mysql.com/downloads/workbench/">MySQL Workbench</a> Exporters to generate database documentation for <a href="http://www.atlassian.com/software/confluence/">Confluence</a> and <a href="http://www.redmine.org/">Redmine</a>/<a href="http://en.wikipedia.org/wiki/Textile_%28markup_language%29">Textile</a>.

99.9% based on <a href="http://ralf.schaeftlein.de/2011/02/24/generating-mysql-database-documentation-for-confluence-with-mysql-workbench-plugin/">work by Ralf Schäftlein</a> (LGPLv3).

Instructions:
-------------
1. Download an Exporter Script
2. Start your MySQL Workbench
3. Choose from the “scripting” menu the entry “Install Plugin/Module…”
4. Change Drop down in the Dialog to File type ”lua Files..”
5. Choose downloaded File and click open
6. Restart Workbench
7. Open previously generated ER model file *.mwb
8. Choose from the “Plugins” menu the entry “Catalog” and their the new entry “Confluence Markup Exporter…”
9. Markup is now in the clipboard
10. Open in Confluence an existing page or create a new onw
11. Click on “Edit” button and go to tab “Wiki Markup”
12. Paste the generated documentation and click on “save” button
