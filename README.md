
# Working on the MELT website

The website is built using the `hugo` static site generator tool: https://gohugo.io/ . It uses the off-the-shelf theme `hugo-geekdoc`: https://github.com/thegeeklab/hugo-geekdoc . Content is contained in `content/`, you shouldn't(TM) have to edit the rest.

To work on it locally:

 - If you are not on Linux, uncomment the appropriate line in `setup-build-env` to download the executable for your OS/architecture. 
 - Run `./setup-build-env` to fetch hugo and the theme. You should maybe do this semiregularly in case we update the version of hugo we use.
 - OPTIONAL: Run `./make-docs` in your silver install, then run `./fetch-docs` with the env var `DOCPATH` set to the generated folder of docs. E.g. `DOCPATH=../silver/generated/doc/ ./fetch-docs`.
 - Run `serve-site` to run a local webserver serving the site

