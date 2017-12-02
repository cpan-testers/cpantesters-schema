
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::Release> module which
queries for L<CPAN::Testers::Schema::Result::Release> objects.

=head1 SEE ALSO

=over

=item L<DBIx::Class::ResultSet>

=back

=cut

use CPAN::Testers::Schema::Base 'Test';

my %default = (
    oncpan => 1,
    perlmat => 1,
    patched => 1,
);

my %stats_default = (
    tester => 'doug@example.com (Doug Bell)',
    platform => 'darwin-2level',
    perl => '5.22.0',
    osname => 'darwin',
    osvers => '10.8.0',
    type => 2,
);

my %data = (

    Upload => [
        {
            uploadid => 1,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Dist',
            version => '1.001',
            filename => 'My-Dist-1.001.tar.gz',
            released => 1479524600,
        },
        {
            uploadid => 2,
            type => 'cpan',
            author => 'POSTACTION',
            dist => 'My-Dist',
            version => '1.002',
            filename => 'My-Dist-1.002.tar.gz',
            released => 1479524700,
        },
        {
            uploadid => 3,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Other',
            version => '1.000',
            filename => 'My-Other-1.000.tar.gz',
            released => 1479524800,
        },
        {
            uploadid => 4,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Other',
            version => '1.001',
            filename => 'My-Other-1.001.tar.gz',
            released => 1479524900,
        },
    ],

    Stats => [
        {
            %stats_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.001',
            uploadid => 1,
            # Stats info
            id => 1,
            guid => '00000000-0000-0000-0000-000000000001',
            state => 'pass',
            postdate => '201608',
            fulldate => '201608120401',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.001',
            uploadid => 1,
            # Stats info
            id => 2,
            guid => '00000000-0000-0000-0000-000000000002',
            state => 'fail',
            postdate => '201608',
            fulldate => '201608120000',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Dist',
            version => '1.002',
            uploadid => 2,
            # Stats info
            id => 3,
            guid => '00000000-0000-0000-0000-000000000003',
            state => 'fail',
            postdate => '201608',
            fulldate => '201608200000',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Other',
            version => '1.000',
            uploadid => 3,
            # Stats info
            id => 4,
            guid => '00000000-0000-0000-0000-000000000004',
            state => 'pass',
            postdate => '201609',
            fulldate => '201609180000',
        },
        {
            %stats_default,
            # Upload info
            dist => 'My-Other',
            version => '1.001',
            uploadid => 4,
            # Stats info
            id => 5,
            guid => '00000000-0000-0000-0000-000000000005',
            state => 'pass',
            postdate => '201609',
            fulldate => '201609180100',
        },
    ],

    Release => [
        {
            %default,
            distmat => 1,
            # Upload info
            dist => 'My-Dist',
            version => '1.001',
            uploadid => 1,
            # Stats
            id => 2,
            guid => '00000000-0000-0000-0000-000000000002',
            # Release summary
            pass => 1,
            fail => 1,
            na => 0,
            unknown => 0,
        },
        {
            %default,
            distmat => 1,
            # Upload info
            dist => 'My-Dist',
            version => '1.002',
            uploadid => 2,
            # Stats
            id => 3,
            guid => '00000000-0000-0000-0000-000000000003',
            # Release summary
            pass => 1,
            fail => 0,
            na => 0,
            unknown => 0,
        },
        {
            %default,
            distmat => 1,
            # Upload info
            dist => 'My-Other',
            version => '1.000',
            uploadid => 3,
            # Stats
            id => 4,
            guid => '00000000-0000-0000-0000-000000000004',
            # Release summary
            pass => 1,
            fail => 0,
            na => 0,
            unknown => 0,
        },
        {
            %default,
            distmat => 2,
            # Upload info
            dist => 'My-Other',
            version => '1.001',
            uploadid => 4,
            # Stats
            id => 5,
            guid => '00000000-0000-0000-0000-000000000005',
            # Release summary
            pass => 1,
            fail => 0,
            na => 0,
            unknown => 0,
        },
    ],
);

if ( !eval { require Test::mysqld; 1 } ) {
    plan skip_all => 'Requires Test::mysqld';
    return;
}

no warnings 'once';
my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    },
);
if ( !$mysqld ) {
    plan skip_all => "Failed to start up server: $Test::mysqld::errstr";
    return;
}

my ( undef, $version ) = DBI->connect( $mysqld->dsn(dbname => 'test') )->selectrow_array( q{SHOW VARIABLES LIKE 'version'} );
my ( $mversion ) = $version =~ /^(\d+[.]\d+)/;
if ( $mversion < 5.7 ) {
    plan skip_all => "Need MySQL version 5.7 or higher. This is $version";
    return;
}

