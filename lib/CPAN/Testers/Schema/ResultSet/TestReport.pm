use utf8;
package CPAN::Testers::Schema::ResultSet::TestReport;
our $VERSION = '0.028';
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
use Log::Any qw( $LOG );
use JSON::MaybeXS qw( encode_json );
use Data::FlexSerializer;
use CPAN::Testers::Report;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Fact::LegacyReport;

=method dist

    my $rs = $rs->dist( 'Perl 5', 'CPAN-Testers-Schema' );
    my $rs = $rs->dist( 'Perl 5', 'CPAN-Testers-Schema', '0.012' );

Fetch reports only for the given distribution, optionally for the given
version. Returns a new C<CPAN::Testers::Schema::ResultSet::TestReport>
object that will only return reports with the given data.

This can be used to scan the full reports for specific data.

=cut

sub dist( $self, $lang, $dist, $version=undef ) {
    return $self->search( {
        'report' => [ -and =>
            \[ "->> '\$.environment.language.name'=?", $lang ],
            \[ "->> '\$.distribution.name'=?", $dist ],
            ( defined $version ? (
                \[ "->> '\$.distribution.version'=?", $version ],
            ) : () ),
        ],
    } );
}

=method insert_metabase_fact

    my $row = $rs->insert_metabase_fact( $fact );

Convert a L<CPAN::Testers::Report> object to the new test report
structure and insert it into the database. This is for creating
backwards-compatible APIs.

=cut

sub insert_metabase_fact( $self, $fact ) {
    $LOG->infof( 'Inserting test report from Metabase fact (%s)', $fact->core_metadata->{guid} );
    my $row = $self->convert_metabase_report( $fact );
    return $self->update_or_create($row);
}

=method convert_metabase_report

Convert a L<CPAN::Testers::Report> object to the new test report
structure and return the row object with C<id>, C<created>, and
C<report> fields. C<report> is the canonical report schema as a Perl
data structure.

=cut

sub convert_metabase_report( $self, $fact ) {
    my ( $fact_report ) = grep { blessed $_ eq 'CPAN::Testers::Fact::LegacyReport' } $fact->content->@*;
    my %fact_data = (
        $fact_report->content->%*,
        $fact->core_metadata->%{qw( creation_time guid )},
        $fact->core_metadata->{resource}->metadata->%{qw( dist_name dist_version dist_file cpan_id )},
    );

    my $user_id = $fact->core_metadata->{creator}->resource;
    my ( $metabase_user ) = $self->result_source->schema->resultset( 'MetabaseUser' )
        ->search( { resource => $user_id }, { order_by => { -desc => 'id' }, limit => 1 } )->all;

    if ( !$metabase_user ) {
        warn $LOG->warn( "Could not find metabase user $user_id" ) . "\n";
    }

    # Remove leading "v" from Perl version
    $fact_data{perl_version} =~ s/^v+//;

    my %report = (
        reporter => {
            name => ( $metabase_user ? $metabase_user->fullname : 'Unknown' ),
            email => ( $metabase_user ? $metabase_user->email : undef ),
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
        },
        result => {
            grade => lc $fact_data{grade},
            output => {
                uncategorized => $fact_data{textreport},
            },
        }
    );

    my $format = DateTime::Format::ISO8601->new();
    my $creation = $format->parse_datetime( $fact->creation_time );
    return {
        id => $fact->guid,
        created => $creation,
        report => \%report,
    };
}

=method parse_metabase_report

    my $metabase_report = $rs->parse_metabase_report( $metabase_row );

This sub undoes the processing that CPAN Testers expects before it is
put in the database so we can ensure that the report was submitted
correctly.

This code is stolen from CPAN::Testers::Data::Generator sub load_fact.

C<$metabase_row> is a hashref with the following keys:

    fact        - A serialized CPAN::Testers::Fact::TestSummary (I think)
    report      - A serialized CPAN::Testers::Fact::LegacyReport (I think)

=cut

my $zipper = Data::FlexSerializer->new(
    assume_compression  => 1,
    detect_sereal       => 1,
    detect_json         => 1,
);

sub parse_metabase_report( $self, $row ) {
    if ( $row->{fact} ) {
        return $zipper->deserialize( $row->{fact} );
    }

    die "No report" unless $row->{report};
    my $data = $zipper->deserialize( $row->{report} );
    my $struct = {
        metadata => {
            core => {
                $data->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}->%*,
                guid => $row->{guid},
                type => 'CPAN-Testers-Report',
            },
        },
        content => encode_json([
            {
                %{ $data->{'CPAN::Testers::Fact::LegacyReport'} },
                content => encode_json( $data->{'CPAN::Testers::Fact::LegacyReport'}{content} ),
            },
            {
                %{ $data->{'CPAN::Testers::Fact::TestSummary'} },
                content => encode_json( $data->{'CPAN::Testers::Fact::TestSummary'}{content} ),
            },
        ]),
    };
    #; use Data::Dumper;
    #; warn Dumper $struct;
    my $fact = CPAN::Testers::Report->from_struct( $struct );
    return $fact;
}

1;
__END__
