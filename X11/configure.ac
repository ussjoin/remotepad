AC_INIT(remotepad.c)
AC_PROG_CC
AC_PATH_XTRA
AC_CHECK_LIB(m, sqrt)
CPPFLAGS="$CPPFLAGS $X_CFLAGS"
AC_CHECK_MEMBERS([struct sockaddr.sa_len],,,[
#include <sys/types.h>
#include <sys/socket.h>
])
AC_CHECK_HEADER(X11/Xlib.h, AC_CHECK_LIB(X11, XOpenDisplay, , AC_MSG_ERROR([X Window System is required.]), $X_LIBS), AC_MSG_ERROR([X Window System is required.]))
AC_CHECK_HEADER(X11/extensions/XTest.h, AC_CHECK_LIB(Xtst, XTestQueryExtension, , AC_MSG_ERROR([XTest extension development library is required.  Please install a package libXtst-dev or libXtst-devel or x11/libXtst.]), $X_LIBS), AC_MSG_ERROR([XTest extension development library is required.  Please install a package libXtst-dev or libXtst-devel or x11/libXtst.]))
AC_CONFIG_HEADER(config.h)
AC_CONFIG_FILES(Makefile)
AC_OUTPUT
