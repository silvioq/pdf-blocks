# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PDF-Blocks.t'
# vi: set cin sw=2:

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('PDF::Blocks') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my  $block = PDF::Blocks->new;
eval{
  $block->block( 'name', 200 );
};
ok( $@ );

$block->block( 'name', 200, sub{
    my $self = shift;
    $self->line( 0,0,100,0 );
    $self->rect( 0,0,100,10 );
    $self->cell( 0,0,100,12, "Hello test", "Arial", 12, "left", 0, 0 );
  });

$block->var( { one => 'two', three => 'for' } );
is( $block->var( 'one' ), 'two' );
ok( !$block->var( 'two' ) );
is( $block->var( 'three' ), 'for' );
$block->var( 'two', 2 );
is( $block->var( 'two' ), 2 );


$block->footer( 'name' );
is( scalar( @{$block->{footer}} ), 1 );
$block->footer( 'name' );
is( scalar( @{$block->{footer}} ), 2 );

is( $block->footer_size, 400 );

# Checks footer & header utilization
$block = PDF::Blocks->new;
$block->footer( 'namea' );
$block->header( 'nameb' );

$block->block( 'name', 100, sub{ my $self = shift; });
eval{
  $block->print_block( 'name' );
  ok( 0, "Must not arrive here" );
};
ok( 1, "Not namea and nameb" );

$block = PDF::Blocks->new;
$block->footer( 'namea' );
$block->header( 'nameb' );
$block->block( 'namea', 100, sub{ my $self = shift; });
eval{
  $block->print_block( 'name' );
  ok( 0, "Must not arrive here (2)" );
};
ok( 1, "Not nameb" );

$block = PDF::Blocks->new;
$block->footer( 'namea' );
$block->header( 'nameb' );
$block->block( 'namea', 100, sub{ my $self = shift; });
$block->block( 'nameb', 100, sub{ my $self = shift; });
eval{
  $block->print_block( 'name' );
  ok( 1, "Namea and nameb exists" );
};




1;
