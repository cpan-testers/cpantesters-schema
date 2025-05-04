
=head1 DESCRIPTION

This tests the main L<CPAN::Testers::Schema> class which creates schema objects and can
populate data from the CPAN Testers API at L<http://api.cpantesters.org>.

=cut

use CPAN::Testers::Schema::Base 'Test2';
use File::Temp qw( );
use Mojo::File qw( path );
use Data::GUID qw( guid_string );
use CPAN::Testers::ReportsDir;

subtest 'write report' => sub {
    my $tmp = File::Temp->newdir;
    my $uuid = lc guid_string();
    my $content = 'report';
    my $timestamp = '2025-01-01T00:01:00';

    my $rd = CPAN::Testers::ReportsDir->new( root => $tmp->dirname );
    $rd->write( $uuid, $content, timestamp => $timestamp );

    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $got = path($tmp->dirname, 'report', $xx, $yy, $uuid);
    ok -e $got, 'report file exists';
    is $got->slurp, $content, 'report content correct';

    my $meta = path($tmp->dirname, '_meta', 'timestamp', '2025', '01', '01', '00', '01', '00');
    ok -e $meta, 'meta timestamp file exists' or say STDERR
    path($tmp->dirname, 'timestamp')->list({ dir => 1 })->each;
    is $meta->slurp, "$uuid\n", 'meta contents correct';
};

subtest 'read report' => sub {
    my $tmp = File::Temp->newdir;
    my $uuid = lc guid_string();
    my $content = 'report';
    my $timestamp = '2025-01-01T00:01:00';
    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $path = path($tmp->dirname, 'report', $xx, $yy, $uuid);
    $path->dirname->make_path;
    $path->spew($content);

    my $rd = CPAN::Testers::ReportsDir->new( root => $tmp->dirname );
    my $got_content = $rd->read( $uuid );

    is $got_content, $content;
};

subtest 'list reports by timestamp' => sub {
    my $tmp = File::Temp->newdir;
    my $rd = CPAN::Testers::ReportsDir->new( root => $tmp->dirname );
    my $day = '2025-01-01';

    my @uuids = ();
    for my $i (0..20) {
        my $uuid = lc guid_string();
        push @uuids, $uuid;
        my $content = 'report';
        my $timestamp = sprintf '%sT%02d:01:00', $day, $i;
        $rd->write( $uuid, $content, timestamp => $timestamp );
    }

    subtest 'get all' => sub {
        my @got_uuids = $rd->list( from => "${day}T00:00:00", to => "${day}T23:59:59" );
        is \@got_uuids, \@uuids;
    };

    subtest 'get some hours' => sub {
        my @got_uuids = $rd->list( from => "${day}T05:00:00", to => "${day}T08:59:59" );
        is \@got_uuids, [@uuids[5..8]];
    };

};

done_testing;
