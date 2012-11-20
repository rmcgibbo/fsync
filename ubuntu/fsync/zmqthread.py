import zmq
import threading

class ZMQThread(threading.Thread):
    "ZeroMQ Receiver Thread"

    def __init__(self, sock_type, addr, bind, callback):
        threading.Thread.__init__(self)
        # make this thread a daemon so that when gtk exits
        # its main loop, we'll exit too
        self.daemon = True

        ctx = zmq.Context()
        self.sock = ctx.socket(sock_type)
        if bind:
            self.sock.bind(addr)
        else:
            self.sock.connect(addr)
        self.callback = callback
        
    def run(self):
        while True:
            return_message = self.callback(self.sock.recv_json()) or 'OK'
            self.sock.send(return_message)
