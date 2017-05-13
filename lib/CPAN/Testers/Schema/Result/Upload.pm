use utf8;
package CPAN::Testers::Schema::Result::Upload;
our $VERSION = '0.010';
# ABSTRACT: Information about uploads to CPAN

=head1 SYNOPSIS

    my $upload = $schema->resultset( 'Upload' )
        ->search( dist => 'My-Dist', version => '0.01' )->first;

    say $row->author . " released as " . $row->filename;
    say scalar localtime $row->released;
    if ( $row->type eq 'backpan' ) {
        say "Deleted from CPAN";
    }

    my $new_upload = $schema->resultset( 'Upload' )->create({
        type => 'cpan',
        dist => 'My-Dist',
        version => '1.001',
        author => 'PREACTION',
        filename => 'My-Dist-1.001.tar.gz',
        released => 1366237867,
    });

=head1 DESCRIPTION

This table contains information about uploads to CPAN, including who
uploaded it, when it was uploaded, and when it was deleted (and thus
only available to BackPAN).

B<NOTE>: Since files can be deleted from PAUSE, and new files uploaded
with the same name, distribution, and version, there may be duplicate
C<< dist => version >> pairs in this table. This table does not
determine which packages were authorized and indexed by PAUSE for
installation by CPAN clients.

This data is read directly from the local CPAN mirror by
L<CPAN::Testers::Data::Uploads> and written to this table.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=cut

use CPAN::Testers::Schema::Base 'Result';
__PACKAGE__->load_components( 'InflateColumn' );
table 'uploads';

=attr uploadid

The ID of this upload. Auto-generated.

=cut

primary_column uploadid => {
    data_type => 'int',
    extra     => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
};

=attr type

This column indicates where the distribution is. It can be one of three values:

=over 4

=item cpan

This distribution is on CPAN

=item backpan

This distribution has been deleted from CPAN and is only available on BackPAN

=item upload

This distribution has been reported via NNTP (nntp.perl.org group perl.cpan.uploads),
but has not yet been seen on CPAN itself.

=back

=cut

column type => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

=attr author

The PAUSE ID of the user who uploaded this distribution.

=cut

column author => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

=attr dist

The distribution name, parsed from the uploaded file's name using
L<CPAN::DistnameInfo>.

=cut

column dist => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

=attr version

The version of the distribution, parsed from the uploaded file's name
using L<CPAN::DistnameInfo>.

=cut

column version => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

=attr filename

The full file name uploaded to CPAN, without the author directory prefix.

=cut

column filename => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

=attr released

The date/time of the dist release. Calculated from the file's modified
time, as synced by the CPAN mirror sync system, or from the upload
notification message time from the NNTP group.

Inflated from a UNIX epoch into a L<DateTime> object.

=cut

column released => {
    data_type         => 'bigint',
    is_nullable       => 0,
    inflate_datetime  => 1,
};

__PACKAGE__->inflate_column(
    released => {
        deflate => sub( $value, $event ) {
            ref $value ? $value->epoch : $value
        },
        inflate => sub( $value, $event ) {
            DateTime->from_epoch(
                epoch => $value,
                time_zone => 'UTC',
                formatter => 'CPAN::Testers::Schema::DateTime::Formatter',
            );
        },
    },
);

package
    CPAN::Testers::Schema::DateTime::Formatter {
    sub format_datetime( $self, $dt ) {
        # XXX Replace this with DateTime::Format::ISO8601 when
        # https://github.com/jhoblitt/DateTime-Format-ISO8601/pull/2
        # is merged
        my $cldr = $dt->nanosecond % 1000000 ? 'yyyy-MM-ddTHH:mm:ss.SSSSSSSSS'
                 : $dt->nanosecond ? 'yyyy-MM-ddTHH:mm:ss.SSS'
                 : 'yyyy-MM-ddTHH:mm:ss';

        my $tz;
        if ( $dt->time_zone->is_utc ) {
            $tz = 'Z';
        }
        else {
            my $offset = $dt->time_zone->offset_for_datetime( $dt );
            $tz = DateTime::TimeZone->offset_as_string( $offset );
            substr $tz, 3, 0, ':';
        }

        return $dt->format_cldr( $cldr ) . $tz;
    }
}

1;
