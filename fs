#!/usr/bin/env python
import sys, os
import zmq
import socket # supposed to be the best way to gett the hostname
from zmq import ssh
import subprocess
import json

# port for ZeroMQ: this needs to be synced between the server and the client
PORT = 34401
SERVER_ROOT = '/tmp'


def normalize_path(path):
    "Return the cannonical path of a file, relative to $HOME"
    return os.path.relpath(os.path.abspath(path), os.environ['HOME'])

try:
    ssh_string = os.environ['SSH_CLIENT']
    hostip = ssh_string.split()[0]
except KeyError:
    raise RuntimeError("Could not find SSH CLIENT in your env. "
        "Without it, I don't know how to find your workstation")
    

def main(file):
    nfile = normalize_path(file)
    if not os.path.exists(file):
        # if the file doesn't exist, touch it
        open(file, 'w').close()
    if '..' in nfile:
        raise ValueError('Sorry, %s is not in the home directory' % file)
    
    context = zmq.Context.instance()
    sock = context.socket(zmq.REQ)
    ssh.tunnel_connection(sock, "tcp://localhost:%d" % PORT, hostip)

    server_fn = os.path.join(SERVER_ROOT, socket.gethostname(), nfile)
    client_fn = os.path.abspath(file)
    
    # without trailing slashes, rsync will copy the results back into a subdirectory
    if os.path.isdir(file):
        server_fn += '/'
        client_fn += '/'

    #rsync the file to the server
    def do_rsync():
        # when we send the files to the server, we want to delete any
        # junk thats currently there
        # note, when the server rsyncs the results back, it will NOT use --delete
        cmd = ['/usr/bin/rsync', '--delete', '-r', file, hostip + ':' + server_fn]
        subprocess.check_output(' '.join(cmd), shell=True, stderr=subprocess.STDOUT)

    try:
        do_rsync()
    except subprocess.CalledProcessError:
        # tell the server to do the mkdir operator that rsync doesn't want to do
        # if not necessary, we'd prefer not to do the MKDIR, which is why we
        # have it in the except block
        sock.send_json({"type":"mkdir", "dir": os.path.dirname(server_fn)})
        assert sock.recv() == 'OK'
        do_rsync()

    #alert the server that we've sent it the file
    sock.send(json.dumps({'type': 'path',
                          'displayname': '~/' + nfile,
                          'editor': '/usr/local/bin/mate',
                          'server_fn': server_fn,
                          'hostname': socket.gethostname(),
                          'client_fn': client_fn}))
    assert sock.recv() == 'OK'

    
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print 'Usage: %s <file_or_directory>' % sys.arv[0]

    main(sys.argv[1])
