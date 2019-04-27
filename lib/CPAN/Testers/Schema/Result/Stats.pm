use utf8;
package CPAN::Testers::Schema::Result::Stats;
our $VERSION = '0.025';
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

This data is built from the Metabase by the L<CPAN::Testers::Data::Generator>.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'Result';
table 'cpanstats';

=attr id

The ID of the row. Auto-generated.

=cut

primary_column 'id', {
    data_type         => 'int',
    extra             => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable       => 0,
};

=attr guid

The UUID of this report from the Metabase, stored in standard hex string
representation.

=cut

# Must be unique for foreign keys to work
column 'guid', {
    data_type   => 'char',
    is_nullable => 0,
    size        => 36,
};
unique_constraint guid => [qw( guid )];

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

column 'state', {
    data_type   => 'enum',
    extra       => { list => ['pass', 'fail', 'unknown', 'na'] },
    is_nullable => 0,
};

=attr postdate

A truncated date, consisting only of the year and month in C<YYYYMM>
format.

=cut

column 'postdate', {
    data_type      => 'mediumint',
    extra          => { unsigned => 1 },
    is_nullable    => 0,
};

=attr tester

The e-mail address of the tester who sent this report, optionally with
the tester's name as a comment (C<doug@example.com (Doug Bell)>).

=cut

column 'tester', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr dist

The distribution that was tested.

=cut

column 'dist', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr version

The version of the distribution.

=cut

column 'version', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr platform

The Perl C<platform> string (from C<$Config{archname}>).

=cut

column 'platform',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr perl

The version of Perl that was used to run the tests (from
C<$Config{version}>).

=cut

column 'perl',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr osname

The name of the operating system (from C<$Config{osname}>).

=cut

column 'osname',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr osvers

The version of the operating system (from C<$Config{osvers}>).

=cut

column 'osvers',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

=attr fulldate

The full date of the report, with hours and minutes, in C<YYYYMMDDHHNN>
format.

=cut

column 'fulldate', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 32,
};

=attr type

A field that declares the status of this row. The only current
possibilities are:

=over 4

=item 2 - This is a valid Perl 5 test report

=item 3 - This report was marked invalid by a user

=back

=cut

column 'type', {
    data_type   => 'tinyint',
    extra       => { unsigned => 1 },
    is_nullable => 0,
};

=attr uploadid

The ID of the upload that created this dist. Related to the C<uploadid>
field in the C<uploads> table (see
L<CPAN::Testers::Schema::Result::Uploads>).

=cut

column 'uploadid', {
    data_type   => 'int',
    extra       => { unsigned => 1 },
    is_nullable => 0,
};

=method upload

Get the related row in the `uploads` table. See L<CPAN::Testers::Schema::Result::Upload>.

=cut

belongs_to upload => 'CPAN::Testers::Schema::Result::Upload' => 'uploadid';

=method perl_version

Get the related metadata about the Perl version this report is for. See
L<CPAN::Testers::Schema::Result::PerlVersion>.

=cut

might_have perl_version => 'CPAN::Testers::Schema::Result::PerlVersion' =>
    { 'foreign.version' => 'self.perl' };

1;
