use utf8;
package CPAN::Testers::Schema::ResultSet::TestReport;
our $VERSION = '0.006';
# ABSTRACT: Query the raw test reports

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'TestReport' );
    $rs->insert_metabase_fact( $fact );

=head1 DESCRIPTION

This object helps to insert and query the raw test reports.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::TestReport>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'ResultSet';

=method insert_metabase_fact

    my $row = $rs->insert_metabase_fact( $fact );

Convert a L<Metabase::Fact> object to the new test report structure and
insert it into the database. This is for creating backwards-compatible
APIs.

=cut

sub insert_metabase_fact( $self, $fact ) {
    return $self->insert({
        id => $fact->guid,
    });
}

1;
__END__
