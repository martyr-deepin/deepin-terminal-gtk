project("dterminal" C)

set(target deepin-terminal)

cmake_minimum_required(VERSION 2.6)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include(ExternalProject)
include(ValaPrecompile)
include(ValaVersion)
find_package(Vala)
ensure_vala_version("0.22.0" MINIMUM)
find_package(PkgConfig)
find_package(GLib "2.48" REQUIRED)
find_package(JsonGlib)
find_package(Libsecret)
find_package(FontConfig)
find_package(X11)
find_package(Gettext)

pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
pkg_check_modules(GEE REQUIRED gee-0.8)
pkg_check_modules(GIO REQUIRED gio-unix-2.0)
pkg_check_modules(RSVG REQUIRED librsvg-2.0)
pkg_check_modules(WNCK REQUIRED libwnck-3.0)
pkg_check_modules(FONTCONFIG REQUIRED fontconfig)
pkg_check_modules(GLIB REQUIRED glib-2.0)

option(TEST_BUILD "Build with native testing" ON)
option(USE_VENDOR_LIB "Backport support for debian stretch" ON)

if (NOT USE_VENDOR_LIB)
pkg_check_modules(VTE REQUIRED vte-2.91)
endif()

if (NOT DEFINED VERSION)
find_package(Git)
message("generate version from git")
execute_process(COMMAND ${GIT_EXECUTABLE}
    describe --abbrev=6 --dirty --tags
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
endif()
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/constant.vala.in
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/constant.vala
)

if(TEST_BUILD)
message("set project_path to native test")
execute_process(
    COMMAND sed s|@@PROJECT_PATH@@|\"${CMAKE_SOURCE_DIR}\"|g
    OUTPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/project_path.c
    INPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/project_path.c.in
)
list(APPEND ARGS_DEFINITIONS "TEST_BUILD")
else()
message("set project_path to ${CMAKE_INSTALL_PREFIX}")
execute_process(
    COMMAND sed s|@@PROJECT_PATH@@|\"${CMAKE_INSTALL_PREFIX}\"|g
    OUTPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/project_path.c
    INPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/project_path.c.in
)
endif()

if (USE_VENDOR_LIB)
ExternalProject_Add(Vte-0.52
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/3rdparty/vte-0.52.1
  CONFIGURE_COMMAND ./configure --enable-static
  BUILD_COMMAND make
  INSTALL_COMMAND ""
  BUILD_IN_SOURCE 1
  )

ExternalProject_Add(zssh-1.5c
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/3rdparty/zssh-1.5c
  CONFIGURE_COMMAND ./configure
  BUILD_COMMAND make
  INSTALL_COMMAND ""
  BUILD_IN_SOURCE 1
  )
endif()

set(CFLAGS
	${GIO_CFLAGS}
	${GTK3_CFLAGS} ${GTK3_CFLAGS_OTHER}
	${GEE_CFLAGS}
	${X11_CFLAGS} ${X11_CFLAGS_OTHER}
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE
	-DGETTEXT_PACKAGE=${target}
	-s -O3 -w
	#	-g
)
add_compile_options(${CFLAGS})
set(INCLUDE_PATHS
	${GIO_INCLUDE_DIRS}
	${GTK3_INCLUDE_DIRS}
	${GEE_INCLUDE_DIRS}
	${WNCK_INCLUDE_DIRS}
	${RSVG_INCLUDE_DIRS}
	${JsonGlib_INCLUDE_DIRS}
	${LIBSECRET_INCLUDE_DIRS}
)

if (USE_VENDOR_LIB)
	list(APPEND INCLUDE_PATHS ${CMAKE_SOURCE_DIR}/3rdparty/vte-0.52.1/src)
	find_library(VTE_LIB NAMES libvte-2.91.a tcmalloc_minimal)
else()
	list(APPEND INCLUDE_PATHS ${VTE_INCLUDE_DIRS})
endif()

include_directories(${INCLUDE_PATHS})
set(LIBS
	${GIO_LIBRARIES}
	${GTK3_LIBRARIES}
	${GEE_LIBRARIES}
	${WNCK_LIBRARIES}
	${RSVG_LIBRARIES}
	${JsonGlib_LIBRARIES}
	${LIBSECRET_LIBRARIES}
	${ZLIB_LIBRARIES}
	${X11_LIBRARIES}
	${XTST_LIBRARIES}
	${FONTCONFIG_LIBRARY}
	${M_LIBRARIES}
	stdc++
	m
	z
	pthread
	gnutls
	pcre2-8
)

if (NOT USE_VENDOR_LIB)
	list(APPEND LIBS ${VTE_LIBRARIES})
