pragma circom 2.0.0;

template Hello() {
    // Signal input
    signal input x;
    
    // Signal output
    signal output y;
    
    // Constraint: y = x * 2
    y <== x * 2;
}

component main = Hello();