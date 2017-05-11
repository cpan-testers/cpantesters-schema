package CPAN::Testers::Schema::Result::TestReport;
our $VERSION = '0.006';
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
table 'test_report';

=attr id

The UUID of this report stored in standard hex string representation.

=cut

primary_column 'id', {
    data_type => 'char',
    size => 36,
    is_nullable => 0,
};

=attr report

The full JSON report.

XXX: Describe the format a little and link to the main schema OpenAPI
format on http://api.cpantesters.org

=cut

column 'report', {
    data_type => 'JSON',
};

1;
