
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::TestReport> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';
use Scalar::Util qw( looks_like_number );
my $schema = prepare_temp_schema;
my $HEX = qr{[A-Fa-f0-9]};

subtest 'column defaults' => sub {
    my $row = $schema->resultset( 'TestReport' )->create( { report => '{}' } );
    like $row->id, qr{${HEX}{8}-${HEX}{4}-${HEX}{4}-${HEX}{4}-${HEX}{12}},
        'GUID is created automatically';
    ok looks_like_number $row->created, 'created timestamp looks like number';
    cmp_ok $row->created, '>', time-60, 'was created in the last 60 seconds';
};

done_testing;
