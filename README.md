fsync
=====

Launch your local gui editor via the command line from within a SSH remote session
to edit remote files.

Only mac

The server is written in macruby, and the client in python. They communicate
via ZeroMQ over SSH. The file transfer is done by rsync.

Requirements
------------

On your workstation:
macruby: https://macruby.macosforge.org/files/nightlies/
macruby zeromq bindings: `sudo macgem install zmq`
passwordless ssh between the machines: http://osxdaily.com/2012/05/25/how-to-set-up-a-password-less-ssh-login/

On your remote machine:
python: http://www.enthought.com/products/epdgetstart.php?platform=linux
pyzermomq: `pip install pyzmq`


