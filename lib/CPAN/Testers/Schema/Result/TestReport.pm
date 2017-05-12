package CPAN::Testers::Schema::Result::TestReport;
our $VERSION = '0.008';
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
table 'test_report';

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

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

=cut

column created => {
    data_type => 'datetime',
    is_nullable => 0,
};

=attr report

The full JSON report.

XXX: Describe the format a little and link to the main schema OpenAPI
format on http://api.cpantesters.org

=cut

column 'report', {
    data_type            => 'JSON',
    is_nullable          => 0,
    'serializer_class'   => 'JSON',
    'serializer_options' => { allow_blessed => 1, convert_blessed => 1 }
};

=method new

Create a new object. This is called automatically by the ResultSet
object and should not be called directly.

This is overridden to provide sane defaults for the C<id> and C<created>
fields.

=cut

sub new( $class, $attrs ) {
    $attrs->{report}{id} = $attrs->{id} ||= Data::UUID->new->create_str;
    $attrs->{report}{created} = $attrs->{created} ||= DateTime->now( time_zone => 'UTC' )->datetime . 'Z';
    return $class->next::method( $attrs );
};

1;
