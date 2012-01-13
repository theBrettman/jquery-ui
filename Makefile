# jQuery UI Makefile

SRC_DIR = ui
THEMES_DIR = themes
PREFIX = ${PWD}
BUILD_DIR = ${PREFIX}/build
VERSION = $(shell cat version.txt)
MAJOR_VERSION = $(shell cat version.txt | perl -pe 's/\D*(\d+\.\d+).*/$$1/')
RELEASE = jquery-ui-${VERSION}

DIST_DIR = ${PREFIX}/dist
DEST_DIR = ${DIST_DIR}/${RELEASE}
CDN_DEST_DIR = ${DEST_DIR}-cdn
CONCAT_JS = ${DEST_DIR}/ui/jquery-ui.js
CONCAT_I18N = ${DEST_DIR}/ui/i18n/jquery-ui-i18n.js
CONCAT_CSS = ${DEST_DIR}/themes/base/jquery-ui.css
MIN_DIR = ${DEST_DIR}/ui/minified
MIN_CSS_DIR = ${DEST_DIR}/themes/base/minified

DOCS_DIR = ${DEST_DIR}/docs

SIZE_DIR = ${BUILD_DIR}/size

CDN_DIR = ${DIST_DIR}/${RELEASE}-cdn

# Commands
JS_ENGINE ?= $(shell which node nodejs 2>/dev/null)
JS_MINIFY = ${JS_ENGINE} ${BUILD_DIR}/uglify.js --unsafe
CSS_MINIFY = java -jar ${BUILD_DIR}/yuicompressor-2.4.2.jar --charset utf-8 -v

