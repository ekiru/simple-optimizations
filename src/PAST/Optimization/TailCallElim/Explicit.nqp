module PAST::Optimization::TailCallElim::Explicit;

INIT {
    pir::load_bytecode('PAST/Pattern.pbc');
    pir::load_bytecode('Tree/Optimizer.pbc');

    my $pattern :=
      PAST::Pattern::Op.new(:pasttype<return>,
                            PAST::Pattern::Op.new);

    my &eliminate := sub ($/) {
        # Return if it's actually another kind of op.
        # Since call ops don't always have a :pastype attribute,
        # we have to do this manually.
        return $/.orig
          if (pir::defined__IP($/[0].orig.pasttype) &&
              $/[0].orig.pasttype ne 'call');
        return $/.orig if pir::defined__IP($/[0].orig.pirop);

        my $result := $/[0].orig;
        $result.pirop('tailcall');
        $result.pasttype('pirop');
            
        if $result.name {
            my $get_sub :=
              '%r = find_sub_not_null "' ~ $result.name ~ '"';
            $result.unshift(PAST::Op.new(:inline($get_sub)));
        }
        $result;
    };

    our $optimization :=
      Tree::Optimizer::Pass.new(&eliminate,
                                :when($pattern),
                                :recursive(1),
                                :name<PAST::Optimization::TailCallElim::Explicit>);
}
