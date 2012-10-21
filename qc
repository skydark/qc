#!/usr/bin/python
# -*- coding: utf-8 -*-


import os
from os import path
# This is a monkey patch:
#  If directory A is a symbol-link to directory B,
#  we expect the output of `os.path.abspath('.')` is A.
#  But in fact, it is B.
_old_abspath = path.abspath
path.abspath = lambda s: _old_abspath(path.join(os.getenv('PWD'), s))

import sys
if sys.version_info < (3, 0):
    reload(sys)
    sys.setdefaultencoding('utf-8')

import logging
logger = logging.getLogger('qc')
# logger.setLevel(logging.DEBUG)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())

DS_NAME = 'qcdb.yaml'
DEFAULT_DS = 'yaml'
MAX_HISTORY_SIZE = 20


def message(msg):
    return '\n' + msg


class DataStore(object):
    _engine = None
    _save_options = {}
    _load_options = {}
    _default_db_factory = dict
    _ext = None

    def __init__(self, path):
        self.dbpath = path

    def create_if_not_exist(self):
        if not path.isfile(self.dbpath):
            self.save(self._default_db_factory())

    def save(self, db):
        try:
            with open(self.dbpath, 'w') as file_handler:
                self._engine.dump(db, file_handler, **self._save_options)
                logger.debug('Write db to file: {}'.format(self.dbpath))
        except UnicodeError as e:
            logger.error(e)

    def load(self):
        # db = self._default_db_factory()
        try:
            with open(self.dbpath, 'r') as file_handler:
                db = self._engine.load(file_handler, **self._load_options)
                logger.debug('Read db in file: {}'.format(self.dbpath))
        except UnicodeError as e:
            logger.error(e)
        return db


class YamlDataStore(DataStore):
    import yaml
    _engine = yaml
    _save_options = {
            'default_flow_style': False,
            'allow_unicode': True,
            'encoding': 'utf-8',
            }
    _ext = 'yaml'


class JsonDataStore(DataStore):
    import json
    _engine = json
    _ext = 'json'


