package CPAN::Testers::Schema::Result::MetabaseUser;
our $VERSION = '0.021';
# ABSTRACT: Legacy user information from the Metabase

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'MetabaseUser' );
    my ( $row ) = $rs->search({ resource => $resource })->all;

    say $row->fullname;
    say $row->email;

=head1 DESCRIPTION

This table stores the Metabase users so we can look up their name and e-mail
when they send in reports.

=head1 SEE ALSO

L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'Result';
table 'metabase_user';

=attr id

The ID of the row in the database.

=cut

primary_column id => {
    data_type => 'int',
    is_auto_increment => 1,
};

=attr resource

The Metabase GUID of the user. We use this to look the user up. Will be
a UUID prefixed with C<metabase:user:>.

=cut

unique_column resource => {
    data_type => 'char',
    size => 50,
    is_nullable => 0,
};

=attr fullname

The full name of the user.

=cut

column fullname => {
    data_type => 'varchar',
    is_nullable => 0,
};

=attr email

The e-mail address of the user.

=cut

column email => {
    data_type => 'varchar',
    is_nullable => 1,
};

1;
