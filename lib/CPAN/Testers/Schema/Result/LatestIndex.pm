use utf8;
package CPAN::Testers::Schema::Result::LatestIndex;
our $VERSION = '0.001';
# ABSTRACT: A cache of the latest version of a dist by author

=head1 SYNOPSIS

    my $ix = $schema->resultset( 'LatestIndex' )->find({
        dist => 'My-Dist',
        author => 'PREACTION',
    });

    $schema->resultset( 'LatestIndex' )->find_or_create({
        dist => 'My-Dist',
        author => 'PREACTION',
        uploadid => 23,
        version => '1.003',
        released => 1479410521,
        oncpan => 1,
    });

=head1 DESCRIPTION

This table stores the latest version of a dist that was uploaded by an
author. This information is used to build author pages.

This table is a cache of information already found in the C<uploads>
table. See L<CPAN::Testers::Schema::Result::Upload>.

B<XXX>: This table violates 3NF. If we want to continue doing so, we need
to have a good reason. Remove this note when we find that reason, or else
remove this module/table entirely.

=head1 SEE ALSO

=over 4

=item L<DBIx::Class::Row>

=item L<CPAN::Testers::Schema>

=item L<CPAN::Testers::Schema::Result::Upload>

=item L<CPAN::Testers::Data::Uploads>

This module processes the data and writes to this table.

=item L<http://github.com/cpan-testers/cpantesters-project>

For an overview of how the CPANTesters project works, and for
information about project goals and to get involved.

=back

=cut

=attr dist

The distribution name. Composite primary key with L</author>. Copied
from the `dist` column of the `uploads` table.

=cut

__PACKAGE__->add_column(
    dist => {
        data_type => 'varchar',
        is_nullable => 0,
    },
);

=attr author

The distribution author. Composite primary key with L</dist>. Copied
from the `author` column of the `uploads` table.

=cut

__PACKAGE__->add_column(
    author => {
        data_type => 'varchar',
        is_nullable => 0,
    }
);

__PACKAGE__->set_primary_key( qw( dist author ) );

=attr version

The version of the distribution release. Copied from the `version` column
of the `uploads` table.

=cut

__PACKAGE__->add_column(
    version => {
        data_type => 'varchar',
        is_nullable => 0,
    }
);

=attr released

The UNIX epoch of the release. Copied from the `released` column of the
`uploads` table.

=cut

__PACKAGE__->add_column(
    released => {
        data_type => 'bigint',
        is_nullable => 0,
    }
);

=attr oncpan

An integer deciding whether this release is on CPAN. If C<0>, this
release is not available on CPAN. If C<1>, this release is available on
CPAN or was reported by the CPAN upload notification system (`cpan` or
`upload` value in the `type` column on the `uploads` table). If C<2>,
this release is available on BackPAN.

=cut

__PACKAGE__->add_column(
    oncpan => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=attr uploadid

The ID of this upload from the `uploads` table.

=cut

__PACKAGE__->add_column(
    uploadid => {
        data_type => 'int',
        is_nullable => 0,
    }
);

=method upload

Get the related row from the `uploads` table. See
L<CPAN::Testers::Schema::Result::Upload>.

=cut

__PACKAGE__->belongs_to(
    upload => Uploads => 'uploadid',
);

1;
