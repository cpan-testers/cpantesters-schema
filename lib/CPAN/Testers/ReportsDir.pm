package CPAN::Testers::ReportsDir;
our $VERSION = '0.028';

=head1 SYNOPSIS

    my $rdir = CPAN::Testers::ReportsDir->new(root => $root_path);

=head1 DESCRIPTION

This module manages a plain-text database of CPAN Testers reports, along
with some metadata for basic synchronization querying.

=head1 SEE ALSO

=cut

use CPAN::Testers::Schema::Base;
use Mojo::Base -base, -signatures;
use Mojo::File qw( path );
use Time::Piece;
use Scalar::Util qw( blessed );

=attr root

The root directory of the reports. Individual reports are stored in directories
named after the reports' UUID. Additional metadata files are stored in '_meta'.

=cut

has root => sub { die "root is required" };

=method write

Write a new report to the directory. The C<$uuid> is required and is
used as the path to write to. C<$content> is a string of content. This
also updates the metadata files.

C<%opt> is an optional set of metadata with the following keys:

    timestamp - The timestamp of the report in ISO8601 format

=cut

sub write( $self, $uuid, $content, %opt ) {
    my $path = $self->_uuid_path($uuid);
    $path->dirname->make_path;
    $path->spew($content);

    my $timestamp = _to_tp( $opt{timestamp} // Time::Piece->new );
    $self->_add_timestamp( $uuid, $timestamp );
}

sub _uuid_path( $self, $uuid ) {
    $uuid = lc $uuid;
    my ($xx, $yy) = $uuid =~ m{^([0-9a-f]{2})([0-9a-f]{2})};
    my $path = path( $self->root, 'report', $xx, $yy, $uuid );
    return $path;
}

sub _two_digit( $x ) {
    return sprintf '%02d', $x;
}

sub _tp_path( $tp ) {
    return ($tp->year, _two_digit($tp->mon), _two_digit($tp->mday), _two_digit($tp->hour), _two_digit($tp->min), _two_digit($tp->sec) );
}

sub _meta_path( $self, $type, @parts ) {
    return path( $self->root, '_meta', $type, @parts );
}

sub _add_timestamp( $self, $uuid, $t=Time::Piece->new ) {
    my $path = $self->_meta_path( timestamp => _tp_path($t) );
    $path->dirname->make_path;
    my $fh = $path->open('>>');
    say {$fh} $uuid;
    close $fh;
}

=method read

Read a report by UUID. Returns the string content of the report.

=cut

sub read( $self, $uuid ) {
    return $self->_uuid_path($uuid)->slurp;
}

=method list

List reports by metadata. Returns a list of report UUIDs.

Currently, only report timestamp is available to search using the 'from'
and 'to' search fields.

    from - Timestamp to start search from in ISO8601 format
    to - Timestamp to search to (inclusive) in ISO8601 format

=cut

sub list( $self, %search ) {
    my @uuids = ();
    if ($search{from}) {
        $search{to} //= Time::Piece->new;
        my $from = _to_tp( $search{from} );
        my $to = _to_tp( $search{to} );

        my $from_path = $self->_meta_path( timestamp => _tp_path($from) );
        my $to_path = $self->_meta_path( timestamp => _tp_path($to) );

        my @glob_path_parts = ();
        if ($from->year eq $to->year) {
            push @glob_path_parts, $from->year;
            if ($from->mon eq $to->mon) {
                push @glob_path_parts, _two_digit($from->mon);
                if ($from->mday eq $to->mday) {
                    push @glob_path_parts, _two_digit($from->mday);
                    if ($from->hour eq $to->hour) {
                        push @glob_path_parts, _two_digit($from->hour);
                        if ($from->min eq $to->min) {
                            push @glob_path_parts, _two_digit($from->min);
                            if ($from->sec eq $to->sec) {
                                push @glob_path_parts, _two_digit($from->sec);
                            }
                            else {
                                push @glob_path_parts, '*';
                            }
                        }
                        else {
                            push @glob_path_parts, ('*')x2;
                        }
                    }
                    else {
                        push @glob_path_parts, ('*')x3;
                    }
                }
                else {
                    push @glob_path_parts, ('*')x4;
                }
            }
            else {
                push @glob_path_parts, ('*')x5;
            }
        }
        else {
            push @glob_path_parts, ('*')x6;
        }

        my $glob_path = $self->_meta_path( timestamp => @glob_path_parts );
        while ( my $path = glob( "$glob_path" ) ) {
            if ( $path gt "$to_path" ) {
                last;
            }
            if ( $path lt "$from_path" ) {
                next;
            }
            push @uuids, grep !!$_, split /\n/, path( $path )->slurp;
        }

    }
    return @uuids;
}

sub _to_tp( $maybe_tp ) {
    return blessed $maybe_tp ? $maybe_tp : Time::Piece->strptime( $maybe_tp, '%Y-%m-%dT%H:%M:%S' );
}

1;
