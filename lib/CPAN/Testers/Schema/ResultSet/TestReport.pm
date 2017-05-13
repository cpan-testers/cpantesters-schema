use utf8;
package CPAN::Testers::Schema::ResultSet::TestReport;
our $VERSION = '0.009';
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
use Scalar::Util qw( blessed );

=method insert_metabase_fact

    my $row = $rs->insert_metabase_fact( $fact );

Convert a L<Metabase::Fact> object to the new test report structure and
insert it into the database. This is for creating backwards-compatible
APIs.

=cut

sub insert_metabase_fact( $self, $fact ) {
    my ( $fact_report ) = grep { blessed $_ eq 'CPAN::Testers::Fact::LegacyReport' } $fact->content->@*;
    my %fact_data = (
        $fact_report->content->%*,
        $fact->core_metadata->%{qw( creation_time guid )},
        $fact->core_metadata->{resource}->metadata->%{qw( dist_name dist_version dist_file cpan_id )},
    );

    my $user_id = $fact->core_metadata->{creator}->resource;
    my ( $metabase_user ) = $self->result_source->schema->resultset( 'MetabaseUser' )
        ->search( { resource => $user_id }, { order_by => '-id', limit => 1 } )->all;

    my %report = (
        reporter => {
            name => $metabase_user->fullname,
            email => $metabase_user->email,
        },
        environment => {
            system => {
                osname => $fact_data{osname},
                osversion => $fact_data{osversion},
            },
            language => {
                name => "Perl 5",
                version => $fact_data{perl_version},
                archname => $fact_data{archname},
            },
        },
        distribution => {
            name => $fact_data{dist_name},
            version => $fact_data{dist_version},
            grade => $fact_data{grade},
            output => {
                uncategorized => $fact_data{textreport},
            },
        },
    );

    return $self->create({
        id => $fact->guid,
        created => $fact->creation_time,
        report => \%report,
    });
}

1;
__END__
