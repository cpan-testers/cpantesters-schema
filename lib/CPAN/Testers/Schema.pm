package CPAN::Testers::Schema;
our $VERSION = '0.025';
# ABSTRACT: Schema for CPANTesters database processed from test reports

=head1 SYNOPSIS

    my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );
    my $rs = $schema->resultset( 'Stats' )->search( { dist => 'Test-Simple' } );
    for my $row ( $rs->all ) {
        if ( $row->state eq 'fail' ) {
            say sprintf "Fail report from %s: http://cpantesters.org/cpan/report/%s",
                $row->tester, $row->guid;
        }
    }

=head1 DESCRIPTION

This is a L<DBIx::Class> Schema for the CPANTesters statistics database.
This database is generated by processing the incoming data from L<the
CPANTesters Metabase|http://metabase.cpantesters.org>, and extracting
the useful fields like distribution, version, platform, and others (see
L<CPAN::Testers::Schema::Result::Stats> for a full list).

This is its own distribution so that it can be shared by the backend
processing, data APIs, and the frontend web application.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::Stats>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base;
use File::Share qw( dist_dir );
use Path::Tiny qw( path );
use List::Util qw( uniq );
use base 'DBIx::Class::Schema';
use Mojo::UserAgent;
use DateTime::Format::ISO8601;

__PACKAGE__->load_namespaces;
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory( dist_dir( 'CPAN-Testers-Schema' ) );

=method connect_from_config

    my $schema = CPAN::Testers::Schema->connect_from_config( %extra_conf );

Connect to the MySQL database using a local MySQL configuration file
in C<$HOME/.cpanstats.cnf>. This configuration file should look like:

    [client]
    host     = ""
    database = cpanstats
    user     = my_usr
    password = my_pwd

See L<DBD::mysql/mysql_read_default_file>.

C<%extra_conf> will be added to the L<DBIx::Class::Schema/connect>
method in the C<%dbi_attributes> hashref (see
L<DBIx::Class::Storage::DBI/connect_info>).

=cut

# Convenience connect method
sub connect_from_config ( $class, %config ) {
    my $schema = $class->connect(
        "DBI:mysql:mysql_read_default_file=$ENV{HOME}/.cpanstats.cnf;".
        "mysql_read_default_group=application;mysql_enable_utf8=1",
        undef,  # user
        undef,  # pass
        {
            AutoCommit => 1,
            RaiseError => 1,
            mysql_enable_utf8 => 1,
            quote_char => '`',
            name_sep   => '.',
            %config,
        },
    );
    return $schema;
}

=method ordered_schema_versions

Get the available schema versions by reading the files in the share
directory. These versions can then be upgraded to using the
L<cpantesters-schema> script.

=cut

sub ordered_schema_versions( $self ) {
    my @versions =
        uniq sort
        map { /[\d.]+-([\d.]+)/ }
        grep { /CPAN-Testers-Schema-[\d.]+-[\d.]+-MySQL[.]sql/ }
        path( dist_dir( 'CPAN-Testers-Schema' ) )->children;
    return '0.000', @versions;
}

=method populate_from_api

    $schema->populate_from_api( \%search, @tables );

