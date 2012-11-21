#fsync
------

*Inside your SSH session, launch your local editor to work on remote files.*

This utility will let you, from you SSH session to a remote machine, open up a
file or directory on your local workstation. Any edits you make will by synced
back to the remote machine (like dropbox). To get going, you need to run the
fsync server on your local workstation -- it's a tiny little status bar app.

It's sort of like mounting your remote server via SSH-FS, but better. That solution
doesn't let you easily activate your editor via command line from within your
SSH session.

## Using

From within your SSH session on a remote machine, run

`$ fs foo.bar`

It pops up your file, in your editor, on your workstation. When you hit save, the
modified file will be automatically synced back to your workstation. Poof.

You can make some customizations by setting the environment variables
`$FSYNC_EDITOR`, `$FSYNC_USER`, and `$FSYNC_SERVER`. See the `-h` help for the
`fs` utility for details.

## Install

The status bar app installs as a regular GUI app.

### Mac Status Bar App (for your workstation)
[Download](https://github.com/rmcgibbo/fsync/downloads) the .zip. The app is
inside. Drag it to your Applications folder.

### Linux Status Bar App (for your workstation)
[Get](https://github.com/rmcgibbo/fsync/downloads) the .deb. Install it, either
by the command line (`sudo dpkg -i fsync_ubuntu_0.1.deb`) or by double clicking
it, using the Ubuntu application store.

### Client Utility (for your remote machine)
Use the `client/setup.py` script. `$ python setup.py install` 
installs the  command line program `fs`.

## Requirements

- fsync server app running on local workstation
- symmetrical passwordless SSH via public keys between your workstation
    and remote.

On your workstation (mac or linux) you run a little server. The server is written
in Objective-C (mac) and python/PyGTK (linux). For the linux system, you need to
have [libzmq](http://www.zeromq.org/intro:get-the-software) installed. For mac,
it's packaged within.

##How it works

The client (remote machine) looks in your environment variables for `SSH_CLIENT`,
and it opens a ZeroMQ connection over ssh tunnel via the client ip listed in `SSH_CLIENT`.

Then, it rsyncs the files back and alerts the server (your workstation) to open
the files with the editor.

The server uses mac's FSEvents API to monitor for filesystem events on the transferred
files. When any event gets triggered (i.e. saving), it runs an rsync to transfer
the files back to the client.
