#fsync

*Launch TextMate via the command line from within a SSH remote session
to edit remote files.*

The server is written in macruby, and the client in python. They communicate
via ZeroMQ over SSH. The file transfer is done by rsync.

##Requirements

###On your workstation:
- macruby: https://macruby.macosforge.org/files/nightlies/
- macruby zeromq bindings: `sudo macgem install zmq`
- hotcocoa: `sudo macgem install hotcocoa`
- passwordless ssh between the machines: http://osxdaily.com/2012/05/25/how-to-set-up-a-password-less-ssh-login/

###On your remote machine:
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