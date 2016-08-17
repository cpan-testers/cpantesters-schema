use utf8;
package CPAN::Testers::Schema;
# ABSTRACT: DBIx::Class::Schema for CPANTesters cpanstats db

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


our $VERSION = 0;   # DBIx::Class::Deploymenthandler?



# Convenience connect method
sub connect_from_config {
    my $schema = shift->connect(
        "DBI:mysql:mysql_read_default_file=$ENV{HOME}/.cpanstats.cnf;".
        "mysql_read_default_group=application;mysql_enable_utf8=1",
        undef,  # user
        undef,  # pass
        {
            AutoCommit => 1,
            RaiseError => 1,
            mysql_enable_utf8 => 1,
            quote_char => '`',
            name_sep   => '.',
        },
    );
    $schema->txn_begin;
    return $schema;
}

1;
