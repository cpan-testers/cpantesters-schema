use utf8;
package CPAN::Testers::Schema::Result::ReleaseStat;
our $VERSION = '0.020';
# ABSTRACT: A single test report reduced to a simple pass/fail

=head1 SYNOPSIS

    my $release_stats = $schema->resultset( 'ReleaseStat' )->search({
        dist => 'My-Dist',
        version => '1.001',
    });

=head1 DESCRIPTION

This table contains information about individual reports, reduced to
a pass/fail.

These stats are built from the `cpanstats` table
(L<CPAN::Testers::Schema::Result::Stats>), and collected and combined
into the `release_summary` table
(L<CPAN::Testers::Schema::Result::Release>).

B<XXX>: This intermediate table between a report and the release summary
does not seem necessary and if we can remove it, we should.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'Result';
table 'release_data';

=attr dist

The name of the distribution.

=cut

column dist => {
    data_type => 'varchar',
    is_nullable => 0,
};

=attr version

The version of the distribution.

=cut

column version => {
    data_type => 'varchar',
    is_nullable => 0,
};

=attr id

The ID of this report from the `cpanstats` table. See
L<CPAN::Testers::Schema::Result::Stats>.

=cut

column id => {
    data_type => 'int',
    is_nullable => 0,
};

=attr guid

The GUID of this report from the `cpanstats` table. See
L<CPAN::Testers::Schema::Result::Stats>.

=cut

column guid => {
    data_type => 'char',
    size => 36,
    is_nullable => 0,
};

__PACKAGE__->set_primary_key(qw( id guid ));

=attr oncpan

The installability of this release: C<1> if the release is on CPAN. C<2>
if the release has been deleted from CPAN and is only on BackPAN.

=cut

column oncpan => {
    data_type => 'int',
    is_nullable => 0,
};

=attr distmat

The maturity of this release. C<1> if the release is stable and
ostensibly indexed by CPAN. C<2> if the release is a developer release,
unindexed by CPAN.

=cut

column distmat => {
    data_type => 'int',
    is_nullable => 0,
};

=attr perlmat

The maturity of the Perl these reports were sent by: C<1> if the Perl is
a stable release. C<2> if the Perl is a developer release.

=cut

column perlmat => {
    data_type => 'int',
    is_nullable => 0,
};

=attr patched

The patch status of the Perl that sent the report. C<2> if the Perl reports
being patched, C<1> otherwise.

=cut

column patched => {
    data_type => 'int',
    is_nullable => 0,
};

=attr pass

C<1> if this report's C<state> was C<PASS>.

=cut

column pass => {
    data_type => 'int',
    is_nullable => 0,
};

=attr fail

C<1> if this report's C<state> was C<FAIL>.

=cut

column fail => {
    data_type => 'int',
    is_nullable => 0,
};

=attr na

C<1> if this report's C<state> was C<NA>.

=cut

column na => {
    data_type => 'int',
    is_nullable => 0,
};

=attr unknown

C<1> if this report's C<state> was C<UNKNOWN>.

=cut

column unknown => {
    data_type => 'int',
    is_nullable => 0,
};

=attr uploadid

The ID of this upload from the `uploads` table.

=cut

column uploadid => {
    data_type => 'int',
    extra       => { unsigned => 1 },
    is_nullable => 0,
};

=method upload

Get the related row from the `uploads` table. See
L<CPAN::Testers::Schema::Result::Upload>.

=cut

belongs_to upload => 'CPAN::Testers::Schema::Result::Upload' => 'uploadid';

1;
