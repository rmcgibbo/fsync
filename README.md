#fsync

*Launch your local gui editor via the command line from within a SSH remote session
to edit remote files.*

The server is written in macruby, and the client in python. They communicate
via ZeroMQ over SSH. The file transfer is done by rsync.

##Requirements

###On your workstation:
- macruby: https://macruby.macosforge.org/files/nightlies/
- macruby zeromq bindings: `sudo macgem install zmq`
- passwordless ssh between the machines: http://osxdaily.com/2012/05/25/how-to-set-up-a-password-less-ssh-login/

###On your remote machine:
- python: http://www.enthought.com/products/epdgetstart.php?platform=linux
- pyzermomq: `pip install pyzmq`


##Install
There is no installation. Run the server on your machine by `$ ./fsyncserver`
From your remote machine, edit files using `$edit <file>`
  
You can add the `edit` executable to your path or alias it if you like.
To add the alias, add

```
alias edit=/path/to/fsync/download/path/edit
```

to your `.bashrc`


