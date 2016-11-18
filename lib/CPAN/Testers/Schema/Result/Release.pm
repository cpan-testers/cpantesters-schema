use utf8;
package CPAN::Testers::Schema::Result::Release;
our $VERSION = '0.001';
# ABSTRACT: Collected test report stats about a single CPAN release

=head1 SYNOPSIS

    my $release = $schema->resultset( 'Release' )->find({
        dist => 'My-Dist',
        version => '1.001',
    });

    say sprintf "My dist has %d pass and %d fail reports",
        $release->pass, $release->fail;

    $schema->resultset( 'Release' )
        ->search({ dist => 'My-Dist', version => '1.001' })
        ->update({ pass => \'pass+1' }); # increment PASSes

=head1 DESCRIPTION

This table contains a collected summary of release data suitable for
quick views of sets of distributions and versions.

=head1 SEE ALSO

=over 4

=item L<DBIx::Class::Row>

=item L<CPAN::Testers::Schema>

=item L<Labyrinth::Plugin::CPAN::Release>

This module processes the data and writes to this table.

=item L<http://github.com/cpan-testers/cpantesters-project>

For an overview of how the CPANTesters project works, and for
information about project goals and to get involved.

=back

=cut

=attr dist

The name of the distribution.

=cut

__PACKAGE__->add_column(
    dist => {
        data_type => 'varchar',
        is_nullable => 0,
    }
);

=attr version

The version of the distribution.

=cut

__PACKAGE__->add_column(
    version => {
        data_type => 'varchar',
        is_nullable => 0,
    }
);

=attr id

The ID of the latest report for this release from the `cpanstats` table.
See L<CPAN::Testers::Schema::Result::Stats>.

=cut

__PACKAGE__->add_column(
    id => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr guid

The GUID of the latest report for this release from the `cpanstats`
table. See L<CPAN::Testers::Schema::Result::Stats>.

=cut

__PACKAGE__->add_column(
    guid => {
        data_type => 'char',
        is_nullable => 0,
    }
);

=attr oncpan

The installability of this release: C<1> if the release is on CPAN. C<2>
if the release has been deleted from CPAN and is only on BackPAN.

=cut

__PACKAGE__->add_column(
    oncpan => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr distmat

The maturity of this release. C<1> if the release is stable and
ostensibly indexed by CPAN. C<2> if the release is a developer release,
unindexed by CPAN.

=cut

__PACKAGE__->add_column(
    distmat => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr perlmat

The maturity of the Perl these reports were sent by: C<1> if the Perl is
a stable release. C<2> if the Perl is a developer release.

=cut

__PACKAGE__->add_column(
    perlmat => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr patched

The patch status of the Perl that sent the report. C<2> if the Perl reports
being patched, C<1> otherwise.

=cut

__PACKAGE__->add_column(
    patched => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr pass

The number of C<PASS> results for this release.

=cut

__PACKAGE__->add_column(
    pass => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr fail

The number of C<FAIL> results for this release.

=cut

__PACKAGE__->add_column(
    fail => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr na

The number of C<NA> results for this release.

=cut

__PACKAGE__->add_column(
    na => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr unknown

The number of C<UNKNOWN> results for this release.

=cut

__PACKAGE__->add_column(
    unknown => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr uploadid

The ID of this upload from the `uploads` table.

=cut

__PACKAGE__->add_column(
    uploadid => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=method upload

Get the related row from the `uploads` table. See
L<CPAN::Testers::Schema::Result::Upload>.

=cut

__PACKAGE__->belongs_to(
    upload => Uploads => 'uploadid',
);

1;