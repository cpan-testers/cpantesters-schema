use utf8;
package CPAN::Testers::Schema::ResultSet::Release;
our $VERSION = '0.013';
# ABSTRACT: Query the per-release summary testers data

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Release' );
    $rs->by_dist( 'My-Dist' );
    $rs->by_author( 'PREACTION' );
    $rs->since( '2016-01-01T00:00:00' );

=head1 DESCRIPTION

This object helps to query the per-release test report summaries. These
summaries say how many pass, fail, NA, and unknown results a single
version of a distribution has.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>, L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'ResultSet';

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
    return $self->search( { 'upload.author' => $author }, { join => 'upload' } );
}

=method since

    $rs = $rs->since( '2016-01-01T00:00:00' );

Restrict results to only those that have been updated since the given
ISO8601 date.

=cut

sub since( $self, $date ) {
    my $fulldate = $date =~ s/[-:T]//gr;
    $fulldate = substr $fulldate, 0, 12; # 12 digits makes YYYYMMDDHHNN
    return $self->search( { 'report.fulldate' => { '>=', $fulldate } }, { join => 'report' } );
}

1;
__END__
