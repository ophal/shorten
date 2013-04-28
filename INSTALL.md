Installation instructions
=========================

1. Create table 'shorten_urls':

CREATE TABLE shorten_urls(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id UNSIGNED BIG INT, long TEXT, short CHAR(10), active BOOLEAN, created UNSIGNED BIG INT);
CREATE INDEX idx_short_url ON shorten_urls (short);
CREATE INDEX idx_long_url ON shorten_urls (long);

2. Add required functions to global environment

env.math = math
env.io_write = io.write
env.os_exit = os.exit
