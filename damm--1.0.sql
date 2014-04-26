-- complain if script is sourced in psql rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION damm" to load this file. \quit

CREATE TABLE @extschema@.damm_matrix (i smallint, j smallint, v smallint, PRIMARY KEY (i, j));

COMMENT ON TABLE @extschema@.damm_matrix IS
'This is the magic constant table from page 111 of the Damm paper that makes it go. You probably should ignore this.';

INSERT INTO @extschema@.damm_matrix
SELECT
  i-1,
  j-1,
  ('{{0, 3, 1, 7, 5, 9, 8, 6, 4, 2},
     {7, 0, 9, 2, 1, 5, 4, 8, 6, 3},
     {4, 2, 0, 6, 8, 7, 1, 3, 5, 9},
     {1, 7, 5, 0, 9, 8, 3, 4, 2, 6},
     {6, 1, 2, 3, 0, 4, 5, 9, 7, 8},
     {3, 6, 7, 4, 2, 0, 9, 5, 8, 1},
     {5, 8, 6, 9, 7, 2, 0, 1, 3, 4},
     {8, 9, 4, 5, 3, 6, 2, 0, 1, 7},
     {9, 4, 3, 8, 6, 1, 7, 2, 0, 5},
     {2, 5, 8, 1, 4, 3, 6, 7, 9, 0}}'::smallint[][])[i][j] as v
FROM
  generate_series(1, 10) as i(i),
  generate_series(1, 10) as j(j);

CREATE OR REPLACE FUNCTION @extschema@.damm_check_digit(bigint) RETURNS smallint AS $$
WITH RECURSIVE prev AS
  (SELECT
     string_to_array($1::varchar, null)::smallint[] AS digits,
     0::smallint AS interim,
     1 as i
   UNION ALL
   SELECT prev.digits, v AS interim, prev.i+1
   FROM prev
   JOIN @extschema@.damm_matrix dm ON (dm.i,dm.j) = (prev.interim, prev.digits[prev.i]))
SELECT interim AS code
FROM prev
ORDER BY i DESC
LIMIT 1
$$ LANGUAGE SQL;

COMMENT ON FUNCTION @extschema@.damm_check_digit(bigint) IS
'Compute the Damm check digit for a given number.';


CREATE OR REPLACE FUNCTION @extschema@.valid_damm_code(bigint) RETURNS boolean AS $$
SELECT @extschema@.damm_check_digit($1 / 10) = ($1 % 10)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION @extschema@.valid_damm_code(bigint) IS
'True if the number up is a valid Damm code (meaning the last digit is a check digit that verifies the preceeding digits).';

CREATE OR REPLACE FUNCTION @extschema@.generate_damm(bigint) RETURNS bigint AS $$
SELECT $1 * 10 + @extschema@.damm_check_digit($1)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION @extschema@.generate_damm(bigint) IS
'Given a number, compute the Damm check digit and append it to the number, yielding a valid Damm code.';

CREATE DOMAIN @extschema@.damm_code AS bigint CONSTRAINT damm_code_is_valid CHECK(valid_damm_code(VALUE));

COMMENT ON DOMAIN @extschema@.damm_code IS 'A valid Damm code.';

CREATE OR REPLACE FUNCTION @extschema@.nextdamm(varchar) RETURNS bigint AS $$
SELECT @extschema@.generate_damm(nextval($1))
$$ LANGUAGE SQL;

COMMENT ON FUNCTION nextdamm(varchar) IS
'A nextval() replacement that produces sequential Damm codes from a sequence instead of sequential integers.';
