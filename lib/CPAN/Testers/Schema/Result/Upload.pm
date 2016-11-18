use utf8;
package CPAN::Testers::Schema::Result::Upload;
our $VERSION = '0.002';
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

=head1 SEE ALSO

=over 4

=item L<DBIx::Class::Row>

=item L<CPAN::Testers::Schema>

=item L<CPAN::Testers::Data::Uploads>

This module processes the data and writes to this table.

=item L<http://github.com/cpan-testers/cpantesters-project>

For an overview of how the CPANTesters project works, and for
information about project goals and to get involved.

=back

=cut

use CPAN::Testers::Schema::Base;
use base 'DBIx::Class::Core';

__PACKAGE__->table( 'uploads' );

=attr uploadid

The ID of this upload. Auto-generated.

=cut

__PACKAGE__->add_column(
    uploadid => {
        data_type => 'int',
        is_auto_increment => 1,
        is_nullable => 0,
    }
);
__PACKAGE__->set_primary_key( 'uploadid' );

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

__PACKAGE__->add_columns(
    type => {
        data_type         => 'varchar',
        is_nullable       => 0,
    },
);

=attr author

The PAUSE ID of the user who uploaded this distribution.

=cut

__PACKAGE__->add_columns(
    author => {
        data_type         => 'varchar',
        is_nullable       => 0,
    },
);

=attr dist

The distribution name, parsed from the uploaded file's name using
L<CPAN::DistnameInfo>.

=cut

__PACKAGE__->add_columns(
    dist => {
        data_type         => 'varchar',
        is_nullable       => 0,
    },
);

=attr version

The version of the distribution, parsed from the uploaded file's name
using L<CPAN::DistnameInfo>.

=cut

__PACKAGE__->add_columns(
    version => {
        data_type         => 'varchar',
        is_nullable       => 0,
    },
);

=attr filename

The full file name uploaded to CPAN, without the author directory prefix.

=cut

__PACKAGE__->add_columns(
    filename => {
        data_type         => 'varchar',
        is_nullable       => 0,
    },
);

=attr released

The UNIX epoch of the dist release. Calculated from the file's modified
time, as synced by the CPAN mirror sync system, or from the upload
notification message time from the NNTP group.

=cut

__PACKAGE__->add_columns(
    released => {
        data_type         => 'bigint',
        is_nullable       => 0,
    },
);

1;
