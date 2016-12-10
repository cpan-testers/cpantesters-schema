
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::Upload> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';

subtest 'create' => sub {
    my $schema = prepare_temp_schema;
    my %upload = (
        type => 'cpan',
        dist => 'My-Dist',
        version => '1.000',
        author => 'PREACTION',
        filename => 'My-Dist-1.000.tar.gz',
        released => 1366237867,
    );
    my $upload = $schema->resultset( 'Upload' )->create( \%upload );
    ok $upload, 'row is created';
    ok $upload->uploadid, 'uploadid is created';

    isa_ok $upload->released, 'DateTime', 'released column is auto-inflated to DateTime object';
    is $upload->released->epoch, $upload{ released }, 'datetime is correct';
};

done_testing;
