# Makefile will generate the ZSSH definition

Summary		: Interactive file transfers to/from a remote machine while using the secure shell (ssh).
Name		: zssh
Version		: %{ZSSHVER}
Release		: 1
Copyright	: GPL
Group		: Applications/Communications
Source		: download.sourceforge.net:/pub/sourceforge/zssh/zssh-%{ZSSHVER}.tgz
packager        : Matthieu Lucotte <gounter@users.sourceforge.net>
%description
zssh (Zmodem SSH) is a program for interactively transferring files to/from
a remote machine while using the secure shell (ssh). It is intended to be a
convenient alternative to scp, allowing to transfer files without having to
open another  session and re-authenticate  oneself. zssh is  an interactive
wrapper for ssh used to switch  the ssh connection between the remote shell
and  file transfers.  Files are  transferred through  the  zmodem protocol,
using the rz and sz commands.

%prep
%setup

%build
./configure
make

%install
make install

%files
%doc CHANGES COPYING FAQ INSTALL README VERSION
/usr/local/bin/zssh
/usr/local/bin/ztelnet
/usr/local/man/man1/zssh.1
/usr/local/man/man1/ztelnet.1


