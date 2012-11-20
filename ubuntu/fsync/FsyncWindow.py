### BEGIN LICENSE
# Copyright 2012 Robert McGibbon
#
# This file is part of fsync
#
# fsync is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# fsync is distributed in the hope that it will be useful, but WITHOUT ANY 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# fsync. If not, see http://www.gnu.org/licenses/.
### END LICENSE

# standard imports
import sys, os
import subprocess

# gtk imports
import gobject, gtk, gio
import appindicator

# other imports
import zmq
from zmqthread import ZMQThread

# necessary to tell gtk we're going to use threads
gtk.gdk.threads_init()

class WatchFileMenuItem(gtk.MenuItem):
    def __init__(self, client_fn, server_fn, hostname, displayname):
        """This gtk.MenuItem puts a file system event watch on the
        `server_fn` file.

        The 4 parameters are the oes passed in the JSON message over
        ZMQ from the client.

        When the FS event triggers, this object will start an rsync
        to transfer the file back
        """
        
        # save for use in callback
        self.client_fn = client_fn
        self.server_fn = server_fn
        self.hostname = hostname

        # initialize with title
        gtk.MenuItem.__init__(self, '%s: %s' %(hostname, displayname))

        if not os.path.exists(server_fn):
            raise ValueError('server_fn does not exist: %s' % server_fn)

        self._monitor = gio.File(server_fn).monitor()

        self._monitor.connect("changed", self.file_changed)

    def file_changed(self, monitor, file, unknown, event):
        if event == gio.FILE_MONITOR_EVENT_CHANGES_DONE_HINT:
            cmd = ['/usr/bin/rsync', '-r', self.server_fn,
                   '%s:%s' % (self.hostname, self.client_fn)]
            subprocess.Popen(cmd)
    
    def remove_monitor(self):
        self._monitor.cancel()


class Fsync:
    def __init__(self):
        self.ind = appindicator.Indicator("example-simple-client", "indicator-messages", appindicator.CATEGORY_COMMUNICATIONS)
        self.ind.set_status (appindicator.STATUS_ACTIVE)
        self.ind.set_attention_icon ("indicator-messages-new")
        self.ind.set_icon("gtk-refresh")
        
        self.menu = self.create_menu()
        self.ind.set_menu(self.menu)

        zthread = ZMQThread(zmq.REP, 'tcp://127.0.0.1:34401', bind=True,
                            callback=self.zmq_msg).start()

    def item_clicked(self, item):
        """Respond to the user clicking on one of the files in the menu.

        unmap the file

        """
        item.remove_monitor()
        item.destroy()

    def zmq_msg(self, msg):
        try:
            type = msg.pop('type')
            if type == 'path':
                self.register_new_path(msg)
            elif type == 'mkdir':
                self.mkdir_for_client(msg)
            else:
                raise ValueError("Bad message %s" % message)

        except Exception as e:
            # could make it respond gracefully to failures, display
            # an alert...
            raise

        return 'OK'
    
    def mkdir_for_client(self, msg):
        """Make a directory on the server that
        the client can deposit data in"""
        try:
            os.makedirs(msg['dir'])
        except OSError:
            pass

    def register_new_path(self, msg):
        """Handler for incoming ZeroMQ messages that want to add a new path

        1) validate message
        2) make sure the file is not already being mapped
        3) add the WatchFileMenuItem to the menu, which starts
           the filesystem watching
        4) Launch the editor
        """
        required_keys = ['server_fn', 'client_fn', 'hostname', 'editor',
                         'displayname']
        if any([key not in msg for key in required_keys]):
            raise ValueError("Bad message. Doesn't have the right keys")

        editor = msg.pop('editor')

        # check if the item is already in the menu
        unique = True
        for current_item in self.menu.get_children():
            if isinstance(current_item, WatchFileMenuItem):
                if current_item.server_fn == msg['server_fn']:
                    unique = False
         
        # only add unique items
        if unique:
            newitem = WatchFileMenuItem(**msg)
            newitem.show()
            newitem.connect("activate", self.item_clicked)
            self.menu.prepend(newitem)

        # launch the editor regardless
        #print [editor, msg['server_fn']]
        subprocess.Popen([editor, msg['server_fn']])

            
    def create_menu(self):
        """Create a menu and show it

        Returns
        -------
        menu : gtk.Menu
        """
        menu = gtk.Menu()
        
        def add(item, connect=None):
            item.show()
            menu.append(item)
            if connect:
                item.connect(*connect)
            
        add(gtk.SeparatorMenuItem())
        add(gtk.MenuItem("About fsync"), connect=("activate", self.show_about))
        add(gtk.SeparatorMenuItem())
        add(gtk.MenuItem("Quit"), connect=("activate", gtk.main_quit))

        menu.show()
        return menu

    def show_about(self, item):
        """Launch the browser to the github page

        """
        gtk.show_uri(None, 'http://github.com/rmcgibbo/fsync', gtk.gdk.CURRENT_TIME)

if __name__ == '__main__':
    # Run the application.    
    app = Fsync()
    gtk.main()

    
