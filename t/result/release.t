
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::Release> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';

subtest 'upload relationship' => sub {
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

    my %release = (
        dist => 'My-Dist',
        version => '1.000',
        id => 1,
        guid => '00000000-0000-0000-0000-000000000000',
        oncpan => 1,
        distmat => 1,
        perlmat => 1,
        patched => 1,
        pass => 35,
        fail => 1,
        na => 0,
        unknown => 0,
        uploadid => $upload->uploadid,
    );
    my $release = $schema->resultset( 'Release' )->create( \%release );

    ok $release->upload, 'upload relationship exists';
    is $release->upload->uploadid, $upload->uploadid, 'correct upload is related';
};

done_testing;
