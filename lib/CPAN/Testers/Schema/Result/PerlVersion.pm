use utf8;
package CPAN::Testers::Schema::Result::PerlVersion;
our $VERSION = '0.024';
# ABSTRACT: Metadata about Perl versions

=head1 SYNOPSIS

    my $perl = $schema->resultset( 'PerlVersion' )->find( '5.26.0' );
    say "Stable" unless $perl->devel;

    $schema->resultset( 'PerlVersion' )->find_or_create({
        version => '5.30.0',    # Version reported by Perl
        perl => '5.30.0',       # Parsed Perl version string
        patch => 0,             # Has patches applied
        devel => 0,             # Is development version (odd minor version)
    });

    # Fill in metadata automatically
    $schema->resultset( 'PerlVersion' )->find_or_create({
        version => '5.31.0 patch 1231',
        # devel will be set to 1
        # patch will be set to 1
        # perl will be set to 5.31.0
    });

=head1 DESCRIPTION

This table holds metadata about known Perl versions. Through this table we can
quickly list which Perl versions are stable/development.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'Result';

table 'perl_version';

=attr version

The Perl version reported by the tester. This is the primary key.

=cut

primary_column version => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 0,
};

=attr perl

The parsed version of Perl in C<REVISION.VERSION.SUBVERSION> format.

If not specified when creating a new row, the Perl version will be parsed
and this field updated accordingly.

=cut

column perl => {
    data_type => 'varchar',
    size => 32,
    is_nullable => 1,
};

=attr patch

If true (C<1>), this Perl has patches applied. Defaults to false (C<0>).

If not specified when creating a new row, the Perl version will be parsed
and this field updated accordingly.

=cut

column patch => {
    data_type => 'tinyint',
    size => 1,
    default_value => 0,
};

=attr devel

If true (C<1>), this Perl is a development Perl version. Development Perl
versions have an odd C<VERSION> field (the second number) like C<5.27.0>,
C<5.29.0>, C<5.31.0>, etc... Release candidates (like C<5.28.0 RC0>) are
also considered development versions.

If not specified when creating a new row, the Perl version will be parsed
and this field updated accordingly.

=cut

column devel => {
    data_type => 'tinyint',
    size => 1,
    default_value => 0,
};

=method new

The constructor will automatically fill in any missing information based
on the supplied C<version> field.

=cut

sub new( $class, $attrs ) {
    if ( !$attrs->{perl} ) {
        ( $attrs->{perl} ) = $attrs->{version} =~ m{^v?(\d+\.\d+\.\d+)};
    }
    if ( !$attrs->{patch} ) {
        $attrs->{patch} = ( $attrs->{version} =~ m{patch} ) ? 1 : 0;
    }
    if ( !$attrs->{devel} ) {
        my ( $version ) = $attrs->{version} =~ m{^v?\d+\.(\d+)};
        $attrs->{devel} =
            (
                ( $version >= 7 && $version % 2 ) ||
                $attrs->{version} =~ m{^v?\d+\.\d+\.\d+ RC\d+}
            ) ? 1 : 0;
    }
    return $class->next::method( $attrs );
}

1;
