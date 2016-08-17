use utf8;
package CPAN::Testers::Schema::Result::CpanStats;

use strict;
use warnings;

__PACKAGE__->table('cpanstats');

__PACKAGE__->add_columns(
  'id', {
    data_type         => 'int',
    extra             => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  'guid', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 36,
  },
  'state', {
    data_type   => 'enum',
    extra       => { list => ['pass', 'fail', 'unknown', 'na'] },
    is_nullable => 0,
  },
  # masked type maybe? or a FK? 
  'postdate', {
    data_type      => 'mediumint',
    extra          => { unsigned => 1 },
    is_nullable    => 0,
  },
  'tester', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 100,
  },
  'dist', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 100,
  },
  'version', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
  'platform',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
  'perl',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 10,
  },
  'osname',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
  'osvers',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 20,
  },
  'fulldate', {
    data_type   => 'char',
    is_nullable => 0,
    size        => 8,
  },
  # FK?
  'type', {
    data_type   => 'tinyint',
    extra       => { unsigned => 1 },
    is_nullable => 0,
  }, 
  'uploadid', {
    data_type   => 'int',
    extra       => { unsigned => 1 },
    is_nullable => 0,
  }, 
);

__PACKAGE__->set_primary_key('id');

1;    
