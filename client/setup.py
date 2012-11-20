from setuptools import setup

setup(name='fsync-client',
      version='0.1',
      install_requires=['pyzmq', 'pexpect'],
      license='GPL-3',
      author='Robert McGibbon',
      author_email='rmcgibbo@gmail.com',
      scripts=['fs'])