endif()

SET(APP_SOURCES, "")
FILE(GLOB valalist LIST_FILES true */*.vala)
FOREACH(child ${valalist})
	file(RELATIVE_PATH
    file_path
    ${CMAKE_SOURCE_DIR}
    ${child}
	)
	set (APP_SOURCES ${APP_SOURCES} ${file_path})
ENDFOREACH()

set(VALA_PRECOMPILE_PACKAGES
	xcb
	gtk+-3.0
	vte-2.91
	gee-0.8
	json-glib-1.0
	gio-2.0
	libwnck-3.0
	posix
	libsecret-1
	gdk-x11-3.0
	glib-2.0
	librsvg-2.0
)

if (USE_VENDOR_LIB)
	list(APPEND VALA_PRECOMPILE_PACKAGES fontconfig)

	vala_precompile(VALA_C
		./main.vala
		${APP_SOURCES}

	OPTIONS
	--vapidir=${CMAKE_SOURCE_DIR}/vapi

	PACKAGES
		${VALA_PRECOMPILE_PACKAGES}
	)
else()
	vala_precompile(VALA_C
		./main.vala
		${APP_SOURCES}

	PACKAGES
		${VALA_PRECOMPILE_PACKAGES}
	)
endif()

add_executable(${target} ${VALA_C} ${CMAKE_SOURCE_DIR}/project_path.c ${CMAKE_SOURCE_DIR}/lib/font.c)

if (USE_VENDOR_LIB)
	target_link_libraries(${target} ${LIBS} ${CMAKE_SOURCE_DIR}/3rdparty/vte-0.52.1/src/.libs/libvte-2.91.a)
	add_dependencies(${target} Vte-0.52)
else()
	target_link_libraries(${target} ${LIBS})
endif()

FILE(GLOB children LIST_DIRECTORIES true po/*)
SET(dirlist "")

FOREACH(child ${children})
	IF(IS_DIRECTORY ${child})
		get_filename_component(childdir ${child} NAME)
		LIST(APPEND dirlist ${childdir})
	ENDIF()
ENDFOREACH()

FOREACH(lang ${dirlist})
	SET(gmoFiles)
	FOREACH(current_PO_FILE po/${lang}/LC_MESSAGES/deepin-terminal.po)
    	  SET(gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${lang}-${target}.gmo)
    	  SET(INSTALL_DESTINATION share/locale/)
    	  ADD_CUSTOM_COMMAND(OUTPUT ${gmoFile}
    	        COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${gmoFile} ${current_PO_FILE}
    	        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    	        DEPENDS ${current_PO_FILE}
    	     )
    	  INSTALL(FILES ${gmoFile} DESTINATION ${INSTALL_DESTINATION}/${lang}/LC_MESSAGES/  RENAME ${target}.mo)

    	  LIST(APPEND gmoFiles ${gmoFile})
    ENDFOREACH(current_PO_FILE)

    ADD_CUSTOM_TARGET(${lang} ALL DEPENDS ${gmoFiles})

ENDFOREACH(lang)

INSTALL (TARGETS ${target} DESTINATION bin)
if (USE_VENDOR_LIB)
	INSTALL (PROGRAMS ${CMAKE_SOURCE_DIR}/3rdparty/ssh_login.sh ${CMAKE_SOURCE_DIR}/3rdparty/zssh-1.5c/zssh DESTINATION lib/${target})
else()
	INSTALL (PROGRAMS ssh_login.sh DESTINATION lib/${target})
endif()
INSTALL (FILES hicolor/32x32/${target}.png DESTINATION share/icons/hicolor/32x32/apps)
INSTALL (FILES hicolor/48x48/${target}.png DESTINATION share/icons/hicolor/48x48/apps)
INSTALL (FILES hicolor/96x96/${target}.png DESTINATION share/icons/hicolor/96x96/apps)
INSTALL (FILES hicolor/128x128/${target}.png DESTINATION share/icons/hicolor/128x128/apps)
INSTALL (FILES hicolor/${target}.svg DESTINATION share/icons/hicolor/scalable/apps)
INSTALL (DIRECTORY image DESTINATION share/${target} FILES_MATCHING PATTERN "*.png")
INSTALL (DIRECTORY image DESTINATION share/${target} FILES_MATCHING PATTERN "*.svg")
INSTALL (DIRECTORY theme DESTINATION share/${target} FILES_MATCHING PATTERN "*")
INSTALL (FILES style.css DESTINATION share/${target})
INSTALL (FILES ${target}.desktop DESTINATION share/applications)
