package CPAN::Testers::Schema::Result::TestReport;
our $VERSION = '0.029';
# ABSTRACT: Raw reports as JSON documents

=head1 SYNOPSIS

    my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );

    # Retrieve a row
    my $row = $schema->resultset( 'TestReport' )->first;

=head1 DESCRIPTION

This table contains the raw reports as submitted by the tester. From this,
the L<statistics table|CPAN::Testers::Schema::Result::Stats> is generated
by L<CPAN::Testers::Backend::ProcessReports>.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'Result';
use Data::UUID;
use DateTime;
use JSON::MaybeXS;
use Mojo::Util qw( html_unescape );
table 'test_report';

__PACKAGE__->load_components('InflateColumn::DateTime', 'Core');

=attr id

The UUID of this report stored in standard hex string representation.

=cut

primary_column 'id', {
    data_type => 'char',
    size => 36,
    is_nullable => 0,
};

=attr created

The ISO8601 date/time of when the report was inserted into the database.
Will default to the current time.

The JSON report also contains a C<created> field. This is the date/time
that the report was created on the reporter's machine.

=cut

column created => {
    data_type => 'datetime',
    is_nullable => 0,
    format_datetime => 1,
};

=attr report

The full JSON report.

XXX: Describe the format a little and link to the main schema OpenAPI
format on http://api.cpantesters.org

The serializer for this column will convert UTF-8 characters into their
corresponding C<\u####> escape sequence, so this column is safe for
tables with Latin1 encoding.

=cut

column 'report', {
    data_type            => 'JSON',
    is_nullable          => 0,
};

my %JSON_OPT = (
    allow_blessed => 1,
    convert_blessed => 1,
    ascii => 1,
);
__PACKAGE__->inflate_column( report => {
    deflate => sub {
        my ( $ref, $row ) = @_;
        JSON::MaybeXS->new( %JSON_OPT )->encode( $ref );
    },
    inflate => sub {
        my ( $raw, $row ) = @_;
        JSON::MaybeXS->new( %JSON_OPT )->decode(
            $raw =~ s/([\x{0000}-\x{001f}])/sprintf "\\u%v04x", $1/reg
        );
    },
} );

=method new

Create a new object. This is called automatically by the ResultSet
object and should not be called directly.

This is overridden to provide sane defaults for the C<id> and C<created>
fields.

B<NOTE:> You should not supply a C<created> unless you are creating
reports in the past. Reports created in the past will be hidden from
many feeds, and may cause failures to not be reported to authors.

=cut

sub new( $class, $attrs ) {
    $attrs->{report}{id} = $attrs->{id} ||= Data::UUID->new->create_str;
    $attrs->{created} ||= DateTime->now( time_zone => 'UTC' );
    $attrs->{report}{created} ||= $attrs->{created}->datetime . 'Z';
    return $class->next::method( $attrs );
};

=method upload

    my $upload = $row->upload;

Get the associated L<CPAN::Testers::Schema::Result::Upload> object for
the distribution tested by this test report.

=cut

sub upload( $self ) {
    my ( $dist, $vers ) = $self->report->{distribution}->@{qw( name version )};
    return $self->result_source->schema->resultset( 'Upload' )
        ->search({ dist => $dist, version => $vers })->single;
}

=method dist_name

The name of the distribution that was tested.

=cut

sub dist_name( $self ) {
    return $self->report->{distribution}{name};
}

=method dist_version

The version of the distribution that was tested.

=cut

sub dist_version( $self ) {
    return $self->report->{distribution}{version};
}

=method lang_version

The language and version the test was executed with

=cut

sub lang_version( $self ) {
    return sprintf '%s v%s',
        $self->report->{environment}{language}->@{qw( name version )};
}

=method platform

The platform the test was run on

=cut

sub platform( $self ) {
    return join ' ', $self->report->{environment}{language}{archname};
}

=method grade

The report grade. One of 'pass', 'fail', 'na', 'unknown'.

=cut

sub grade( $self ) {
    return $self->report->{result}{grade};
}

=method text

The full text of the report, either from the phased sections or the
"uncategorized" section.

=cut

my @output_phases = qw( configure build test install );
sub text( $self ) {
    return $self->report->{result}{output}{uncategorized}
        || join "\n\n", grep defined, $self->report->{result}{output}->@{ @output_phases };
}

=method tester_name

The name of the tester who sent the report

=cut

sub tester_name( $self ) {
    return html_unescape $self->report->{reporter}{name};
}

1;
