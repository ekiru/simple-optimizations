#!/usr/bin/env parrot-nqp

sub MAIN() {
    # Load distutils library
    pir::load_bytecode('distutils.pbc');

    my %cfg :=
      hash(
           :setup<setup.nqp>,
           :name<simple-optimizations>,
           :abstract<A set of simple PAST optimizations>,
           :keywords(< past optimization >),
           :license_type<Artistic License 2.0>,
           :license_uri<http://www.perlfoundation.org/artistic_license_2_0>,
           :copyright_holder<Tyler L. Curtis>,
           :authority<http://github.com/ekiru>,
           :checkout_uri<git://github.com/ekiru/simple-optimizations.git>,
           :browser_uri<http://github.com/ekiru/simple-optimizations>,
           :project_uri<http://github.com/ekiru/simple-optimizations>,
           :description<A set of simple PAST optimizations that can be used in PCT-based compilers.>,
           :pir_nqp(unflatten('build/PAST/Optimization/ConstantFold/Simple.pir',
                              'src/PAST/Optimization/ConstantFold/Simple.nqp',
                              'build/PAST/Optimization/TailCallElim/Explicit.pir',
                              'src/PAST/Optimization/TailCallElim/Explicit.nqp')),
           :pbc_pir(unflatten('build/PAST/Optimization/ConstantFold/Simple.pbc',
                              'build/PAST/Optimization/ConstantFold/Simple.pir',
                              'build/PAST/Optimization/TailCallElim/Explicit.pbc',
                              'build/PAST/Optimization/TailCallElim/Explicit.pir')),

           :test_exec(get_parrot() ~ ' --library build '
                      ~ get_libdir() ~ '/library/nqp-rx.pbc'),
           :test_files<t/*.t>,
           :inst_lib(<
                     build/PAST/Optimization/ConstantFold/Simple.pbc
                     build/PAST/Optimization/TailCallElim/Explicit.pbc
                     >),
           
          );

    # Boilerplate; should not need to be changed
    my @*ARGS := pir::getinterp__P()[2];
       @*ARGS.shift;

    setup(@*ARGS, %cfg);
}

# NQP-rx doesn't have hash literals.
sub hash     (*%h ) { %h }
sub unflatten(*@kv) { my %h; for @kv -> $k, $v { %h{$k} := $v }; %h }

# Start it up!
MAIN();
