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

import optparse

import gettext
from gettext import gettext as _
gettext.textdomain('fsync')

#from gi.repository import Gtk # pylint: disable=E0611
import gtk

from fsync import FsyncWindow

from fsync_lib import set_up_logging, get_version

def parse_options():
    """Support for command line options"""
    parser = optparse.OptionParser(version="%%prog %s" % get_version())
    parser.add_option(
        "-v", "--verbose", action="count", dest="verbose",
        help=_("Show debug messages (-vv debugs fsync_lib also)"))
    (options, args) = parser.parse_args()

    set_up_logging(options)

def main():
    'constructor for your class instances'
    parse_options()

    # Run the application.    
    app = FsyncWindow.Fsync()
    gtk.main()
