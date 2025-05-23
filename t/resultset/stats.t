
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::Stats> module which
queries for L<CPAN::Testers::Schema::Result::Stats> objects.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>

=cut

use utf8;
use CPAN::Testers::Schema::Base 'Test';
use CPAN::Testers::Schema;

use Scalar::Util 'looks_like_number';

my $schema = CPAN::Testers::Schema->connect( 'dbi:SQLite::memory:', undef, undef, { ignore_version => 1 } );
$schema->deploy;
my $rs = $schema->resultset('Stats');

my $upload_id = 0;
subtest 'insert_test_report' => sub {
    my $report = $schema->resultset('TestReport')->create({
        id => 'd0ab4d36-3343-11e7-b830-917e22bfee97',
        created => DateTime->new(
            year => 2017,
            month => 05,
            day => 07,
            hour => 16,
            minute => 40,
        ),
        report => {
            reporter => {
                name  => 'Andreas J. Köenig',
                email => 'andreas.koenig.gmwojprw@franz.ak.mind.de',
            },
            environment => {
                system => {
                    osname => 'linux',
                    osversion => '4.8.0-2-amd64',
                },
                language => {
                    name => 'Perl 5',
                    version => '5.22.2',
                    archname => 'x86_64-linux',
                },
            },
            distribution => {
                name => 'Sorauta-SVN-AutoCommit',
                version => '0.02',
            },
            result => {
                grade => 'FAIL',
            },
        },
    });

    my $stat_id;
    subtest 'upload does not exist' => sub {
        my $stat = eval { $rs->insert_test_report($report) };
        my $err = $@;
        ok $stat, 'stat record was still created';
        $stat_id = $stat->id;

        ok looks_like_number($stat->id), 'an id was generated';
        is $stat->guid, 'd0ab4d36-3343-11e7-b830-917e22bfee97', 'correct guid';
        is $stat->state, 'fail', 'correct test state';
        is $stat->postdate, 201705, 'correct postdate';
        is $stat->tester, '"Andreas J. K&#246;enig" <andreas.koenig.gmwojprw@franz.ak.mind.de>', 'correct tester';
        is $stat->dist, 'Sorauta-SVN-AutoCommit', 'correct dist';
        is $stat->version, '0.02', 'correct version';
        is $stat->platform, 'x86_64-linux', 'correct platform';
        is $stat->perl, '5.22.2', 'correct perl';
        is $stat->osname, 'linux', 'correct osname';
        is $stat->osvers, '4.8.0-2-amd64', 'correct osvers';
        is $stat->fulldate, 201705071640, 'correct fulldate';
        is $stat->type, 2, 'correct type';

        # Provisional upload record was created
        my $upload = $schema->resultset('Upload')->find({ dist => 'Sorauta-SVN-AutoCommit', version => '0.02' });
        ok $upload, 'provisional upload record created';
        is $upload->type, 'unknown', 'provisional record is "unknown"';
        is $stat->uploadid, $upload->id, 'stat is related to upload';
        $upload_id = $upload->id;
    };

    subtest 'reprocess report' => sub {
        $report->report->{result}{grade} = 'PASS';
        $report->update({ report => $report->report });
        my $stat = $rs->insert_test_report( $report );
        is $stat->id, $stat_id, 'stat is updated, not duplicated';
        is $stat->guid, 'd0ab4d36-3343-11e7-b830-917e22bfee97', 'correct guid';
        is $stat->state, 'pass', 'correctly changed test state';
    };
};

subtest 'since' => sub {
    my $rs = $schema->resultset( 'Stats' )->since( '2017-05-07T16:40:00' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ],
        [
            {
                'dist' => 'Sorauta-SVN-AutoCommit',
                'fulldate' => '201705071640',
                'guid' => 'd0ab4d36-3343-11e7-b830-917e22bfee97',
                'id' => 1,
                'osname' => 'linux',
                'osvers' => '4.8.0-2-amd64',
                'perl' => '5.22.2',
                'platform' => 'x86_64-linux',
                'postdate' => 201705,
                'state' => 'pass',
                'tester' => '"Andreas J. K&#246;enig" <andreas.koenig.gmwojprw@franz.ak.mind.de>',
                'type' => 2,
                'uploadid' => $upload_id,
                'version' => '0.02',
            },
        ],
        'get items since 2017-05-07'
            or diag explain [ $rs->all ];
};

subtest 'perl_maturity' => sub {
    my $perl_devel = $schema->resultset( 'PerlVersion' )->create({ version => '5.25.0' });
    my $perl_patch = $schema->resultset( 'PerlVersion' )->create({ version => '5.24.0 patch 123' });
    my $perl_stable = $schema->resultset( 'PerlVersion' )->create({ version => '5.22.2' });

    my $devel_stat = $schema->resultset( 'Stats' )->create({
        'dist' => 'Sorauta-SVN-AutoCommit',
        'fulldate' => '201705071643',
        'guid' => '00000000-3343-11e7-b830-917e22bfee97',
        'id' => 2,
        'osname' => 'linux',
        'osvers' => '4.8.0-2-amd64',
        'perl' => '5.25.0',
        'platform' => 'x86_64-linux',
        'postdate' => 201705,
        'state' => 'pass',
        'tester' => '"Andreas J. K&#246;enig" <andreas.koenig.gmwojprw@franz.ak.mind.de>',
        'type' => 2,
        'uploadid' => 169497,
        'version' => '0.02',
    });

    my $patch_stat = $schema->resultset( 'Stats' )->create({
        'dist' => 'Sorauta-SVN-AutoCommit',
        'fulldate' => '201705071643',
        'guid' => '11111111-3343-11e7-b830-917e22bfee97',
        'id' => 3,
        'osname' => 'linux',
        'osvers' => '4.8.0-2-amd64',
        'perl' => '5.24.0 patch 123',
        'platform' => 'x86_64-linux',
        'postdate' => 201705,
        'state' => 'pass',
        'tester' => '"Andreas J. K&#246;enig" <andreas.koenig.gmwojprw@franz.ak.mind.de>',
        'type' => 2,
        'uploadid' => 169497,
        'version' => '0.02',
    });

    my $dev_rs = $schema->resultset( 'Stats' )->perl_maturity( 'dev' );
    my @dev_rows = $dev_rs->all;
    is scalar @dev_rows, 2, '2 tests reported for a devel perl';
    is_deeply [ sort map { $_->guid } @dev_rows ],
        [ '00000000-3343-11e7-b830-917e22bfee97', '11111111-3343-11e7-b830-917e22bfee97' ],
        'correct guids for devel perl';

    my $stable_rs = $schema->resultset( 'Stats' )->perl_maturity( 'stable' );
    my @stable_rows = $stable_rs->all;
    is scalar @stable_rows, 1, '1 test reported for a stable perl';
    is $stable_rows[0]->guid, 'd0ab4d36-3343-11e7-b830-917e22bfee97',
        'correct guid for stable perl';
};

done_testing;



