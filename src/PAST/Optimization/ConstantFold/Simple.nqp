module PAST::Optimization::ConstantFold::Simple;

INIT {
    pir::load_bytecode('PAST/Pattern.pbc');
    pir::load_bytecode('PAST/Optimizer.pbc');

    my %foldable-op;
    my %foldable-argument;
    my %fold-sub;

    my &int-or-float := -> $node, $ignore {
        my $arg := $node ~~ PAST::Val
          ?? $node.value
          !! $node;
        pir::isa__IPP($arg, Integer) || pir::isa__IPP($arg, Float);
    };

    %foldable-op<add> := 1;
    %foldable-argument<add> := &int-or-float;
    %fold-sub<add> := -> $l, $r {
        PAST::Val.new(:value($l + $r));
    };

    %foldable-op<sub> := 1;
    %foldable-argument<sub> := &int-or-float;
    %fold-sub<sub> := -> $l, $r {
        PAST::Val.new(:value($l - $r));
    };
    
    my $pattern := 
      PAST::Pattern::Op.new(:pirop(-> $op { pir::exists__iQs(%foldable-op,
                                                             $op); }),
                            -> $ignore { 1; },
                            -> $ignore { 1; });

    my &fold := -> $/ {
        my $op := $<pirop>.orig;
        return $/.orig
          unless %foldable-argument{$op}($/[0].orig, 'l')
            && %foldable-argument{$op}($/[1].orig, 'r');
        
        my $left := $/[0].orig ~~ PAST::Val
          ?? $/[0].orig.value
          !! $/[0].orig;
        my $right := $/[1].orig ~~ PAST::Val
          ?? $/[1].orig.value
          !! $/[1].orig;
        my $result := %fold-sub{$op}($left, $right);
        $result;
    };

    our $optimization :=
      PAST::Optimizer::Pass.new(&fold,
                                :when($pattern),
                                :recursive(1),
                                :name<PAST::Optimization::ConstantFold::Simple>);
}