my $schema = CPAN::Testers::Schema->connect(
    $mysqld->dsn(dbname => 'test'), undef, undef, { ignore_version => 1 },
);
$schema->deploy;

# Order is important else we can get a FK error on insert
$schema->populate( $_, $data{ $_ } ) for ( qw/ Upload Stats Release / );

my $rs = $schema->resultset( 'Release' );
$rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

is_deeply [ $rs->all ], $data{Release}, 'sanity check that items were inserted'
    or diag explain [ $rs->all ];

subtest 'since' => sub {
    my $rs = $schema->resultset( 'Release' )->since( '2016-08-20T00:00:00' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Release}->@[1..3] ], 'get items since 2016-08-20'
        or diag explain [ $rs->all ];
};

subtest 'maturity' => sub {
    subtest 'stable only' => sub {
        my $rs = $schema->resultset( 'Release' )->maturity( 'stable' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}->@[0..2] ], 'get only stable items'
            or diag explain [ $rs->all ];
    };

    subtest 'development only' => sub {
        my $rs = $schema->resultset( 'Release' )->maturity( 'dev' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}->@[3] ], 'get only dev items'
            or diag explain [ $rs->all ];
    };
};

subtest 'limit_per_dist' => sub {
    my $rs = $schema->resultset( 'Release' )->limit_per_dist( 1 );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Release}->@[1,3] ], 'limit 1 result per dist'
        or diag explain [ $rs->all ];
};

subtest 'since and maturity' => sub {
     my $rs = $schema->resultset( 'Release' )
       ->since( '2016-08-20T00:00:00' )
       ->maturity( 'stable' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Release}->@[1,2] ], 'get stable items since 2016-08-20'
        or diag explain [ $rs->all ];
};

subtest 'since and limit_per_dist' => sub {
     my $rs = $schema->resultset( 'Release' )
       ->since( '2016-08-20T00:00:00' )
       ->limit_per_dist( 1 );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Release}->@[1,3] ], 'get one item per dist since 2016-08-20'
        or diag explain [ $rs->all ];
};

subtest 'maturity and limit_per_dist' => sub {
    my $rs = $schema->resultset( 'Release' )
       ->maturity( 'stable' )
       ->limit_per_dist( 1, maturity => 1 );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
$schema->storage->debug(1);
    my $res = $rs->all;
$schema->storage->debug(0);
    is_deeply [ $rs->all ], [ $data{Release}->@[1,2] ], 'get one stable item per dist'
        or diag explain [ $rs->all ];
};


subtest 'by_dist' => sub {
    my $rs = $schema->resultset( 'Release' )->by_dist( 'My-Dist' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Release}->@[0,1] ], 'get items for My-Dist'
        or diag explain [ $rs->all ];

    subtest 'since' => sub {
        my $rs = $schema->resultset( 'Release' )->by_dist( 'My-Dist' )
                ->since( '2016-08-20T00:00:00' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}[1] ], 'get items for My-Dist'
            or diag explain [ $rs->all ];
    };

    subtest 'maturity' => sub {
        my $rs = $schema->resultset( 'Release' )->by_dist( 'My-Other' )
                ->maturity( 'stable' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}[2] ], 'get stable items for My-Other'
            or diag explain [ $rs->all ];
    };

    subtest 'limit_per_dist' => sub {
        my $rs = $schema->resultset( 'Release' )->by_dist( 'My-Dist' )
                ->limit_per_dist( 1 );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}[1] ], 'get maximum 1 item for My-Dist'
            or diag explain [ $rs->all ];
    };
};

subtest 'by_author' => sub {
    my $rs = $schema->resultset( 'Release' )->by_author( 'PREACTION' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Release}->@[0,2,3] ], 'get items for PREACTION'
        or diag explain [ $rs->all ];

    subtest 'since' => sub {
        my $rs = $schema->resultset( 'Release' )->by_author( 'PREACTION' )
                ->since( '2016-08-20T00:00:00' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}->@[2,3] ], 'get items for PREACTION'
            or diag explain [ $rs->all ];
    };

    subtest 'maturity' => sub {
        my $rs = $schema->resultset( 'Release' )->by_author( 'PREACTION' )
                ->maturity( 'dev' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}[3] ], 'get dev items for PREACTION'
            or diag explain [ $rs->all ];
    };

    subtest 'limit_per_dist' => sub {
        my $rs = $schema->resultset( 'Release' )->by_author( 'PREACTION' )
                ->limit_per_dist( 1, author => 'PREACTION' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Release}->@[0,3] ], 'get maximum 1 item for each PREACTION dist'
            or diag explain [ $rs->all ];
    };
};

done_testing;

