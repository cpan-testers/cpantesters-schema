-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.006-MySQL.sql' to 'CPAN::Testers::Schema v0.007':;

BEGIN;

ALTER TABLE test_report ADD COLUMN created timestamp NOT NULL DEFAULT '0';


COMMIT;

