module PAST::Optimization::ConstantFold::Simple;

INIT {
    pir::load_bytecode('PAST/Pattern.pbc');
    pir::load_bytecode('Tree/Optimizer.pbc');

    my &isInt := sub isInt ($val) {
        pir::isa__iPP($val, Integer);
    }

    my $pattern := 
      PAST::Pattern::Op.new(:pirop<add>,
                            PAST::Pattern::Val.new(:value(&isInt)),
                            PAST::Pattern::Val.new(:value(&isInt)));

    my &foldAdd := sub foldAdd ($/) {
        my $value := $/[0].from().value() + $/[1].from().value();
        my $result := PAST::Val.new(:value($value));

        $result;
    };

    our $optimization :=
      Tree::Optimizer::Pass.new(&foldAdd,
                                :when($pattern),
                                :recursive(1),
                                :name<PAST::Optimization::ConstantFold::Simple>);
}
