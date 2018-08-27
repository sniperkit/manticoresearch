# Sniperkit-Bot
# - Status: analyzed


# versions below 3.3.2 doesn't correctly pack debian control extra.
cmake_minimum_required ( VERSION 3.3.2 )

# Common debian-specific build variables
set ( CPACK_GENERATOR "DEB" )

find_program ( DPKG_PROGRAM dpkg )
if ( DPKG_PROGRAM )
	# use dpkg to fix the package file name
	execute_process (
			COMMAND ${DPKG_PROGRAM} --print-architecture
			OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
			OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	mark_as_advanced( DPKG_PROGRAM )
endif ( DPKG_PROGRAM )

if ( NOT CPACK_DEBIAN_PACKAGE_ARCHITECTURE )
	message ( WARNING "No arch for debian build found. Provide CPACK_PACKAGE_ARCHITECTURE var with the value" )
endif ()

# block below used to patch the minconf and full conf for debian
file ( READ "sphinx-min.conf.in" _MINCONF )
file ( READ "sphinx.conf.in" _FULLCONF )
string ( REPLACE "@CONFDIR@/log/searchd.pid" "@RUNDIR@/searchd.pid" _MINCONF "${_MINCONF}" )
string ( REPLACE "@CONFDIR@/log/searchd.pid" "@RUNDIR@/searchd.pid" _FULLCONF "${_FULLCONF}" )
string ( REPLACE "@CONFDIR@/log" "@LOGDIR@" _FULLCONF "${_FULLCONF}" )
string ( REPLACE "@CONFDIR@/log" "@LOGDIR@" _FULLCONF "${_FULLCONF}" )
file ( WRITE "${MANTICORE_BINARY_DIR}/sphinx-min.conf.in" "${_MINCONF}" )
file ( WRITE "${MANTICORE_BINARY_DIR}/sphinx.conf.in" "${_FULLCONF}" )
unset ( _MINCONF )
unset ( _FULLCONF )

set ( CONFDIR "${LOCALSTATEDIR}/lib/manticore" )
set ( RUNDIR "${LOCALSTATEDIR}/run/manticore" )
set ( LOGDIR "${LOCALSTATEDIR}/log/manticore" )
configure_file ( "${MANTICORE_BINARY_DIR}/sphinx-min.conf.in" "${MANTICORE_BINARY_DIR}/sphinx-min.conf.dist" @ONLY )
configure_file ( "${MANTICORE_BINARY_DIR}/sphinx.conf.in" "${MANTICORE_BINARY_DIR}/sphinx.conf.dist" @ONLY )


string ( CONFIGURE "${POSTINST_SPECIFIC_IN}" POSTINST_SPECIFIC @ONLY )

# install some internal admin sripts for debian
configure_file ( "${CMAKE_CURRENT_SOURCE_DIR}/dist/deb/postinst.in"
		"${MANTICORE_BINARY_DIR}/postinst" @ONLY )

configure_file ( "${CMAKE_CURRENT_SOURCE_DIR}/dist/deb/conffiles.in"
		"${MANTICORE_BINARY_DIR}/conffiles" @ONLY )

configure_file ( "${CMAKE_CURRENT_SOURCE_DIR}/dist/deb/manticore.default.in"
		"${MANTICORE_BINARY_DIR}/manticore" @ONLY )

configure_file ( "${CMAKE_CURRENT_SOURCE_DIR}/dist/deb/manticore.init.in"
		"${MANTICORE_BINARY_DIR}/manticore.init" @ONLY )

configure_file ( "${CMAKE_CURRENT_SOURCE_DIR}/dist/deb/manticore.upstart.in"
		"${MANTICORE_BINARY_DIR}/manticore.upstart" @ONLY )

configure_file ( "${CMAKE_CURRENT_SOURCE_DIR}/dist/deb/README.Debian.in"
		"${MANTICORE_BINARY_DIR}/README.Debian" @ONLY )

# Add one more component group
set ( CPACK_COMPONENT_ADM_GROUP "bin" )
set ( CPACK_COMPONENT_ADM_DISPLAY_NAME "Helper scripts" )

# Copy a default configuration file
INSTALL ( FILES ${MANTICORE_BINARY_DIR}/sphinx.conf.dist
		DESTINATION ${SYSCONFDIR}/sphinxsearch COMPONENT doc RENAME sphinx.conf )

install ( FILES doc/indexer.1 doc/indextool.1 doc/searchd.1 doc/spelldump.1
		DESTINATION ${MANDIR}/man1 COMPONENT doc )

install ( DIRECTORY api DESTINATION ${SHAREDIR}/${PACKAGE_NAME} COMPONENT doc )

install ( FILES
		doc/internals-index-format.txt doc/internals-format-versions.txt
		doc/internals-coding-standard.txt
		"${MANTICORE_BINARY_DIR}/README.Debian"
		dist/deb/copyright
		DESTINATION ${DOCDIR} COMPONENT doc )

install ( FILES example.sql ${MANTICORE_BINARY_DIR}/sphinx.conf.dist
		${MANTICORE_BINARY_DIR}/sphinx-min.conf.dist
		DESTINATION ${DOCDIR}/example-conf COMPONENT doc )

install ( FILES "${MANTICORE_BINARY_DIR}/manticore"
		DESTINATION ${SYSCONFDIR}/default COMPONENT adm)

install ( FILES "${MANTICORE_BINARY_DIR}/manticore.upstart"
		DESTINATION ${SYSCONFDIR}/init COMPONENT adm RENAME manticore.conf )

install ( FILES "${MANTICORE_BINARY_DIR}/manticore.init"
		DESTINATION ${SYSCONFDIR}/init.d PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                      GROUP_EXECUTE GROUP_READ COMPONENT adm RENAME manticore )

install ( DIRECTORY DESTINATION ${LOCALSTATEDIR}/lib/manticore/data COMPONENT adm)
install ( DIRECTORY DESTINATION ${LOCALSTATEDIR}/run/manticore COMPONENT adm )
install ( DIRECTORY DESTINATION ${LOCALSTATEDIR}/log/manticore COMPONENT adm )

# tickets per components
set ( CPACK_DEBIAN_PACKAGE_DESCRIPTION "Fast standalone full-text SQL search engine
 Manticore (ex. Sphinx) is a standalone full text search engine, meant to provide fast,
 size-efficient and relevant fulltext search functions to other applications.
 Sphinx was specially designed to integrate well with SQL databases and
 scripting languages. Currently built-in data sources support fetching data
 either via direct connection to MySQL or PostgreSQL, or using XML pipe
 mechanism (a pipe to indexer in special XML-based format which Sphinx
 recognizes).
 .
 Sphinx is an acronym which is officially decoded as SQL Phrase Index." )

# component 'bin'
set ( CPACK_DEBIAN_BIN_PACKAGE_NAME "manticore" )
# version
# arch

# dependencies will be auto calculated. FIXME! M.b. point them directly?
#set ( CPACK_DEBIAN_BIN_PACKAGE_DEPENDS "libc6 (>= 2.15), libexpat (>= 2.0.1), libgcc1 (>= 1:3.0), libstdc++6 (>= 5.2), zlib1g (>= 1:1.1.4), lsb-base (>= 4.1+Debian11ubuntu7)" )
set ( CPACK_DEBIAN_BIN_PACKAGE_SHLIBDEPS "ON" )
set ( CPACK_DEBIAN_BIN_PACKAGE_SECTION "misc" )
set ( CPACK_DEBIAN_BIN_PACKAGE_PRIORITY "optional" )
set ( CPACK_DEBIAN_BIN_PACKAGE_CONTROL_EXTRA "${MANTICORE_BINARY_DIR}/conffiles;${MANTICORE_BINARY_DIR}/postinst;${MANTICORE_BINARY_DIR}/prerm;${EXTRA_SCRIPTS}" )
set ( CPACK_DEBIAN_BIN_PACKAGE_CONTROL_STRICT_PERMISSION "ON" )
set ( CPACK_DEBIAN_BIN_PACKAGE_REPLACES "sphinxsearch" )

# component 'dbg' (debug symbols)
set ( CPACK_DEBIAN_DBG_PACKAGE_NAME "manticore-dbg" )
# no dependencies
set ( CPACK_DEBIAN_DBG_PACKAGE_DEPENDS "" )
set ( CPACK_DEBIAN_DBG_PACKAGE_SECTION "debug" )
set ( CPACK_DEBIAN_DBG_PACKAGE_PRIORITY "extra" )

set ( CONFFILEDIR "${SYSCONFDIR}/sphinxsearch" )

#set ( CPACK_DEBIAN_PACKAGE_DEBUG "ON" )
