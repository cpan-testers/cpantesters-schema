use utf8;
package CPAN::Testers::Schema::Base;
our $VERSION = '0.017';
# ABSTRACT: Base module for importing standard modules, features, and subs

=head1 SYNOPSIS

    # lib/CPAN/Testers/Schema/MyModule.pm
    package CPAN::Testers::Schema::MyModule;
    use CPAN::Testers::Schema::Base;

    # t/mytest.t
    use CPAN::Testers::Schema::Base 'Test';

=head1 DESCRIPTION

This module collectively imports all the required features and modules
into your module. This module should be used by all modules in the
L<CPAN::Testers::Schema> distribution. This module should not be used by
modules in other distributions.

This module imports L<strict>, L<warnings>, and L<the sub signatures
feature|perlsub/Signatures>.

=head1 SEE ALSO

L<Import::Base>

=cut

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    'strict', 'warnings',
    feature => [qw( :5.24 signatures )],
    '>-warnings' => [qw( experimental::signatures )],
);

our %IMPORT_BUNDLES = (
    Result => [
        'DBIx::Class::Candy',
    ],
    ResultSet => [
        'DBIx::Class::Candy::ResultSet',
    ],
    Test => [
        'Test::More', 'Test::Lib',
        'Local::Schema' => [qw( prepare_temp_schema )],
    ],
);

1;
