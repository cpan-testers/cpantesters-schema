use utf8;
package CPAN::Testers::Schema::ResultSet::Release;
our $VERSION = '0.025';
# ABSTRACT: Query the per-release summary testers data

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Release' );
    $rs->by_dist( 'My-Dist', '0.001' );
    $rs->by_author( 'PREACTION' );
    $rs->since( '2016-01-01T00:00:00' );
    $rs->maturity( 'stable' );

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
    $rs = $rs->by_dist( 'My-Dist', '0.001' );

Add a dist constraint to the query (with optional version), replacing
any previous dist constraints.

=cut

sub by_dist( $self, $dist, $version = undef ) {
    my %search = ( 'me.dist' => $dist );
    if ( $version ) {
        $search{ 'me.version' } = $version;
    }
    return $self->search( \%search );
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

=method maturity

    $rs = $rs->maturity( 'stable' );

Restrict results to only those dists that are stable. Also supported:
'dev' to restrict to only development dists.

=cut

sub maturity( $self, $maturity ) {
    my %map = ( 'stable' => 1, 'dev' => 2 );
    $maturity = $map{ $maturity };
    return $self->search( { 'me.distmat' => $maturity } );
}

=method total_by_release

    $rs = $rs->total_by_release

Sum the pass/fail/na/unknown counts by release distribution and version.

=cut

sub total_by_release( $self ) {
    my @total_cols = qw( pass fail na unknown );
    return $self->search( {}, {
        group_by => [qw( dist version )],
        '+select' => [ map { \"SUM($_)" } @total_cols ],
        '+as' => [ @total_cols ],
    } );
}

1;
__END__
