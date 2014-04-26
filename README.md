# Damm codes for PostgreSQL

[The Damm algorithm](http://en.wikipedia.org/wiki/Damm_algorithm)
produces a check digit for a particular integer. The Damm algorithm is
better than all the other algorithms we have and simpler to implement
to boot. It can detect every single-digit error or transposition
error.

The main use is to define a Damm code, which is an integer whose last
digit is the check digit. I wanted to be able to use this from within
PostgreSQL to define my own primary keys with this nice built-in
validity property.

## Installation

Check out the source and run the following command:

     $ sudo make install

You should see output like this:

    /bin/sh /opt/local/lib/postgresql93/pgxs/src/makefiles/../../config/install-sh -c -d '/opt/local/share/postgresql93/extension'
    /bin/sh /opt/local/lib/postgresql93/pgxs/src/makefiles/../../config/install-sh -c -d '/opt/local/share/postgresql93/extension'
    /usr/bin/install -c -m 644 ./damm.control '/opt/local/share/postgresql93/extension/'
    /usr/bin/install -c -m 644 ./damm--1.0.sql  '/opt/local/share/postgresql93/extension/'

This extension is pure SQL with no C component, so it may be possible
to install unprivileged. The extension can be loaded with the `WITH
SCHEMA` option, but it is not dynamically relocatable due to the
lookup table.

## Getting Started

This library offers two "levels" of API. The high-level API is to use
`nextdamm` to produce the next Damm code from some underlying
sequence:

    CREATE SEQUENCE thing_id_seq;
	
    CREATE TABLE things (
	  id damm_code DEFAULT nextdamm('thing_id_seq') PRIMARY KEY,
	  …
	);

This is not much different from using `SERIAL`, which is just
shorthand for `bigint DEFAULT nextval('thing_id_seq')` combined with
automatically creating the sequence. (If anyone knows how to create a
type in Postgres that could do that automatically, please let me know,
as I'd like to make the above code simpler.)

The low-level API is to use `generate_damm` to create a Damm code from
a number by synthesizing the check digit and appending it. It sounds
worse than it is. For instance, suppose you want to use a date with a
Damm code. Interactively, it's going to look something like this:

    damm=# select generate_damm(to_char(current_timestamp, 'YYYYMMDD')::bigint);
     generate_damm 
    ---------------
         201404265
    (1 row)

The 5 is a check digit appended to the original value (20140426). This
might be an appropriate way to produce user-visible IDs from dates.

If you don't want to use the `damm_code` type, you may want to use the
function `valid_damm_code` to validate a number.

    damm=# select valid_damm_code(201404265);
     valid_damm_code 
    -----------------
     t
    (1 row)

## License

This software is made available under the terms of the MIT license. If
you use the software and find it useful, please let me know, I'd love
to hear from you.