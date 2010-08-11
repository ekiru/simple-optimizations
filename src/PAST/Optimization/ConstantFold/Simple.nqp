module PAST::Optimization::ConstantFold::Simple;

INIT {
    pir::load_bytecode('PAST/Pattern.pbc');
    pir::load_bytecode('PAST/Optimizer.pbc');

    my %foldable-op;
    my %foldable-argument;
    my %foldable-returns;
    my %fold-sub;

    my &int-or-float := -> $node, $ignore {
        my $arg := $node ~~ PAST::Val
          ?? $node.value
          !! $node;
        pir::isa__IPP($arg, Integer) || pir::isa__IPP($arg, Float);
    };

    my &int-or-float-non-zero-rhs := -> $node, $side {
        my $arg := $node ~~ PAST::Val
          ?? $node.value
          !! $node;
        &int-or-float($arg, $side) && ($node eq 'l' || $arg != 0);
    };

    my &float-if-either-arg := -> $left, $right {
        if pir::isa__IPP($left, Float) || pir::isa__IPP($right, Float) {
            'Float';
        } else {
            'Integer';
        }
    };

    %foldable-op<add> := 1;
    %foldable-argument<add> := &int-or-float;
    %foldable-returns<add> := &float-if-either-arg;
    %fold-sub<add> := -> $l, $r {
        $l + $r;
    };

    %foldable-op<sub> := 1;
    %foldable-argument<sub> := &int-or-float;
    %foldable-returns<sub> := &float-if-either-arg;
    %fold-sub<sub> := -> $l, $r {
        $l - $r;
    };
    
    %foldable-op<mul> := 1;
    %foldable-argument<mul> := &int-or-float;
    %foldable-returns<mul> := &float-if-either-arg;
    %fold-sub<mul> := -> $l, $r {
        $l * $r;
    };

    %foldable-op<fdiv> := 1;
    %foldable-argument<fdiv> := &int-or-float-non-zero-rhs;
    %foldable-returns<fdiv> := &float-if-either-arg;
    %fold-sub<fdiv> := -> $l, $r {
        pir::fdiv($l, $r);
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
        my $type := %foldable-returns{$op}($left, $right);
        my $result := PAST::Val.new(:value(%fold-sub{$op}($left, $right)),
                                    :returns($type));
        $result;
    };

    our $optimization :=
      PAST::Optimizer::Pass.new(&fold,
                                :when($pattern),
                                :recursive(1),
                                :name<PAST::Optimization::ConstantFold::Simple>);
}
