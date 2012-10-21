QC - Yet Another Bash Bookmark
==============================


Features
--------

Example:

    [~]$ c -a book ~/Book                   # save bookmark explicitly
    [~]$ c -a fonts ~/.fonts
    [~]$ c /usr/share/games/supertux2       # save bookmark implicitly
    [/usr/share/games/supertux2]$ c -l      # list your bookmarks
    book  | ~/Book
    fonts | ~/.fonts
    [/usr/share/games/supertux2]$ c -L      # ... with implicit history
    book  | ~/Book
    fonts | ~/.fonts
    --------------------------------------
    supertux2 | /usr/share/games/supertux2
    [/usr/share/games/supertux2]$ c book    # cd with explicitly saved bookmark
    [~/Book]$ c supertux2                   # cd with implicitly saved bookmark
    [/usr/share/games/supertux2]$ c ~/github/dotvim
    [~/github/dotvim]$ c supertux2/music    # expand by history
    [/usr/share/games/supertux2/music]$ c ..
    [/usr/share/games/supertux2]$ ls
    credits.txt  fonts  images  levels  locale  music  scripts  sounds  speech
    [/usr/share/games/supertux2]$ c fonts   # locale directory first
    [/usr/share/games/supertux2/fonts]$ c ..
    [/usr/share/games/supertux2]$ c ,fonts  # if a name starts with a comma, it's a bookmark's name
    [~/.fonts]$ c @dotvim                   # if a name starts with 'at', it's a history's name
    [~/github/dotvim]$ c -d book            # delete your bookmark
    [~/github/dotvim]$ c book
    Where is 'book'?
    [~/github/dotvim]$ c -L
    fonts | ~/.fonts
    --------------------------------------------
    dotvim    | ~/github/dotvim
    fonts     | /usr/share/games/supertux2/fonts
    supertux2 | /usr/share/games/supertux2
    [~/github/dotvim]$ c ..
    [~/github]$ c -c                        # save current directory as bookmark
    [~/github]$ c -c git                    # ... with a new name
    [~/github]$ c -l
    git         ~/github
    github      ~/github
    fonts       ~/.fonts

By default, all of your bookmarks are saved in a file named `qcdb.yaml` in the same directory where you clone this repository.


Dependencies
------------

+ [PyYAML](http://pypi.python.org/pypi/PyYAML/3.10)


Install
-------

1. Clone this repository to anywhere you like.
For example in your homepath:

        $ cd ~
        $ git clone git://github.com/skydark/qc.git

2. Append this line to your .bashrc:

        source ~/qc/qc.sh

License
-------

[MIT License](http://www.opensource.org/licenses/mit-license.php)
