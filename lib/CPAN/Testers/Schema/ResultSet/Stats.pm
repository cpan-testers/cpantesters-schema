use utf8;
package CPAN::Testers::Schema::ResultSet::Stats;
our $VERSION = '0.020';
# ABSTRACT: Query the raw test reports

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Stats' );
    $rs->insert_test_report( $schema->resultset( 'TestReport' )->first );

=head1 DESCRIPTION

This object helps to insert and query the legacy test reports (cpanstats).

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::Stats>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'ResultSet';
use Log::Any '$LOG';

=method insert_test_report

    my $stat = $rs->insert_test_report( $report );

Convert a L<CPAN::Testers::Schema::Result::TestReport> object to the new test
report structure and insert it into the database. This is for creating
backwards-compatible APIs.

Returns an instance of L<CPAN::Testers::Schema::Result::Stats> on success.
Note that since an uploadid is required for the cpanstats table, this method
throws an exception when an upload cannot be determined from the given
information.

=cut

sub insert_test_report ( $self, $report ) {
    my $schema = $self->result_source->schema;

    my $guid = $report->id;
    my $data = $report->report;
    my $created = $report->created;

    # attempt to find an uploadid, which is required for cpanstats
    my @uploads = $schema->resultset('Upload')->search({
        dist => $data->{distribution}{name},
        version => $data->{distribution}{version},
    })->all;

    die $LOG->warn("No upload match for GUID $guid") unless @uploads;
    $LOG->warn("Multiple upload matches for GUID $guid") if @uploads > 1;
    my $uploadid = $uploads[0]->uploadid;

    my $stat = {
        guid => $guid,
        state => lc($data->{result}{grade}),
        postdate => $created->strftime('%Y%m'),
        tester => qq["$data->{reporter}{name}" <$data->{reporter}{email}>],
        dist => $data->{distribution}{name},
        version => $data->{distribution}{version},
        platform => $data->{environment}{language}{archname},
        perl => $data->{environment}{language}{version},
        osname => $data->{environment}{system}{osname},
        osvers => $data->{environment}{system}{osversion},
        fulldate => $created->strftime('%Y%m%d%H%M'),
        type => 2,
        uploadid => $uploadid,
    };

    return $schema->resultset('Stats')->update_or_create($stat, { key => 'guid' });
}

1;

