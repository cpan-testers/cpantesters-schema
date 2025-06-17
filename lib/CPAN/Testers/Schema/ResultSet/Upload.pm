use utf8;
package CPAN::Testers::Schema::ResultSet::Upload;
our $VERSION = '0.029';
# ABSTRACT: Query the CPAN uploads data

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Upload' );
    $rs->by_dist( 'My-Dist' );
    $rs->by_author( 'PREACTION' );
    $rs->since( '2016-01-01T00:00:00' );

=head1 DESCRIPTION

This object helps to query the CPAN uploads table. This table tracks
uploads to CPAN by distribution, version, and author, and also flags
distributions that have been deleted from CPAN (and are thus only
available on BackPAN).

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::Upload>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'ResultSet';
use DateTime::Format::ISO8601;

=method by_dist

    $rs = $rs->by_dist( 'My-Dist' );

Add a dist constraint to the query, replacing any previous dist
constraints.

=cut

sub by_dist( $self, $dist ) {
    return $self->search( { 'me.dist' => $dist } );
}

=method by_author

    $rs = $rs->by_author( 'PREACTION' );

Add an author constraint to the query, replacing any previous author
constraints.

=cut

sub by_author( $self, $author ) {
    return $self->search( { 'me.author' => $author } );
}

=method since

    $rs = $rs->since( '2016-01-01T00:00:00' );

Restrict results to only those that have been updated since the given
ISO8601 date.

=cut

sub since( $self, $date ) {
    my $dt = DateTime::Format::ISO8601->parse_datetime( $date );
    return $self->search( { released => { '>=' => $dt->epoch } } );
}

=method recent

    # 20 most recent
    $rs = $rs->recent( 20 );

    # Just the most recent
    $rs = $rs->recent( 1 );

Return the most-recently released distributions sorted by their release
date/time, descending. Defaults to returning up to 20 results.

=cut

sub recent( $self, $count = 20 ) {
    return $self->search( { }, {
        order_by => { -desc => 'released' },
        rows => $count,
        page => 1,
    } );
}

=method latest_by_dist

Return the dist/version pair for the latest version of all dists
selected by the current resultset.

=cut

sub latest_by_dist( $self ) {
    return $self->search( {}, {
        select => [
            qw( dist ),
            \'MAX(me.version) AS version',
        ],
        as => [ qw( dist version ) ],
        group_by => [ map "me.$_", qw( dist ) ],
        having => \'version = MAX(version)',
    } );
}

1;
__END__
