#fsync

*Launch TextMate via the command line from within a SSH remote session
to edit remote files.*

Sort of like mounting your remote server via SSHFS, but better. That solution
doesn't let you easily activate your editor via command line from within your
SSH session.

##Requirements

###On your workstation (mac only):
You run a littlle server. The server is written in macruby.

- macruby: https://macruby.macosforge.org/files/nightlies/
- macruby zeromq bindings: `sudo macgem install zmq`
- hotcocoa: `sudo macgem install hotcocoa`
- passwordless ssh between the machines: http://osxdaily.com/2012/05/25/how-to-set-up-a-password-less-ssh-login/

###On your remote machine:
You execute a little python script.

- python: http://www.enthought.com/products/epdgetstart.php?platform=linux
- pyzermomq: `pip install pyzmq`


##Install
There is no installation. Run the server on your machine by `$ ./fsyncserver`
From your remote machine, edit files using `$edit <file>`. You probably want to 
add the `edit` executable to your $PATH or alias it.

To add the alias, add

```
alias edit=/path/to/fsync/download/path/edit
```

to your `.bashrc`

Currently, `fsyncserver` is set to use TextMate. But it can really use any editor
that can be invoked from a shell command. If you want to use a different editor, just
change line 13 of `fsyncserver`, where it sets `EDITOR = 'mate'`.

##How it works

The client (remote machine) looks in your environment variables for `SSH_CLIENT`,
and it opens a ZeroMQ connection over ssh tunnel via the client ip listed in `SSH_CLIENT`.

Then, it rsyncs the files back and alerts the server (your workstation) to open
the files with the editor.

The server uses mac's FSEvents API to monitor for filesystem events on the transferred
files. When any event gets triggered (i.e. saving), it runs an rsync to transfer
the files back to the client.

##Random
Note: I think an Ubuntu server would probably be pretty easy to write. You might be
able to do it in python and be able to avoid macruby.