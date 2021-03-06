use Test::More tests => 18;
use Test::Exception;

use CPAN::Mini::Inject;
use File::Path;

mkdir( 't/local/MYCPAN' );

my $mcpi;
$mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg;

$mcpi->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.01',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
 )->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.02',
  file     => 'file:t/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
 )->add(
  # Injecting multiple modules, with different versions
  module   => {Foo => '1.0', Bar => '2.0'},
  authorid => 'SSORICHE',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
)->add(
  # Injecting multiple modules, with different versions, and a default version
  module   => {Fred => '0.0', Wilma => undef, Barney => '1.2'},
  authorid => 'SSORICHE',
  version  => '4.0',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
);

my $soriche_path = File::Spec->catfile( 'S', 'SS', 'SSORICHE' );
is( $mcpi->{authdir}, $soriche_path, 'author directory' );
ok(
  -r 't/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
  'Added module is readable'
);
my @modules = (
   'CPAN::Mini::Inject                 0.02  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Bar                                 2.0  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Foo                                 1.0  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Barney                              1.2  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Fred                                0.0  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Wilma                               4.0  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
);

for my $module (@modules) {
    ok( grep( /$module/, @{ $mcpi->{modulelist} } ), "Added: $module" );
}

is( grep( /^CPAN::Mini::Inject\s+/, @{ $mcpi->{modulelist} } ),
  1, 'Module added to list just once' );

# Test argument validation on add() method
throws_ok  {$mcpi->add( authorid => 'AUTHOR', module => {}) }
          qr/Required option not specified: file/, 'Missing file argument';

throws_ok {$mcpi->add( file => 'My-Modules-1.0.tar.gz', module => {}) }
          qr/Required option not specified: authorid/, 'Missing authorid argument';

throws_ok {$mcpi->add( authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/Required option not specified: module/, 'Missing module argument';

throws_ok {$mcpi->add( module => 'MyModule', authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/The 'version' argument must be given/, 'No default version, when module is a single string';

throws_ok {$mcpi->add( module => [], authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/must be a string or hashref/, 'The module argument is wrong type';

throws_ok {$mcpi->add( module => {Foo => undef}, authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/Must specify 'version'/, 'No default version and no explicit version either';

throws_ok {$mcpi->add( module => {Foo => 1}, authorid => 'AUTHOR', file => 'None-Such-0.0.tar.gz') }
          qr/Copy failed: Not Found/, 'file not found';

SKIP: {
  skip "Not a UNIX system", 2 if ( $^O =~ /^MSWin/ );
  is( ( stat( 't/local/MYCPAN/authors/id/S/SS/SSORICHE' ) )[2] & 07777,
    0775, 'Added author directory mode is 0775' );
  is(
    (
      stat(
        't/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz'
      )
    )[2] & 07777,
    0664,
    'Added module mode is 0664'
  );
}

# XXX do the same test as above again, but this time with a ->readlist after
# the ->parsecfg

rmtree( 't/local/MYCPAN', 0, 1 );
