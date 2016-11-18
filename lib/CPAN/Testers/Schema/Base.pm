use utf8;
package CPAN::Testers::Schema::Base;
our $VERSION = '0.001';
# ABSTRACT: Base module for importing standard modules, features, and subs

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=over

=item L<Import::Base>

=back

=cut

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    'strict', 'warnings',
    feature => [qw( signatures )],
    '-warnings' => [qw( experimental::signatures )],
);

our %IMPORT_BUNDLES = (
    Test => [
        'Test::More', 'File::Temp', 'lib',
        sub {
            lib->import( 't/lib' );
            return;
        },
        'Local::Schema' => [qw( prepare_temp_schema )],
    ],
);

1;