Populate the given tables from the CPAN Testers API (L<http://api.cpantesters.org>).
C<%search> has the following keys:

=over

=item dist

A distribution to populate

=item version

A distribution version to populate

=item author

Populate an author's data

=back

The available C<@tables> are:

=over

=item * upload

=item * release

=item * summary

=item * report

=back

=cut

sub populate_from_api( $self, $search, @tables ) {
    my $ua = $self->{_ua} ||= Mojo::UserAgent->new;
    $ua->inactivity_timeout( 120 );
    my $base_url = $self->{_url} ||= 'http://api.cpantesters.org/v3';
    my $dtf = DateTime::Format::ISO8601->new();

    # Establish dependencies
    my @order = qw( upload summary release report );
    my $match_tables = join '|', @order;
    if ( my @unknown = grep { !/^$match_tables$/ } @tables ) {
        die 'Unknown table(s): ', join ', ', @unknown;
    }

    my %tables = map {; $_ => 1 } @tables;
    # release depends on data in uploads and summary
    if ( $tables{ release } ) {
        @tables{qw( upload summary )} = ( 1, 1 );
    }
    # In order to link the report from the dist via the API, we need
    # to get the summaries first
    if ( $tables{ report } ) {
        @tables{qw( summary )} = ( 1 );
    }
    # summary depends on data in uploads
    if ( $tables{ summary } ) {
        @tables{qw( upload )} = ( 1 );
    }

    # ; use Data::Dumper;
    # ; say "Fetching tables: " . Dumper \%tables;

    for my $table ( @order ) {
        next unless $tables{ $table };
        my $url = $base_url;
        if ( $table eq 'upload' ) {
            $url .= '/upload';
            if ( $search->{dist} ) {
                $url .= '/dist/' . $search->{dist};
            }
            elsif ( $search->{author} ) {
                $url .= '/author/' . $search->{author};
            }
            my $tx = $ua->get( $url );
            if ( my $err = $tx->error ) {
                die sprintf q{Error fetching table '%s': (%s) %s}, $table, $err->{code} // 'XXX', $err->{message};
            }
            my @rows = map {
                $_->{released} = $dtf->parse_datetime( $_->{released} )->epoch;
                $_->{type} = 'cpan';
                $_;
            } $tx->res->json->@*;
            $self->resultset( 'Upload' )->populate( \@rows );
        }

        if ( $table eq 'summary' ) {
            $url .= '/summary';
            if ( $search->{dist} ) {
                $url .= '/' . $search->{dist};
                if ( $search->{version} ) {
                    $url .= '/' . $search->{version};
                }
            }
            my $tx = $ua->get( $url );
            if ( my $err = $tx->error ) {
                die sprintf q{Error fetching table '%s': (%s) %s}, $table, $err->{code} // 'XXX', $err->{message};
            }
            my @rows = map {
                my $dt = $dtf->parse_datetime( delete $_->{date} );
                $_->{postdate} = $dt->strftime( '%Y%m' );
                $_->{fulldate} = $dt->strftime( '%Y%m%d%H%M' );
                $_->{state} = delete $_->{grade};
                $_->{type} = 2;
                $_->{tester} = delete $_->{reporter};
                $_->{uploadid} = $self->resultset( 'Upload' )
                                 ->search({ $_->%{qw( dist version )} })
                                 ->first->id;
                $_;
            } $tx->res->json->@*;
            # ; use Data::Dumper;
            # ; say "Populate summary: " . Dumper \@rows;
            for my $perl ( uniq map { $_->{perl} } @rows ) {
                $self->resultset( 'PerlVersion' )->find_or_create({
                    version => $perl,
                });
            }
            $self->resultset( 'Stats' )->populate( \@rows );
        }

        if ( $table eq 'release' ) {
            $url .= '/release';
            if ( $search->{dist} ) {
                $url .= '/dist/' . $search->{dist};
                if ( $search->{version} ) {
                    $url .= '/' . $search->{version};
                }
            }
            elsif ( $search->{author} ) {
                $url .= '/author/' . $search->{author};
            }
            my $tx = $ua->get( $url );
            if ( my $err = $tx->error ) {
                die sprintf q{Error fetching table '%s': (%s) %s}, $table, $err->{code} // 'XXX', $err->{message};
            }
            my @rows = map {
                delete $_->{author}; # Author is from Upload
                my $stats_rs = $self->resultset( 'Stats' )
                           ->search({ $_->%{qw( dist version )} });
                $_->{id} = $stats_rs->get_column( 'id' )->max;
                $_->{guid} = $stats_rs->find( $_->{id} )->guid;
                my $upload = $self->resultset( 'Upload' )
                             ->search({ $_->%{qw( dist version )} })
                             ->first;
                $_->{oncpan} = $upload->type eq 'cpan';
                $_->{uploadid} = $upload->id;
                # XXX These are just wrong
                $_->{distmat} = 1;
                $_->{perlmat} = 1;
                $_->{patched} = 1;
                $_;
            } $tx->res->json->@*;
            # ; use Data::Dumper;
            # ; say "Populate release: " . Dumper \@rows;
            $self->resultset( 'Release' )->populate( \@rows );
        }

        if ( $table eq 'report' ) {
            $url .= '/report';

            # There is no direct API to get reports by dist/version, BUT
            # we already have summaries loaded in the database so we can
            # get the GUIDs out of there.
            Mojo::Promise->map(
                { concurrency => 8 },
                sub( $summary ) {
                    my $report_url = join '/', $url, $summary->guid;
                    return $ua->get_p( $report_url );
                },
                $self->resultset( 'Stats' )->search( $search )->all,
            )->then(
                # Success
                sub {
                    my $tx = shift->[0];
                    if ( my $err = $tx->error ) {
                        die sprintf q{Error fetching table '%s': (%s) %s}, $table, $err->{code} // 'XXX', $err->{message};
                    }
                    my $report = $tx->res->json;
                    $self->resultset( 'TestReport' )->create({
                        id => $report->{id},
                        report => $report,
                    });
                },
            )->catch(
                sub {
                    warn 'Problem fetching report: ' . join ' ', @_;
                },
            )->wait;
        }
    }
}

1;