# Source Files
JS_SRC = ${SRC_DIR}/*.js
JS_I18N_SRC = ${SRC_DIR}/i18n/*.js
CORE_FILES = jquery.ui.core.js jquery.ui.widget.js jquery.ui.mouse.js jquery.ui.draggable.js jquery.ui.droppable.js jquery.ui.resizable.js jquery.ui.selectable.js jquery.ui.sortable.js jquery.effects.core.js

# A list of all files with CORE_FILES in front
ALL_FILES = $(shell cd ui; echo ${CORE_FILES} jquery.ui.*.js jquery.effects.*.js | xargs -n1 echo | awk '!x[$$$$1]++' )
ALL_CSS = $(shell cd themes/base; echo jquery.ui.core.css jquery.*.css | xargs -n1 echo | awk 'BEGIN { x["jquery.ui.base.css"]=1;x["jquery.ui.all.css"]=1;x["jquery.ui.theme.css"]=1; } !x[$$$$1]++' ) jquery.ui.theme.css

# Build Targets
all: deploy-release

cdn: 
	@@echo Creating fresh CDN Distribution ${CDN_DEST_DIR}
	@@rm -rf ${CDN_DEST_DIR}
	@@mkdir -p ${CDN_DEST_DIR}
	@@mkdir ${CDN_DEST_DIR}/i18n
	@@mkdir ${CDN_DEST_DIR}/themes
	@@cd ${DEST_DIR} ; cp AUTHORS.txt GPL-LICENSE.txt MIT-LICENSE.txt version.txt ${CDN_DEST_DIR}
	@@cd ${DEST_DIR}/ui ; cp jquery-ui.js ${CDN_DEST_DIR}
	@@cd ${DEST_DIR}/ui/minified ; cp jquery-ui.min.js ${CDN_DEST_DIR}
	@@cd ${DEST_DIR}/ui/i18n ; cp *.js ${CDN_DEST_DIR}/i18n
	@@cd ${DEST_DIR}/ui/minified/i18n ; cp *.js ${CDN_DEST_DIR}/i18n
	@@cd ${DEST_DIR} ; cp -R themes ${CDN_DEST_DIR}
	@@cd ${CDN_DEST_DIR} ; for file in $$(find . -type f) ; \
		do openssl dgst -md5 $$file | sed s/MD5\(.\\/// | sed s/\)=// >> ${CDN_DEST_DIR}/MANIFEST ;\
	done
	@@echo Building Google ZIP
	@@cd ${DIST_DIR} ; zip -r ${RELEASE}-googlecdn.zip ${RELEASE}-cdn
	@@echo Building MS ZIP
	@@zip -r ${DIST_DIR}/${RELEASE}-mscdn.zip dist/${RELEASE}-cdn

clean:
	@@echo "Cleaning distributuion directory:" ${DIST_DIR}
	@@rm -rf ${DIST_DIR}

concatenate: copy
	@@echo "Building concatenated JS"
	@@cd ${SRC_DIR} ; cat ${ALL_FILES} > ${CONCAT_JS}

	@@echo "Building concatenated CSS"
	@@cd ${THEMES_DIR}/base ; cat ${ALL_CSS} > ${CONCAT_CSS}

	@@echo "Building concatenated i18n"
	@@cd ${SRC_DIR}/i18n ; cat *.js > ${CONCAT_I18N}

copy:
	@@echo "Copying needed files"
	@@mkdir -p ${DEST_DIR}/ui/i18n
	cp jquery-*.js ${DEST_DIR}
	cp *.txt ${DEST_DIR}
	cp ${SRC_DIR}/jquery.*.js ${DEST_DIR}/ui
	cp ${SRC_DIR}/i18n/jquery.*.js ${DEST_DIR}/ui/i18n
	cp -R demos ${DEST_DIR}
	cp -R external ${DEST_DIR}
	cp -R tests ${DEST_DIR}
	cp -R themes ${DEST_DIR}

# Builds ZIP files for deployment
deploy-release: clean docs-download copy minify replace-version prepend-header zip

docs-download:
	@@mkdir -p ${DOCS_DIR}
	@@echo "Downloading Documentation from " ${DOCS_URL}
	${JS_ENGINE} ${BUILD_DIR}/docs-download.js ${DOCS_DIR} ${MAJOR_VERSION}

minify: concatenate
	@@echo "Minifying Source"
	@@mkdir -p ${MIN_DIR} ${MIN_DIR}/i18n ${MIN_CSS_DIR}
	@@cd ${DEST_DIR}/ui ; for file in jquery.*.js jquery-*.js i18n/jquery.*.js i18n/jquery-*.js ; \
		do echo "* " $${file}; \
		${JS_MINIFY} $$file > `echo ${MIN_DIR}/$$file | sed 's/\.js/.min.js/'` || exit 1;\
	done

	@@echo "Minifying CSS"
	@@cd ${DEST_DIR}/themes/base ; for file in *.css ; \
		do echo "* " $${file}; \
		${CSS_MINIFY} $$file -o `echo ${MIN_CSS_DIR}/$$file | sed 's/\.css/.min.css/'` || exit 1;\
	done

	@@echo "Replacing .css with .min.css in @imports"
	@@cd ${MIN_CSS_DIR} ; for file in jquery.ui.base.min.css jquery.ui.all.min.css ; \
		do sed 's/.css/.min.css/' $$file > $$file.tmp ; \
		rm $$file ; \
		mv $$file.tmp $$file ; \
	done

	@@cp -R ${MIN_CSS_DIR}/../images ${MIN_CSS_DIR}

prepend-header:
	@@echo "Fixing Headers for Minified CSS"
	@@mkdir -p ${MIN_CSS_DIR}/headers
	@@cd ${DEST_DIR}/themes/base ; for file in *.css ; \
		do cat $$file | awk '!x && /*\// { print $0 ; x=1; } !x' > ${MIN_CSS_DIR}/headers/`echo $$file | sed 's/\.css/.min.css/'`; \
	done
	@@cd ${MIN_CSS_DIR} ; for file in *.css ; \
		do cat $$file >> headers/$$file ; \
		rm $$file ; \
		mv headers/$$file . ; \
	done
	@@rm -rf ${MIN_CSS_DIR}/headers

# Replaces the version placeholders
replace-version:
	@@echo "Replacing @VERSION with ${VERSION}"
	@@for file in $$(find ${DEST_DIR}/ui -name \*.js ) $$(find ${DEST_DIR}/themes -name \*.css ); do \
		sed 's/@VERSION/${VERSION}/g' $$file > $$file.tmp ; \
		rm $$file ; \
		mv $$file.tmp $$file ; \
	done

size: copy minify replace-version prepend-header
	@@echo "Collecting the files to size"
	@@mkdir -p ${SIZE_DIR}
	cp ${DEST_DIR}/ui/*.js ${SIZE_DIR}
	cp ${DEST_DIR}/ui/i18n/*.js ${SIZE_DIR}
	cp ${DEST_DIR}/ui/minified/*.js ${SIZE_DIR}
	cp ${DEST_DIR}/ui/minified/i18n/*.js ${SIZE_DIR}
	cp ${DEST_DIR}/themes/base/*.css ${SIZE_DIR}
	cp ${DEST_DIR}/themes/base/minified/*.css ${SIZE_DIR}

	@@echo "Gzipping minified files"
	@@cd ${SIZE_DIR} ; for file in *.min.js *.min.css ; \
		do gzip -c $$file > $$file.gz ; \
	done

	@@echo "Comparing file size with previous build"
	@@wc -c ${SIZE_DIR}/* | ${JS_ENGINE} ${BUILD_DIR}/sizer.js

	@@rm -rf ${SIZE_DIR}

themes-download:
	@@echo "Downloading themes"
	@@mkdir -p ${DEST_DIR}/themes/zip
	@@${JS_ENGINE} ${BUILD_DIR}/themes-download.js ${DEST_DIR}/themes/zip || exit 1

	@@echo "Unzipping and moving to proper location"
	@@cd ${DEST_DIR}/themes/zip ; for file in *.zip ; do \
		rm -rf $$file.tmp ;\
		unzip $$file development-bundle/themes/\*\* -x development-bundle/themes/base/\* -d $$file.tmp > /dev/null ; \
		rm -rf ${DEST_DIR}/themes/`echo $$file | sed s/.zip// ` ; \
		mv $$file.tmp/development-bundle/themes/*/jquery-ui-*custom.css $$file.tmp/development-bundle/themes/`echo $$file | sed s/.zip// `/jquery-ui.css ; \
		mv $$file.tmp/development-bundle/themes/* ${DEST_DIR}/themes ; \
		echo "* $$file" ;\
	done

	@@echo "Cleaning up temporary directory"
	@@rm -rf ${DEST_DIR}/themes/zip

	@@echo "Building ${DIST_DIR}/jquery-ui-themes-${VERSION}"
	@@rm -rf ${DIST_DIR}/jquery-ui-themes-${VERSION}
	@@mkdir -p ${DIST_DIR}/jquery-ui-themes-${VERSION}
	@@cd ${DEST_DIR} ; cp -R AUTHORS.txt GPL-LICENSE.txt MIT-LICENSE.txt version.txt themes ${DIST_DIR}/jquery-ui-themes-${VERSION}

	@@echo "Building ${DIST_DIR}/jquery-ui-themes-${VERSION}.zip"
	@@cd ${DIST_DIR} ; zip -r jquery-ui-themes-${VERSION}.zip jquery-ui-themes-${VERSION}

# strips BOM / trailling whitespaces
whitespace:
	@@echo "Stripping BOM / Trailing Whitespace from source files"
	@@for file in $$(find ui -name \*.js;find themes -name \*.css) ; \
		do perl -pe 's/^\xEF\xBB\xBF//s;s/\s+$$/\n/g' < $$file > $$file.tmp ; \
		rm $$file ; \
		mv $$file.tmp $$file ; \
	done
	@@echo "Done, showing git status"
	git status

zip:
	@@echo "Zipping release"
	@@rm ${DIST_DIR}/${RELEASE}.zip || true
	cd ${DIST_DIR} ; zip -r ${RELEASE}.zip ${RELEASE}