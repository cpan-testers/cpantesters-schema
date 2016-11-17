use utf8;
package CPAN::Testers::Schema::Result::Stats;
our $VERSION = '0.001';
# ABSTRACT: The basic statistics information extracted from test reports

=head1 SYNOPSIS

    my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );

    # Retrieve a row
    my $row = $schema->resultset( 'Stats' )->first;
    # pass from doug@example.com (Doug Bell) using Perl 5.20.1 on darwin
    say sprintf "%s from %s using Perl %s on %s",
        $row->state,
        $row->tester,
        $row->perl,
        $row->osname;

    # Create a new row
    my %new_row_data = (
        state => 'fail',
        guid => '00000000-0000-0000-0000-000000000000',
        tester => 'doug@example.com (Doug Bell)',
        postdate => '201608',
        dist => 'My-Dist',
        version => '0.001',
        platform => 'darwin-2level',
        perl => '5.22.0',
        osname => 'darwin',
        osvers => '10.8.0',
        fulldate => '201608120401',
        type => 2,
        uploadid => 287102,
    );
    my $new_row = $schema->resultset( 'Stats' )->insert( \%new_row_data );

=head1 DESCRIPTION

This table (C<cpanstats> in the database) hold the basic, vital statistics
extracted from test reports. This data is used to generate reports for the
web application and web APIs.

See C<ATTRIBUTES> below for the full list of attributes.

=head1 SEE ALSO

=over 4

=item L<DBIx::Class::Row>

=item L<CPAN::Testers::Schema>

=item L<CPAN::Testers::Data::Generator>

This module processes the data and writes to this table.

=item L<http://github.com/cpan-testers/cpantesters-project>

For an overview of how the CPANTesters project works, and for information about
project goals and to get involved.

=back

=cut

use strict;
use warnings;

__PACKAGE__->table('cpanstats');

=attr id

The ID of the row. Auto-generated.

=cut

__PACKAGE__->add_columns(
  'id', {
    data_type         => 'int',
    extra             => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable       => 0,
  },
);
__PACKAGE__->set_primary_key('id');

=attr guid

The UUID of this report from the Metabase, stored in standard hex string
representation.

=cut

__PACKAGE__->add_columns(
  'guid', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 36,
  },
);

=attr state

The state of the report. One of:

=over 4

=item C<pass>

The tests passed and everything went well.

=item C<fail>

The tests ran but failed.

=item C<na>

This dist is incompatible with the tester's Perl or OS.

=item C<unknown>

The state could not be determined.

=back

C<invalid> reports, which are marked that way by dist authors when the
problem is on the tester's machine, are handled by the L</type> field.

=cut

__PACKAGE__->add_columns(
  'state', {
    data_type   => 'enum',
    extra       => { list => ['pass', 'fail', 'unknown', 'na'] },
    is_nullable => 0,
  },
);

=attr postdate

A truncated date, consisting only of the year and month in C<YYYYMM>
format.

=cut

__PACKAGE__->add_columns(
  'postdate', {
    data_type      => 'mediumint',
    extra          => { unsigned => 1 },
    is_nullable    => 0,
  },
);

=attr tester

The e-mail address of the tester who sent this report, optionally with
the tester's name as a comment (C<doug@example.com (Doug Bell)>).

=cut

__PACKAGE__->add_columns(
  'tester', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 100,
  },
);

=attr dist

The distribution that was tested.

=cut

__PACKAGE__->add_columns(
  'dist', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 100,
  },
);

=attr version

The version of the distribution.

=cut

__PACKAGE__->add_columns(
  'version', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
);

=attr platform

The Perl C<platform> string (from C<$Config{archname}>).

=cut

__PACKAGE__->add_columns(
  'platform',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
);

=attr perl

The version of Perl that was used to run the tests (from
C<$Config{version}>).

=cut

__PACKAGE__->add_columns(
  'perl',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 10,
  },
);

=attr osname

The name of the operating system (from C<$Config{osname}>).

=cut

__PACKAGE__->add_columns(
  'osname',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
);

=attr osvers

The version of the operating system (from C<$Config{osvers}>).

=cut

__PACKAGE__->add_columns(
  'osvers',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
);

=attr fulldate

The full date of the report, with hours and minutes, in C<YYYYMMDDHHNN>
format.

=cut

__PACKAGE__->add_columns(
  'fulldate', {
    data_type   => 'char',
    is_nullable => 0,
    size        => 8,
  },
);

=attr type

A field that declares the status of this row. The only current
possibilities are:

=over 4

=item 2

This is a valid Perl 5 test report

=item 3

This report was marked invalid by a user

=back

=cut

__PACKAGE__->add_columns(
  'type', {
    data_type   => 'tinyint',
    extra       => { unsigned => 1 },
    is_nullable => 0,
  },
);

=attr uploadid

The ID of the upload that created this dist. Related to the C<uploadid>
field in the C<uploads> table (see
L<CPAN::Testers::Schema::Result::Uploads>).

=cut

__PACKAGE__->add_columns(
  'uploadid', {
    data_type   => 'int',
    extra       => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->belongs_to(
    upload => Uploads => 'uploadid',
);

1;