class DirBookmark(object):
    def __init__(self, datastore):
        self.datastore = datastore
        self.datastore.create_if_not_exist()
        self.datastore._default_db_factory = self._default_db_factory
        self.db = self._load_db()

    @staticmethod
    def _curdir():
        return path.abspath('.')

    @staticmethod
    def _get_name_by_path(name):
        return path.split(path.abspath(name))[1]

    @staticmethod
    def _default_db_factory():
        d = {}
        d['bookmarks'] = {}
        d['history'] = []
        return d

    def _load_db(self):
        db = self.datastore.load()
        db.setdefault('bookmarks', {})
        db.setdefault('history', [])
        return db

    def _savedb(self):
        self.datastore.save(self.db)

    def _add_bm(self, name, path_=None):
        if path_ is None:
            path_, name = name, self._get_name_by_path(name)
        self.db['bookmarks'][name] = path.abspath(path_)
        self._savedb()
        return path_

    def add(self, name, path_=None):
        self._add_bm(name, path_)
        return ''

    def _get_bookmark(self, name):
        return self.db['bookmarks'].get(name, '')

    def _get_history(self, name):
        for path_ in self.db['history']:
            if self._get_name_by_path(path_) == name:
                return path_
        return ''

    def delete(self, name):
        if self.db['bookmarks'].pop(name, None) is None:
            logger.warning('No directory named {}'.format(name))
        else:
            self._savedb()
        return ''

    def _save_history(self, path_):
        path_ = path.abspath(path_)
        history = self.db['history']
        if path_ in history:
            history.remove(path_)
        elif len(history) >= MAX_HISTORY_SIZE:
            history.pop(0)
        history.append(path_)
        self._savedb()
        return path_

    def index(self, name):
        if name == '-':
            return name
        if name.startswith(('/', './', '../')) or path.isdir(name):
            return self._save_history(name)
        if '/' in name:
            name, subpath = name.split('/', 1)
            dir = self._get_bookmark(name)
            if dir:
                dir = path.join(dir, subpath)
                if path.isdir(dir):
                    return dir
            dir = self._get_history(name)
            if dir:
                dir = path.join(dir, subpath)
                if path.isdir(dir):
                    return dir
            return message('No subdir %s/%s found!' % (name, subpath))
        if name.startswith(','):
            name = name[1:]
            return self._get_bookmark(name) or \
                    message('No bookmark %s found!' % name)
        if name.startswith('@'):
            name = name[1:]
            return self._get_history(name) or \
                    message('No history %s found!' % name)
        return self._get_bookmark(name) or self._get_history(name) or \
                message('Where is {}?'.format(name))

    def save_current(self, name=None):
        curdir = self._curdir()
        if name is None:
            name = self._get_name_by_path(curdir)
        self._add_bm(name, curdir)
        return ''

    @staticmethod
    def _pretty_print(items):
        items = list(items)
        if len(items) == 0:
            return ''
        homedir = path.realpath(path.expanduser('~'))
        keys = list(zip(*items))[0]
        width = max(len(key) for key in keys)
        formatter = '{:<%s} | {}' % width

        def collapse_user_home(path_):
            if path_.startswith(homedir):
                return '~' + path_[len(homedir):]
            else:
                return path_

        return '\n'.join(formatter.format(k, collapse_user_home(v))
                for k, v in items)

    def list(self):
        lists = self._pretty_print(self.db['bookmarks'].items())
        return message(lists)

    def list_all(self):
        bookmark = self._pretty_print(self.db['bookmarks'].items())
        history = self._pretty_print((self._get_name_by_path(v), v)
                for v in self.db['history'])
        if history:
            size = max(len(line) for line in bookmark.split('\n'))
            size = max(size, max(len(line) for line in history.split('\n')))
            history = '\n' + '-' * size + '\n' + history
        return message(bookmark + history)

    def bash_completion(self, need='all'):
        # assert need in ('add', 'bookmark', 'path', 'all')
        subpaths = []
        if need in ('all', 'path', 'add'):
            subpaths += list(filter(path.isdir, os.listdir('.')))
        if need in ('all', 'add', 'bookmark'):
            bookmarks = self.db['bookmarks'].keys()
            subpaths += bookmarks
            if need == 'all':
                subpaths += [',' + v for v in bookmarks]
        if need in ('all',):
            histories = list(map(self._get_name_by_path, self.db['history']))
            subpaths += histories
            subpaths += ['@' + v for v in histories]
        subpaths = list(set(subpaths))
        subpaths.sort()
        logger.debug(subpaths)
        return message('\n'.join(subpaths))


def get_bookmark(dbpath=None):
    if dbpath is None:
        dbpath = path.join(path.dirname(path.realpath(__file__)), DS_NAME)
    DataStoreMap = dict((c._ext, c) for c in DataStore.__subclasses__())
    DataStoreClass = DataStoreMap.get(path.splitext(dbpath)[1][1:], None)
    if DataStoreClass  is None:
        DataStoreClass = DataStoreMap[DEFAULT_DS]
    datastore = DataStoreClass(dbpath)
    return DirBookmark(datastore)


_switch_map = {
        'a': 'add',
        'c': 'save_current',
        'd': 'delete',
        'h': 'help',
        'l': 'list',
        'L': 'list_all',
        }


def help():
    return message('''Yet another bash bookmark: qc
    -h/--help                   show this help
    -a/--add [name] path        add a bookmark
    -d/--delete name            delete a bookmark
    -c/--save_current [name]    save current directory to bookmark
    -l/--list                   show all bookmarks
    -L/--list_all               show all bookmarks and histories
    ''')


def main(argv):
    if not argv:
        return ''
    func = 'index'
    first_arg = argv[0]
    if first_arg == '--':
        argv.pop(0)
    elif first_arg.startswith('--'):
        func = argv.pop(0)[2:]
    elif first_arg.startswith('-') and first_arg != '-':
        func = _switch_map.get(argv.pop(0)[1:], 'help')

    if func == 'help':
        return help()

    bookmark = get_bookmark()
    try:
        return getattr(bookmark, func)(*argv)
    except TypeError as e:
        logger.error(e)
        help()
        return ''


if __name__ == '__main__':
    print(main(sys.argv[1:]))
