project("dterminal" C)

set(target deepin-terminal)

cmake_minimum_required(VERSION 2.6)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
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
pkg_check_modules(VTE REQUIRED vte-2.91)
pkg_check_modules(GEE REQUIRED gee-0.8)
pkg_check_modules(GIO REQUIRED gio-unix-2.0)
pkg_check_modules(WNCK REQUIRED libwnck-3.0)
pkg_check_modules(FONTCONFIG REQUIRED fontconfig)
pkg_check_modules(GLIB REQUIRED glib-2.0)

set(CFLAGS
	${GIO_CFLAGS}
	${GTK3_CFLAGS} ${GTK3_CFLAGS_OTHER}
	${GEE_CFLAGS}
	${X11_CFLAGS} ${X11_CFLAGS_OTHER}
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE
	-DGETTEXT_PACKAGE="deepin-ternimal"
	-s -O3 -w
	#	-g
)
add_compile_options(${CFLAGS})
set(INCLUDE_PATHS
	${GIO_INCLUDE_DIRS}
	${GTK3_INCLUDE_DIRS}
	${GEE_INCLUDE_DIRS}
	${WNCK_INCLUDE_DIRS}
	${JsonGlib_INCLUDE_DIRS}
	${LIBSECRET_INCLUDE_DIRS}
	${VTE_INCLUDE_DIRS}
)
include_directories(${INCLUDE_PATHS})
set(LIBS
	${GIO_LIBRARIES}
	${GTK3_LIBRARIES}
	${GEE_LIBRARIES}
	${WNCK_LIBRARIES}
	${JsonGlib_LIBRARIES}
	${LIBSECRET_LIBRARIES}
	${VTE_LIBRARIES}
	${X11_LIBRARIES}
	${XTST_LIBRARIES}
	${FONTCONFIG_LIBRARY}
	${M_LIBRARIES}
	m
)
vala_precompile(VALA_C
	./lib/animation.vala
	./lib/config.vala
	./lib/constant.vala
	./lib/draw.vala
	./lib/keymap.vala
	./lib/menu.vala
	./lib/utils.vala
	./lib/xutils.vala
	./widget/about_dialog.vala
	./widget/about_widget.vala
	./widget/add_button.vala
	./widget/appbar.vala
	./widget/check_button.vala
	./widget/click_event_box.vala 
	./widget/command_button.vala
	./widget/command_dialog.vala
	./widget/command_panel.vala
	./widget/base_panel.vala
	./widget/config_window.vala
	./widget/confirm_dialog.vala
	./widget/cursor_toggle_button.vala
	./widget/dialog.vala
	./widget/dialog_button.vala
	./widget/encoding_button.vala 
	./widget/encoding_panel.vala 
	./widget/entry.vala 
	./widget/entry_menu.vala 
	./widget/file_button.vala 
	./widget/image_button.vala
	./widget/panel_button.vala
	./widget/password_button.vala
	./widget/preference.vala
	./widget/preference_slidebar.vala
	./widget/progressbar.vala
	./widget/quake_window.vala
	./widget/remote_panel.vala
	./widget/remote_server_dialog.vala
	./widget/link_button.vala
	./widget/search_entry.vala
	./widget/search_panel.vala
	./widget/server_button.vala
	./widget/server_group_button.vala
	./widget/shortcut_entry.vala
	./widget/split_line.vala
	./widget/spinbutton.vala
	./widget/switcher.vala
	./widget/tabbar.vala
	./widget/terminal.vala
	./widget/text_button.vala
	./widget/theme_button.vala
	./widget/theme_panel.vala
	./widget/titlebar.vala
	./widget/window.vala
	./widget/window_event_area.vala
	./widget/workspace.vala
	./widget/workspace_manager.vala 
	main.vala

OPTIONS
--vapidir=${CMAKE_SOURCE_DIR}/vapi

PACKAGES
	xcb
	gtk+-3.0
	vte-2.91
	gee-0.8
	json-glib-1.0
	gio-2.0
	libwnck-3.0
	posix
	fontconfig
	libsecret-1
	gdk-x11-3.0
	glib-2.0
)
add_executable(${target} ${VALA_C} ${CMAKE_SOURCE_DIR}/project_path.c ${CMAKE_SOURCE_DIR}/lib/font.c)
target_link_libraries(${target} ${LIBS})

FILE(GLOB children LIST_DIRECTORIES true po/*)
SET(dirlist "")
SET(polist "")
FOREACH(child ${children})
	IF(IS_DIRECTORY ${child})
		get_filename_component(childdir ${child} NAME)
		LIST(APPEND dirlist ${childdir})
	ENDIF()
ENDFOREACH()
foreach(lang ${dirlist})
	MESSAGE( STATUS "lang is " ${lang})
	GETTEXT_PROCESS_PO_FILES(${lang} ALL INSTALL_DESTINATION share/locale/ PO_FILES po/${lang}/LC_MESSAGES/deepin-terminal.po)
endforeach()

INSTALL (TARGETS ${target} DESTINATION bin)
INSTALL (FILES hicolor/32x32/deepin-terminal.png DESTINATION share/icons/hicolor/32x32/apps)
INSTALL (FILES hicolor/48x48/deepin-terminal.png DESTINATION share/icons/hicolor/48x48/apps)
INSTALL (FILES hicolor/96x96/deepin-terminal.png DESTINATION share/icons/hicolor/96x96/apps)
INSTALL (FILES hicolor/128x128/deepin-terminal.png DESTINATION share/icons/hicolor/128x128/apps)
INSTALL (FILES hicolor/deepin-terminal.svg DESTINATION share/icons/hicolor/scalable/apps)
INSTALL (DIRECTORY image DESTINATION share/${target} FILES_MATCHING PATTERN "*.png")
INSTALL (DIRECTORY image DESTINATION share/${target} FILES_MATCHING PATTERN "*.svg")
INSTALL (DIRECTORY theme DESTINATION share/${target} FILES_MATCHING PATTERN "*")
INSTALL (DIRECTORY manual/common  manual/en_US  manual/zh_CN DESTINATION share/dman/${target})
INSTALL (FILES style.css ssh_login.sh DESTINATION share/${target})
INSTALL (FILES deepin-terminal.desktop DESTINATION share/applications)
