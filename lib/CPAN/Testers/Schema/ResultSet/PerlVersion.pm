use utf8;
package CPAN::Testers::Schema::ResultSet::PerlVersion;
our $VERSION = '0.027';
# ABSTRACT: Query Perl version metadata

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'PerlVersion' );
    $rs->find_or_create({ version => '5.27.0' });

    $rs = $rs->maturity( 'stable' ); # or 'dev'

=head1 DESCRIPTION

This object helps to query Perl version metadata.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::PerlVersion>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'ResultSet';
use Log::Any '$LOG';
use Carp ();

=method maturity

Filter Perl versions of the given maturity. One of C<stable> or C<dev>.

=cut

sub maturity( $self, $maturity ) {
    if ( $maturity eq 'stable' ) {
        return $self->search({ devel => 0 });
    }
    elsif ( $maturity eq 'dev' ) {
        return $self->search({ devel => 1 });
    }
    Carp::croak "Unknown maturity: $maturity. Must be one of: 'stable', 'dev'";
}


1;

